import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:http/http.dart' as http;
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';

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
        throw Exception();
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
  NativeDataSource(String name, this.identifier, this.uri) : super(name);

  /// The persistent identifier used to read the file via native APIs
  final String? identifier;

  /// The URI that identifies the native file
  final String uri;

  /// The persistent identifier of this source's parent directory. Needed for
  /// resolving relative links.
  String? _parentDirIdentifier;

  @override
  String get id => uri;

  @override
  FutureOr<String> get content => FilePickerWritable()
      .readFile(identifier: identifier!, reader: (_, file) => _readFile(file));

  @override
  FutureOr<Uint8List> get bytes => FilePickerWritable().readFile(
      identifier: identifier!, reader: (_, file) => file.readAsBytes());

  @override
  FutureOr<NativeDataSource> resolveRelative(String relativePath) async {
    final resolved = await FilePickerWritable().resolveRelativePath(
        directoryIdentifier: _parentDirIdentifier!, relativePath: relativePath);
    if (resolved is! FileInfo) {
      throw Exception('$relativePath resolved to a non-file: $resolved');
    }
    return NativeDataSource(
      resolved.fileName ?? Uri.parse(resolved.uri).pathSegments.last,
      resolved.identifier,
      resolved.uri,
    );
  }

  @override
  bool get needsToResolveParent =>
      identifier != null && _parentDirIdentifier == null;

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
            .getDirectory(rootIdentifier: dirId, fileIdentifier: identifier!);
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
        externalFileInfo.persistable ? externalFileInfo.identifier : null,
        externalFileInfo.uri,
        await _readFile(file),
      );

  LoadedNativeDataSource(
      String name, String? identifier, String uri, this.content)
      : super(name, identifier, uri);

  @override
  final String content;

  @override
  DataSource get minimize => NativeDataSource(name, identifier, uri);
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
