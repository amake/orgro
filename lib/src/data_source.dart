import 'dart:async';
import 'dart:io';

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

  FutureOr<String> get content;

  // ignore: avoid_returning_this
  DataSource get minimize => this;
}

class WebDataSource extends DataSource {
  WebDataSource(this.uri) : super(uri.pathSegments.last);

  final Uri uri;

  @override
  FutureOr<String> get content async =>
      time('load url', () async => (await _response).body);

  Future<http.Response> get _response async {
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception();
      }
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      rethrow;
    }
  }
}

class AssetDataSource extends DataSource {
  AssetDataSource(this.key) : super(Uri.parse(key).pathSegments.last);

  final String key;

  @override
  FutureOr<String> get content => rootBundle.loadString(key);
}

class NativeDataSource extends DataSource {
  NativeDataSource(String name, this.identifier, this.uri) : super(name);

  /// The persistent identifier used to read the file via native APIs
  final String? identifier;

  /// The URI that identifies the native file
  final String uri;

  @override
  FutureOr<String> get content => FilePickerWritable()
      .readFile(identifier: identifier!, reader: (_, file) => _readFile(file));
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

class ParsedOrgFileInfo {
  static Future<ParsedOrgFileInfo> from(DataSource source) async {
    try {
      final parsed = await parse(await source.content);
      return ParsedOrgFileInfo(source.minimize, parsed);
    } on Exception catch (e, s) {
      await logError(e, s);
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
