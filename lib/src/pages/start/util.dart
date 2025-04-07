import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';

const kRestoreOpenFileIdKey = 'restore_open_file_id';

Future<void> loadAndRememberFile(
  BuildContext context,
  FutureOr<NativeDataSource?> fileInfoFuture, {
  InitialMode? mode,
}) async {
  final recentFiles = RememberedFiles.of(context);
  final bucket = RestorationScope.of(context);
  final recentFile = await loadFile(context, fileInfoFuture, mode: mode);
  if (recentFile != null) {
    recentFiles.add([recentFile]);
    debugPrint('Saving file ID to bucket $bucket');
    bucket.write<String>(kRestoreOpenFileIdKey, recentFile.identifier);
  }
}

Future<RememberedFile?> loadFile(
  BuildContext context,
  FutureOr<NativeDataSource?> dataSource, {
  RestorationBucket? bucket,
  InitialMode? mode,
}) async {
  bucket ??= RestorationScope.of(context);
  final loaded = await loadDocument(
    context,
    dataSource,
    onClose: () {
      debugPrint('Clearing saved state from bucket $bucket');
      bucket!.remove<String>(kRestoreOpenFileIdKey);
    },
    mode: mode,
  );
  RememberedFile? result;
  if (loaded) {
    final source = await dataSource;
    if (source == null) {
      // User canceled
    } else {
      if (source.persistable) {
        result = RememberedFile(
          identifier: source.identifier,
          name: source.name,
          uri: source.uri,
          lastOpened: DateTime.now(),
        );
      } else {
        debugPrint('Couldn’t obtain persistent access to ${source.name}');
      }
    }
  }
  return result;
}
