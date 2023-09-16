import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

PopupMenuItem<VoidCallback> fullWidthMenuItem(
  BuildContext context, {
  required bool enabled,
  required void Function(bool) onChanged,
}) {
  return CheckedPopupMenuItem<VoidCallback>(
    checked: enabled,
    value: () => onChanged(!enabled),
    child: Text(AppLocalizations.of(context)!.menuItemFullWidth),
  );
}

class FullWidthButton extends StatelessWidget {
  const FullWidthButton({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Transform.rotate(
        angle: pi / 2,
        child: const Icon(Icons.expand),
      ),
      color: enabled ? Theme.of(context).colorScheme.secondary : null,
      onPressed: () => onChanged(!enabled),
    );
  }
}
