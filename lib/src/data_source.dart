import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:http/http.dart' as http;
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';

abstract class DataSource {
  const DataSource(this.name);

  /// A user-facing name for this data source
  final String name;

  /// A string that uniquely identifies this data source ([name] may collide for
  /// differing sources but this should not)
  String get id;

  FutureOr<String> get content;
  FutureOr<Uint8List> get bytes;

  Future<File> copyTo(Uri uri) async {
    final file = File.fromUri(uri);
    await file.writeAsBytes(await bytes);
    return file;
  }

  // ignore: avoid_returning_this
  DataSource get minimize => this;

  FutureOr<DataSource> resolveRelative(String relativePath);

  bool get needsToResolveParent => false;

  Map<String, Object?> toJson();
}

class WebDataSource extends DataSource {
  WebDataSource(this.uri) : super(uri.pathSegments.last);

  final Uri uri;

  @override
  String get id => uri.toString();

  @override
  FutureOr<String> get content async {
    final response = await time('load url', () => _response);
    try {
      return response.body;
    } on Exception {
      return await _readBytes(response.bodyBytes);
    }
  }

  @override
  FutureOr<Uint8List> get bytes =>
      time('load url', () async => (await _response).bodyBytes);

  Future<http.Response> get _response async {
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw OrgroError(
          'Unexpected HTTP response: $response',
          localizedMessage: (context) => AppLocalizations.of(
            context,
          )!.errorUnexpectedHttpResponse(response),
        );
      }
    } on Exception catch (e, s) {
      logError(e, s);
      rethrow;
    }
  }

  @override
  WebDataSource resolveRelative(String relativePath) =>
      WebDataSource(uri.resolveUri(Uri(path: relativePath)));

  @override
  Map<String, Object?> toJson() => {
    'type': 'web',
    'name': name,
    'id': id,
    'uri': uri.toString(),
  };
}

class AssetDataSource extends DataSource {
  AssetDataSource(this.key) : super(Uri.parse(key).pathSegments.last);

  final String key;

  @override
  String get id => key;

  @override
  FutureOr<String> get content async {
    try {
      return await rootBundle.loadString(key);
    } on Exception {
      return await _readBytes(await bytes);
    }
  }

  @override
  FutureOr<Uint8List> get bytes async =>
      Uint8List.sublistView(await rootBundle.load(key));

  @override
  AssetDataSource resolveRelative(String relativePath) => AssetDataSource(
    Uri.parse(key).resolveUri(Uri(path: relativePath)).toFilePath(),
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'asset',
    'name': name,
    'id': id,
    'key': key,
  };
}

class NativeDataSource extends DataSource {
  const NativeDataSource(
    super.name,
    this.identifier,
    this.uri, {
    required this.persistable,
    this.parentDirIdentifier,
    this.rootDirIdentifier,
  }) : assert(
         parentDirIdentifier == null && rootDirIdentifier == null ||
             parentDirIdentifier != null && rootDirIdentifier != null,
       );

  /// The identifier used to read the file via native APIs
  final String identifier;

  /// Whether [identifier] is persistable across app relaunches
  final bool persistable;

  /// The URI that identifies the native file
  final String uri;

  /// The persistent identifier of this source's parent directory. Needed for
  /// resolving relative links.
  final String? parentDirIdentifier;

  /// The persistent identifier of the root directory of this source. May be the
  /// same as [parentDirIdentifier] or may be deeper.
  final String? rootDirIdentifier;

  @override
  String get id => uri;

  @override
  FutureOr<String> get content => FilePickerWritable().readFile(
    identifier: identifier,
    reader: (_, file) => _readFile(file),
  );

  @override
  FutureOr<Uint8List> get bytes => FilePickerWritable().readFile(
    identifier: identifier,
    reader: (_, file) => file.readAsBytes(),
  );

