import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/navigation.dart';

PopupMenuItem<VoidCallback> undoMenuItem(
  BuildContext context, {
  required VoidCallback onChanged,
}) {
  return PopupMenuItem<VoidCallback>(
    value: onChanged,
    enabled: DocumentProvider.of(context)!.canUndo,
    child: Text(AppLocalizations.of(context)!.menuItemUndo),
  );
}

PopupMenuItem<VoidCallback> redoMenuItem(
  BuildContext context, {
  required VoidCallback onChanged,
}) {
  return PopupMenuItem<VoidCallback>(
    value: onChanged,
    enabled: DocumentProvider.of(context)!.canRedo,
    child: Text(AppLocalizations.of(context)!.menuItemRedo),
  );
}
