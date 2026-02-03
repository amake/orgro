import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/app_purchase.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';
import 'package:path_provider/path_provider.dart';

Future<void> clearCaches() async => await Future.wait([
  DefaultCacheManager().emptyCache(),
  clearFontCache(),
  clearTemporaryAttachments(),
]);

Future<void> superClearCaches() async => await Future.wait([
  clearCaches(),
  getLegacyPurchaseCacheFile().then((file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }),
]);

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

class ClearCachesListItem extends StatelessWidget {
  const ClearCachesListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final devMode = Preferences.of(
      context,
      PrefsAspect.customization,
    ).developerMode;
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsActionClearCache),
      onLongPress: devMode
          ? () async {
              await superClearCaches();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.snackbarMessageCacheCleared,
                    ),
                  ),
                );
              }
            }
          : null,
      onTap: () async {
        await clearCaches();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.snackbarMessageCacheCleared,
              ),
            ),
          );
        }
      },
    );
  }
}
