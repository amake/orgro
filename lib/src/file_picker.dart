import 'dart:async';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_charset_detector/flutter_charset_detector.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';

Future<OpenFileInfo> pickFile() async =>
    FilePickerWritable().openFile(OpenFileInfo._fromExternal);

Future<OpenFileInfo> readFileWithIdentifier(String identifier) async =>
    FilePickerWritable()
        .readFile(identifier: identifier, reader: OpenFileInfo._fromExternal);

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

class OpenFileInfo {
  static Future<OpenFileInfo> _fromExternal(
    FileInfo externalFileInfo,
    File file,
  ) async =>
      OpenFileInfo(
        externalFileInfo.persistable ? externalFileInfo.identifier : null,
        externalFileInfo.fileName,
        await _readFile(file),
      );

  OpenFileInfo(this.identifier, this.title, this.content);
  final String identifier;
  final String title;
  final FutureOr<String> content;

  Future<ParsedOrgFileInfo> toParsed() async {
    try {
      final parsed = await parse(await content);
      return ParsedOrgFileInfo(identifier, title, parsed);
    } on Exception catch (e, s) {
      await logError(e, s);
      rethrow;
    }
  }
}

class ParsedOrgFileInfo {
  ParsedOrgFileInfo(this.identifier, this.title, this.doc);
  final String identifier;
  final String title;
  final OrgDocument doc;
}

Future<OrgDocument> parse(String content) async =>
    time('parse', () => compute(_parse, content));

OrgDocument _parse(String text) => OrgDocument.parse(text);

mixin PlatformOpenHandler<T extends StatefulWidget> on State<T> {
  FilePickerState _filePickerState;

  @override
  void initState() {
    super.initState();
    _filePickerState = FilePickerWritable().init()
      ..registerFileOpenHandler(_loadFile);
  }

  Future<bool> _loadFile(FileInfo fileInfo, File file) async {
    final openFileInfo = await OpenFileInfo._fromExternal(fileInfo, file);
    return loadFileFromPlatform(openFileInfo);
  }

  Future<bool> loadFileFromPlatform(OpenFileInfo info);

  @override
  void dispose() {
    _filePickerState.removeFileOpenHandler(_loadFile);
    super.dispose();
  }
}
