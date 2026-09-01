import 'dart:async';
import 'dart:io';

import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/capture.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/native_search.dart';
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

Future<FileInfo?> createAndSaveFile(String fileName, String content) async =>
    await FilePickerWritable().openFileForCreate(
      fileName: fileName,
      writer: (file) => file.writeAsString(content),
    );

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

/// Fall back to searching for the file by name in accessible directories if the
/// file cannot be read by identifier. Returns a tuple of the loaded data source
/// and a boolean indicating whether recovery was necessary.
Future<({NativeDataSource dataSource, bool recovered})>
readFileWithIdentifierWithRecoveryStrategy({
  required String identifier,
  required String fileName,
  required Iterable<String> accessibleDirs,
}) async {
  try {
    final read = await FilePickerWritable().readFile(
      identifier: identifier,
      reader: LoadedNativeDataSource.fromExternal,
    );
    return (dataSource: read, recovered: false);
  } catch (e, s) {
    logError(e, s);

    // Other software may replace the file with a new one (instead of rewriting
    // the existing one), which invalidates the persisted identifier we have. In
    // that case, we try to recover by searching for the file by name in the
    // directories we have access to.
    //
    // Recoverable case on iOS (iCloud Drive):
    //
    // ```
    // flutter: PlatformException(UnknownError, Error Domain=NSFileProviderErrorDomain Code=-1005 "The file doesn’t exist." UserInfo={NSFileProviderErrorNonExistentItemIdentifier=__fp/fs/docID(2176)}, null, null)
    // ```
    //
    // We intentionally take the first match we find, even if there are multiple
    // files with the same name in different directories, because in the general
    // case this may be an extremely slow, network-bound process and recovery is
    // fundamentally best-effort.
    for (final dir in accessibleDirs) {
      final requestId = Object().hashCode.toString();
      // TODO(aaron): FilePickerWritable().readFile() creates a local copy of
      // the file whereas findFileWithExactName() reads in situ. We should
      // probably unify these behaviors.
      try {
        final dataSource = await findFileWithExactName(
          requestId: requestId,
          exactName: fileName,
          dirIdentifier: dir,
        );
        if (dataSource != null) {
          final loaded = await LoadedNativeDataSource.from(dataSource);
          return (dataSource: loaded, recovered: true);
        }
      } catch (e, s) {
        logError(e, s);
      }
    }
    throw NotFoundException(identifier);
  }
}

class NotFoundException implements Exception {
  NotFoundException(this.identifier);

  final String identifier;

  @override
  String toString() => 'NotFoundException: $identifier';
}

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
      ..registerErrorEventHandler(_handleError)
      ..registerUriHandler(_handleUri);
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

  // It doesn't make a lot of sense to handle org-capture URIs here, but
  // file_picker_writable implements the callback that handles URI opening, so
  // for now we have no choice.
  //
  // TODO(aaron): See if file_picker_writable can refuse handling of non-file URIs
  bool _handleUri(Uri uri) {
    debugPrint('Received URI: $uri; scheme=${uri.scheme}, host=${uri.host}');
    if (isCaptureUri(uri)) {
      captureUri(context, uri).onError(logError);
      return true;
    }
    return false;
  }
}
