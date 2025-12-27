import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

PopupMenuItem<VoidCallback> wakelockMenuItem(
  BuildContext context, {
  required bool enabled,
  required void Function(bool) onChanged,
}) {
  return CheckedPopupMenuItem<VoidCallback>(
    checked: enabled,
    value: () => onChanged(!enabled),
    child: Text(AppLocalizations.of(context)!.menuItemWakelock),
  );
}
