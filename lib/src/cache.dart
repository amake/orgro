import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';
import 'package:path_provider/path_provider.dart';

Future<void> clearCaches(BuildContext context) async {
  await DefaultCacheManager().emptyCache();
  if (context.mounted) {
    final prefs = Preferences.of(context);
    await prefs.setRemoteImagesPolicy(kDefaultRemoteImagesPolicy);
    await prefs.setSaveChangesPolicy(kDefaultSaveChangesPolicy);
    await prefs.setLocalLinksPolicy(kDefaultLocalLinksPolicy);
    await prefs.setDecryptPolicy(kDefaultDecryptPolicy);
    await prefs.setCustomFilterQueries(const []);
    await prefs.setScopedPreferencesJson(null);
    for (final dir in prefs.accessibleDirs) {
      try {
        await disposeNativeSourceIdentifier(dir);
      } on Exception catch (e, s) {
        logError(e, s);
      }
    }
    await prefs.setAccessibleDirs(const []);
  }
  await clearFontCache();
  await clearTemporaryAttachments();
}

Future<Directory> getTemporaryAttachmentsDirectory() async {
  final tmp = await getTemporaryDirectory();
  return Directory.fromUri(tmp.uri.resolveUri(Uri(path: 'attachments')))
    ..createSync(recursive: true);
}

Future<void> clearTemporaryAttachments() async {
  final tmp = await getTemporaryAttachmentsDirectory();
  debugPrint('Deleting attachments: ${tmp.listSync()}');
  await tmp.delete(recursive: true);
}
