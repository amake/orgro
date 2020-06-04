import 'package:flutter/material.dart';

PopupMenuItem<VoidCallback> readerModeMenuItem(
  BuildContext context, {
  @required bool enabled,
  @required Function(bool) onChanged,
}) {
  assert(enabled != null);
  assert(onChanged != null);
  return CheckedPopupMenuItem<VoidCallback>(
    checked: enabled,
    value: () => onChanged(!enabled),
    child: const Text('Reader mode'),
  );
}

class ReaderModeButton extends StatelessWidget {
  const ReaderModeButton({
    @required this.enabled,
    @required this.onChanged,
    Key key,
  })  : assert(enabled != null),
        super(key: key);

  final bool enabled;
  final Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chrome_reader_mode),
      color: enabled ? Theme.of(context).accentColor : null,
      onPressed: () => onChanged(!enabled),
    );
  }
}
