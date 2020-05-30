import 'dart:async';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';

Future<OpenFileInfo> pickFile() async =>
    _resolve(FilePickerWritable().openFilePicker);

Future<OpenFileInfo> readFileWithIdentifier(String identifier) async =>
    _resolve(() => FilePickerWritable().readFileWithIdentifier(identifier));

typedef FileInfoProvider = FutureOr<FileInfo> Function();

Future<OpenFileInfo> _resolve(FileInfoProvider provider) async {
  final fileInfo = await time('resolve external file', provider);
  return fileInfo == null ? null : OpenFileInfo.fromExternal(fileInfo);
}

typedef ContentProvider = Future<String> Function();

class OpenFileInfo {
  OpenFileInfo.fromExternal(FileInfo externalFileInfo)
      : this(
          externalFileInfo.persistable ? externalFileInfo.identifier : null,
          externalFileInfo.fileName,
          externalFileInfo.file.readAsString,
        );

  OpenFileInfo(this.identifier, this.title, this.content);
  final String identifier;
  final String title;
  final ContentProvider content;

  Future<ParsedOrgFileInfo> toParsed() async => ParsedOrgFileInfo(
        identifier,
        title,
        await content().then(parse, onError: logError),
      );
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
      ..registerFileInfoHandler(_loadFile);
  }

  Future<bool> _loadFile(FileInfo fileInfo) =>
      loadFileFromPlatform(OpenFileInfo.fromExternal(fileInfo));

  Future<bool> loadFileFromPlatform(OpenFileInfo info);

  @override
  void dispose() {
    _filePickerState.removeFileInfoHandler(_loadFile);
    super.dispose();
  }
}
