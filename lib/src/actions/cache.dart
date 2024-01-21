import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

PopupMenuItem<VoidCallback> clearCacheMenuItem(BuildContext context) {
  final prefs = Preferences.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final snackBar = SnackBar(
    content: Text(AppLocalizations.of(context)!.snackbarMessageCacheCleared),
  );
  return PopupMenuItem<VoidCallback>(
    value: () async {
      await DefaultCacheManager().emptyCache();
      await prefs.setRemoteImagesPolicy(kDefaultRemoteImagesPolicy);
      await prefs.setSaveChangesPolicy(kDefaultSaveChangesPolicy);
      await prefs.setCustomFilterQueries(const []);
      for (final dir in prefs.accessibleDirs) {
        try {
          await disposeNativeSourceIdentifier(dir);
        } on Exception catch (e, s) {
          logError(e, s);
        }
      }
      await prefs.setAccessibleDirs(const []);
      await clearFontCache();
      scaffoldMessenger.showSnackBar(snackBar);
    },
    child: Text(AppLocalizations.of(context)!.menuItemClearCache),
  );
}
