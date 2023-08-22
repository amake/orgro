import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

PopupMenuItem<VoidCallback> readerModeMenuItem(
  BuildContext context, {
  required bool enabled,
  required Function(bool) onChanged,
}) {
  return CheckedPopupMenuItem<VoidCallback>(
    checked: enabled,
    value: () => onChanged(!enabled),
    child: Text(AppLocalizations.of(context)!.menuItemReaderMode),
  );
}

class ReaderModeButton extends StatelessWidget {
  const ReaderModeButton({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chrome_reader_mode),
      color: enabled ? Theme.of(context).colorScheme.primary : null,
      onPressed: () => onChanged(!enabled),
    );
  }
}
