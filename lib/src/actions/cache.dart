import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

PopupMenuItem<VoidCallback> clearCacheMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: () async {
      await DefaultCacheManager().emptyCache();
      final prefs = Preferences.of(context);
      await prefs.setRemoteImagesPolicy(kDefaultRemoteImagesPolicy);
      for (final dir in prefs.accessibleDirs) {
        try {
          await disposeNativeSourceIdentifier(dir);
        } on Exception catch (e, s) {
          logError(e, s);
        }
      }
      await prefs.setAccessibleDirs(const []);
      await clearFontCache();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cache cleared')));
    },
    child: const Text('Clear cache'),
  );
}
