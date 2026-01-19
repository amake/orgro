import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

PopupMenuItem<VoidCallback> readerModeMenuItem(
  BuildContext context, {
  required bool enabled,
  required void Function(bool) onChanged,
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
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.tooltipReaderMode,
      icon: const Icon(Icons.chrome_reader_mode),
      color: enabled ? Theme.of(context).colorScheme.secondary : null,
      onPressed: () => onChanged(!enabled),
    );
  }
}
