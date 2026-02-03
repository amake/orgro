import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

typedef AppPurchaseInfo = Map<String, dynamic>;

enum AppPurchaseInfoSource { cache, native }

const _channel = MethodChannel('com.madlonkay.orgro/app_purchase');

Future<(AppPurchaseInfoSource, AppPurchaseInfo)> _appPurchaseInfoFromNative(
  bool refresh,
) async {
  final info = await _channel.invokeMapMethod<String, dynamic>(
    'getAppPurchaseInfo',
    {'refresh': refresh},
  );
  debugPrint('App purchase info: $info');
  return (AppPurchaseInfoSource.native, info!);
}

const _kLegacyPurchaseCacheFile = 'legacy_purchase_info.json';

Future<File> getLegacyPurchaseCacheFile() async {
  final dir = await getApplicationSupportDirectory();
  return File.fromUri(dir.uri.resolve(_kLegacyPurchaseCacheFile));
}

Future<(AppPurchaseInfoSource, AppPurchaseInfo)?>
_appPurchaseInfoFromCache() async {
  final file = await getLegacyPurchaseCacheFile();
  if (!await file.exists()) return null;

  final contents = await file.readAsString();
  final info = json.decode(contents) as Map<String, dynamic>;
  debugPrint('Cached app purchase info: $info');
  return (AppPurchaseInfoSource.cache, info);
}

Future<(AppPurchaseInfoSource, AppPurchaseInfo)> getAppPurchaseInfo(
  bool refresh,
) async => refresh
    ? await _appPurchaseInfoFromNative(true)
    : await _appPurchaseInfoFromCache() ??
          await _appPurchaseInfoFromNative(false);

Future<void> cacheAppPurchaseInfo(AppPurchaseInfo info) async {
  final file = await getLegacyPurchaseCacheFile();
  final contents = json.encode(info);
  await file.writeAsString(contents);
}
