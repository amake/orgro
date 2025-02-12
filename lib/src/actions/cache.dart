import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/cache.dart';

PopupMenuItem<VoidCallback> clearCacheMenuItem(BuildContext context) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final snackBar = SnackBar(
    content: Text(AppLocalizations.of(context)!.snackbarMessageCacheCleared),
  );
  return PopupMenuItem<VoidCallback>(
    value: () async {
      await clearCaches(context);
      scaffoldMessenger.showSnackBar(snackBar);
    },
    child: Text(AppLocalizations.of(context)!.menuItemClearCache),
  );
}