  @override
  FutureOr<NativeDataSource> resolveRelative(String relativePath) async {
    if (parentDirIdentifier == null) {
      throw OrgroError(
        "Can't resolve path relative to this document",
        localizedMessage: (context) =>
            AppLocalizations.of(context)!.errorCannotResolveRelativePath,
      );
    }
    // TODO(aaron): See if we can resolve to a non-existent file for writing
    try {
      final resolved = await FilePickerWritable().resolveRelativePath(
        directoryIdentifier: parentDirIdentifier!,
        relativePath: relativePath,
      );
      if (resolved is! FileInfo) {
        throw OrgroError(
          '$relativePath resolved to a non-file: $resolved',
          localizedMessage: (context) => AppLocalizations.of(
            context,
          )!.errorPathResolvedToNonFile(relativePath, resolved.uri),
        );
      }
      return NativeDataSource(
        resolved.fileName ?? Uri.parse(resolved.uri).pathSegments.last,
        resolved.identifier,
        resolved.uri,
        persistable: resolved.persistable,
      );
    } on Exception {
      // Normal resolution failed; try symlink-aware resolution.
      // This handles git's portable symlink format where symlinks are stored
      // as small text files containing the target path.
      return _resolveWithSymlinks(relativePath);
    }
  }

  /// Resolves a relative path while handling git-style symlinks.
  ///
  /// Git stores symlinks as small text files containing the target path.
  /// This method detects such files and follows them during path resolution.
  Future<NativeDataSource> _resolveWithSymlinks(String relativePath) async {
    final components = p.posix.split(relativePath);
    String currentDirId = parentDirIdentifier!;

    // Resolve each directory component, following symlinks as needed
    for (int i = 0; i < components.length - 1; i++) {
      final component = components[i];
      if (component.isEmpty || component == '.') continue;

      final resolved = await FilePickerWritable().resolveRelativePath(
        directoryIdentifier: currentDirId,
        relativePath: component,
      );

      if (resolved is DirectoryInfo) {
        // Normal directory, continue traversal
        currentDirId = resolved.identifier;
      } else if (resolved is FileInfo) {
        // Might be a git symlink file; try to read and follow it
        final symlinkTarget = await _readGitSymlink(resolved);
        if (symlinkTarget != null) {
          // It's a symlink! Resolve the target path relative to current dir
          final targetResolved = await FilePickerWritable().resolveRelativePath(
            directoryIdentifier: currentDirId,
            relativePath: symlinkTarget,
          );
          if (targetResolved is DirectoryInfo) {
            currentDirId = targetResolved.identifier;
          } else {
            throw OrgroError(
              'Symlink target "$symlinkTarget" is not a directory',
              localizedMessage: (context) =>
                  AppLocalizations.of(context)!.errorPathResolvedToNonFile(
                    symlinkTarget,
                    targetResolved.uri,
                  ),
            );
          }
        } else {
          throw OrgroError(
            'Path component "$component" is a file, not a directory',
            localizedMessage: (context) =>
                AppLocalizations.of(context)!.errorPathResolvedToNonFile(
                  component,
                  resolved.uri,
                ),
          );
        }
      }
    }

    // Resolve the final component (the actual file)
    final lastComponent = components.last;
    final resolved = await FilePickerWritable().resolveRelativePath(
      directoryIdentifier: currentDirId,
      relativePath: lastComponent,
    );

    if (resolved is! FileInfo) {
      throw OrgroError(
        '$relativePath resolved to a non-file: $resolved',
        localizedMessage: (context) => AppLocalizations.of(
          context,
        )!.errorPathResolvedToNonFile(relativePath, resolved.uri),
      );
    }

    return NativeDataSource(
      resolved.fileName ?? Uri.parse(resolved.uri).pathSegments.last,
      resolved.identifier,
      resolved.uri,
      persistable: resolved.persistable,
    );
  }

  /// Reads a file and returns its contents if it looks like a git symlink.
  ///
  /// Git symlinks are small text files (typically < 1KB) containing a relative
  /// path with no newlines or special characters.
  Future<String?> _readGitSymlink(FileInfo fileInfo) async {
    try {
      final bytes = await FilePickerWritable().readFile(
        identifier: fileInfo.identifier,
        reader: (_, file) => file.readAsBytes(),
      );

      // Git symlinks are very small (just a path)
      if (bytes.length > 1024) return null;

      // Check for binary content (null bytes or high bytes in first portion)
      for (int i = 0; i < bytes.length && i < 100; i++) {
        if (bytes[i] == 0 || bytes[i] > 127) return null;
      }

      final contents = utf8.decode(bytes).trim();

      // Validate it looks like a relative path
      if (contents.isEmpty ||
          contents.contains('\n') ||
          contents.contains('\r') ||
          contents.length > 256 ||
          contents.startsWith('/')) {
        return null;
      }

      return contents;
    } on Exception {
      return null;
    }
  }

