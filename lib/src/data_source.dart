import 'dart:async';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';

abstract class DataSource {
  DataSource(this.name);

  /// A user-facing name for this data source
  final String name;

  /// A string that uniquely identifies this data source ([name] may collide for
  /// differing sources but this should not)
  String get id;

  FutureOr<String> get content;
  FutureOr<Uint8List> get bytes;

  // ignore: avoid_returning_this
  DataSource get minimize => this;

  FutureOr<DataSource> resolveRelative(String relativePath);

  bool get needsToResolveParent => false;
}

class WebDataSource extends DataSource {
  WebDataSource(this.uri) : super(uri.pathSegments.last);

  final Uri uri;

  @override
  String get id => uri.toString();

  @override
  FutureOr<String> get content async =>
      time('load url', () async => (await _response).body);

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
          localizedMessage: (context) => AppLocalizations.of(context)!
              .errorUnexpectedHttpResponse(response),
        );
      }
    } on Exception catch (e, s) {
      logError(e, s);
      rethrow;
    }
  }

  @override
  WebDataSource resolveRelative(String relativePath) =>
      WebDataSource(uri.resolve(relativePath));
}

class AssetDataSource extends DataSource {
  AssetDataSource(this.key) : super(Uri.parse(key).pathSegments.last);

  final String key;

  @override
  String get id => key;

  @override
  FutureOr<String> get content => rootBundle.loadString(key);

  @override
  FutureOr<Uint8List> get bytes async =>
      (await rootBundle.load(key)).buffer.asUint8List();

  @override
  DataSource resolveRelative(String relativePath) =>
      AssetDataSource(Uri.parse(key).resolve(relativePath).toString());
}

class NativeDataSource extends DataSource {
  NativeDataSource(
    String name,
    this.identifier,
    this.uri, {
    required this.persistable,
  }) : super(name);

  /// The identifier used to read the file via native APIs
  final String identifier;

  /// Whether [identifier] is persistable across app relaunches
  final bool persistable;

  /// The URI that identifies the native file
  final String uri;

  /// The persistent identifier of this source's parent directory. Needed for
  /// resolving relative links.
  String? _parentDirIdentifier;

  @override
  String get id => uri;

  @override
  FutureOr<String> get content => FilePickerWritable()
      .readFile(identifier: identifier, reader: (_, file) => _readFile(file));

  @override
  FutureOr<Uint8List> get bytes => FilePickerWritable().readFile(
      identifier: identifier, reader: (_, file) => file.readAsBytes());

  @override
  FutureOr<NativeDataSource> resolveRelative(String relativePath) async {
    if (_parentDirIdentifier == null) {
      throw OrgroError(
        'Can’t resolve path relative to this document',
        localizedMessage: (context) =>
            AppLocalizations.of(context)!.errorCannotResolveRelativePath,
      );
    }
    final resolved = await FilePickerWritable().resolveRelativePath(
        directoryIdentifier: _parentDirIdentifier!, relativePath: relativePath);
    if (resolved is! FileInfo) {
      throw OrgroError(
        '$relativePath resolved to a non-file: $resolved',
        localizedMessage: (context) => AppLocalizations.of(context)!
            .errorPathResolvedToNonFile(relativePath, resolved.uri),
      );
    }
    return NativeDataSource(
      resolved.fileName ?? Uri.parse(resolved.uri).pathSegments.last,
      resolved.identifier,
      resolved.uri,
      persistable: resolved.persistable,
    );
  }

  @override
  bool get needsToResolveParent => persistable && _parentDirIdentifier == null;

  Future<void> resolveParent(List<String> accessibleDirs) async =>
      _parentDirIdentifier ??= await _findParentDirIdentifier(accessibleDirs);

  Future<String?> _findParentDirIdentifier(
    List<String> accessibleDirs,
  ) async {
    debugPrint('Accessible dirs: $accessibleDirs');
    for (final dirId in accessibleDirs) {
      debugPrint('Resolving parent of $uri relative to $dirId');
      try {
        final parent = await FilePickerWritable()
            .getDirectory(rootIdentifier: dirId, fileIdentifier: identifier);
        debugPrint('Found file $uri parent dir: ${parent.uri}');
        return parent.identifier;
      } on Exception {
        // Next
      }
    }
    return null;
  }
}

class LoadedNativeDataSource extends NativeDataSource {
  static Future<LoadedNativeDataSource> fromExternal(
    FileInfo externalFileInfo,
    File file,
  ) async =>
      LoadedNativeDataSource(
        externalFileInfo.fileName ?? file.uri.pathSegments.last,
        externalFileInfo.identifier,
        externalFileInfo.uri,
        await _readFile(file),
        persistable: externalFileInfo.persistable,
      );

  LoadedNativeDataSource(
      String name, String identifier, String uri, this.content,
      {required bool persistable})
      : super(name, identifier, uri, persistable: persistable);

  @override
  final String content;

  @override
  DataSource get minimize => NativeDataSource(
        name,
        identifier,
        uri,
        persistable: persistable,
      );
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

OrgDocument _parse(String text) => OrgDocument.parse(text);

Future<String> _readFile(File file) async {
  try {
    return await file.readAsString();
  } on Exception {
    final bytes = await file.readAsBytes();
    final decoded = await CharsetDetector.autoDecode(bytes);
    debugPrint('Decoded file as ${decoded.charset}');
    return decoded.string;
  }
}
