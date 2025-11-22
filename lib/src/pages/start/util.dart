import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/routes/routes.dart';

Future<void> loadAndRememberFile(
  BuildContext context,
  FutureOr<NativeDataSource?> fileInfoFuture, {
  InitialMode? mode,
  AfterOpenCallback? afterOpen,
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
  await loadDocument(context, dataSource, mode: mode, afterOpen: afterOpen);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreRouteKey);
}

Future<void> loadAndRememberUrl(BuildContext context, Uri uri) async {
  final bucket = RestorationScope.of(context);
  bucket.write<String>(
    kRestoreRouteKey,
    json.encode({'route': Routes.document, 'url': uri.toString()}),
  );
  await loadHttpUrl(context, uri);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreRouteKey);
}

Future<void> loadAndRememberAsset(
  BuildContext context,
  String key, {
  InitialMode? mode,
  AfterOpenCallback? afterOpen,
}) async {
  final bucket = RestorationScope.of(context);
  bucket.write<String>(
    kRestoreRouteKey,
    json.encode({'route': Routes.document, 'assetKey': key}),
  );
  await loadAsset(context, key, mode: mode, afterOpen: afterOpen);
  debugPrint('Clearing saved state from bucket $bucket');
  bucket.remove<String>(kRestoreRouteKey);
}