  Future<FileInfo> write(String content) => FilePickerWritable().writeFile(
    identifier: identifier,
    writer: (file) => file.writeAsString(content),
  );

  @override
  bool get needsToResolveParent => persistable && parentDirIdentifier == null;

  Future<NativeDataSource> resolveParent(List<String> accessibleDirs) async {
    if (parentDirIdentifier != null) return this;
    final found = await _findParentDirIdentifier(accessibleDirs);
    if (found == null) return this;
    final (rootId, parentId) = found;
    return NativeDataSource(
      name,
      identifier,
      uri,
      persistable: persistable,
      parentDirIdentifier: parentId,
      rootDirIdentifier: rootId,
    );
  }

  Future<(String, String)?> _findParentDirIdentifier(
    List<String> accessibleDirs,
  ) async {
    debugPrint('Accessible dirs: $accessibleDirs');
    for (final rootId in accessibleDirs) {
      debugPrint('Resolving parent of $uri relative to $rootId');
      try {
        final parent = await FilePickerWritable().getDirectory(
          rootIdentifier: rootId,
          fileIdentifier: identifier,
        );
        debugPrint('Found file $uri parent dir: ${parent.uri}');
        return (rootId, parent.identifier);
      } on Exception catch (e, s) {
        logError(e, s);
        // Next
      }
    }
    return null;
  }

  @override
  Future<File> copyTo(Uri uri) => FilePickerWritable().readFile(
    identifier: identifier,
    reader: (_, file) async {
      await file.copy(uri.toFilePath());
      return File.fromUri(uri);
    },
  );

  @override
  Map<String, Object?> toJson() => {
    'type': 'native',
    'name': name,
    'id': id,
    'identifier': identifier,
    'uri': uri,
    'persistable': persistable,
  };
}

class LoadedNativeDataSource extends NativeDataSource {
  static Future<LoadedNativeDataSource> fromExternal(
    FileInfo externalFileInfo,
    File file,
  ) async => LoadedNativeDataSource(
    externalFileInfo.fileName ?? file.uri.pathSegments.last,
    externalFileInfo.identifier,
    externalFileInfo.uri,
    await _readFile(file),
    persistable: externalFileInfo.persistable,
  );

  LoadedNativeDataSource(
    super.name,
    super.identifier,
    super.uri,
    this.content, {
    required super.persistable,
  });

  @override
  final String content;

  @override
  DataSource get minimize =>
      NativeDataSource(name, identifier, uri, persistable: persistable);

  @override
  Future<LoadedNativeDataSource> resolveParent(List<String> accessibleDirs) =>
      throw UnimplementedError();
}

class NativeDirectoryInfo {
  NativeDirectoryInfo(this.name, this.identifier, this.uri);

  final String name;
  final String identifier;
  final String uri;
}

class ParsedOrgFileInfo {
  static Future<ParsedOrgFileInfo> from(DataSource source) async {
    try {
      final parsed = await parse(await source.content);
      return ParsedOrgFileInfo(source.minimize, parsed);
    } on Exception catch (e, s) {
      logError(e, s);
      rethrow;
    }
  }

  ParsedOrgFileInfo(this.dataSource, this.doc);
  final DataSource dataSource;
  final OrgDocument doc;
}

Future<OrgDocument> parse(String content) async =>
    time('parse', () => compute(_parse, content));

OrgDocument _parse(String text) =>
    OrgDocument.parse(text, interpretEmbeddedSettings: true);

Future<String> _readFile(File file) async {
  try {
    return await file.readAsString();
  } on Exception {
    return await _readBytes(await file.readAsBytes());
  }
}

Future<String> _readBytes(Uint8List bytes) async {
  final decoded = await CharsetDetector.autoDecode(bytes);
  debugPrint('Decoded bytes as ${decoded.charset}');
  return decoded.string;
}
