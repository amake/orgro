import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/routes/routes.dart';

const kRestoreOpenFileIdKey = 'restore_open_file_id';

Future<void> loadAndRememberFile(
  BuildContext context,
  FutureOr<NativeDataSource?> fileInfoFuture, {
  InitialMode? mode,
}) async {
  final dataSource = await fileInfoFuture;
  if (dataSource == null) return;
  if (!context.mounted) return;

  final rememberedFiles = RememberedFiles.of(context);
  final bucket = RestorationScope.of(context);
  if (dataSource.persistable) {
    final loadedFile = RememberedFile(
      identifier: dataSource.identifier,
      name: dataSource.name,
      uri: dataSource.uri,
      lastOpened: DateTime.now(),
    );
    rememberedFiles.add([loadedFile]);
    debugPrint('Saving file ID to bucket $bucket');
    bucket.write<String>(
      kRestoreRouteKey,
      json.encode({'route': Routes.document, 'fileId': loadedFile.identifier}),
    );
  } else {
    debugPrint('Couldn’t obtain persistent access to ${dataSource.name}');
  }
  await loadFile(context, dataSource, mode: mode);
}

Future<void> loadFile(
  BuildContext context,
  NativeDataSource dataSource, {
  RestorationBucket? bucket,
  InitialMode? mode,
}) async {
  bucket ??= RestorationScope.of(context);
  await loadDocument(context, dataSource, mode: mode);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreOpenFileIdKey);
  bucket.remove<String>(kRestoreRouteKey);
}

Future<void> loadAndRememberUrl(
  BuildContext context,
  Uri uri, {
  RestorationBucket? bucket,
}) async {
  final bucket = RestorationScope.of(context);
  bucket.write<String>(
    kRestoreRouteKey,
    json.encode({'route': Routes.document, 'url': uri.toString()}),
  );
  await loadHttpUrl(context, uri);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreOpenFileIdKey);
  bucket.remove<String>(kRestoreRouteKey);
}

Future<void> loadAndRememberAsset(
  BuildContext context,
  String key, {
  RestorationBucket? bucket,
}) async {
  final bucket = RestorationScope.of(context);
  bucket.write<String>(
    kRestoreRouteKey,
    json.encode({'route': Routes.document, 'assetKey': key}),
  );
  await loadAsset(context, key);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreOpenFileIdKey);
  bucket.remove<String>(kRestoreRouteKey);
}
