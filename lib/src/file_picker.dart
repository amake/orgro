import 'dart:async';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/pages/start/util.dart';

Future<NativeDataSource?> pickFile() async =>
    FilePickerWritable().openFile(LoadedNativeDataSource.fromExternal);

Future<NativeDataSource?> createAndLoadFile(String fileName) async {
  final fileInfo = await FilePickerWritable().openFileForCreate(
    fileName: fileName,
    writer: (file) => file.writeAsString(''),
  );
  return fileInfo == null ? null : readFileWithIdentifier(fileInfo.identifier);
}

Future<NativeDirectoryInfo?> pickDirectory({String? initialDirUri}) async {
  final dirInfo = await FilePickerWritable().openDirectory(
    initialDirUri: initialDirUri,
  );
  return dirInfo == null
      ? null
      : NativeDirectoryInfo(
          dirInfo.fileName ?? 'unknown',
          dirInfo.identifier,
          dirInfo.uri,
        );
}

Future<NativeDataSource> readFileWithIdentifier(String identifier) async =>
    FilePickerWritable().readFile(
      identifier: identifier,
      reader: LoadedNativeDataSource.fromExternal,
    );

Future<bool> canObtainNativeDirectoryPermissions() async =>
    FilePickerWritable().isDirectoryAccessSupported();

Future<void> disposeNativeSourceIdentifier(String identifier) =>
    FilePickerWritable().disposeIdentifier(identifier);

mixin PlatformOpenHandler<T extends StatefulWidget> on State<T> {
  late final FilePickerState _filePickerState;

  @override
  void initState() {
    super.initState();
    _filePickerState = FilePickerWritable().init()
      ..registerFileOpenHandler(_loadFile)
      ..registerErrorEventHandler(_handleError);
  }

  Future<bool> _loadFile(FileInfo fileInfo, File file) async {
    NativeDataSource openFileInfo;
    try {
      openFileInfo = await LoadedNativeDataSource.fromExternal(fileInfo, file);
    } catch (e) {
      await _displayError(e.toString());
      return false;
    }
    if (!mounted) return false;
    await loadAndRememberFile(context, openFileInfo);
    return true;
  }

  Future<bool> _handleError(ErrorEvent event) async {
    await _displayError(event.message);
    return true;
  }

  Future<void> _displayError(String message) async => showDialog<void>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(AppLocalizations.of(context)!.dialogTitleError),
      children: [ListTile(title: Text(message))],
    ),
  );

  @override
  void dispose() {
    _filePickerState
      ..removeFileOpenHandler(_loadFile)
      ..removeErrorEventHandler(_handleError);
    super.dispose();
  }
}
