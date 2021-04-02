import 'dart:async';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/data_source.dart';

Future<NativeDataSource?> pickFile() async =>
    FilePickerWritable().openFile(LoadedNativeDataSource.fromExternal);

Future<NativeDataSource> readFileWithIdentifier(String identifier) async =>
    FilePickerWritable().readFile(
        identifier: identifier, reader: LoadedNativeDataSource.fromExternal);

mixin PlatformOpenHandler<T extends StatefulWidget> on State<T> {
  late FilePickerState _filePickerState;

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
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      await _displayError(e.toString());
      return false;
    }
    return loadFileFromPlatform(openFileInfo);
  }

  Future<bool> loadFileFromPlatform(NativeDataSource info);

  Future<bool> _handleError(ErrorEvent event) async {
    await _displayError(event.message);
    return true;
  }

  Future<void> _displayError(String message) async => showDialog<void>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Error'),
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
