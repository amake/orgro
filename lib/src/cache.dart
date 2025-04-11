import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/fonts.dart';
import 'package:path_provider/path_provider.dart';

Future<void> clearCaches() async => await Future.wait([
  DefaultCacheManager().emptyCache(),
  clearFontCache(),
  clearTemporaryAttachments(),
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

Widget clearCachesListItem(BuildContext context) => ListTile(
  title: Text(AppLocalizations.of(context)!.settingsActionClearCache),
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
