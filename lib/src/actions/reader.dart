import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

PopupMenuItem<VoidCallback> readerModeMenuItem(
    BuildContext context, VoidCallback onToggled) {
  return CheckedPopupMenuItem<VoidCallback>(
    checked: OrgController.of(context).hideMarkup,
    value: onToggled,
    child: const Text('Reader mode'),
  );
}

class ReaderModeButton extends StatelessWidget {
  const ReaderModeButton({
    @required this.enabled,
    @required this.onToggled,
    Key key,
  })  : assert(enabled != null),
        super(key: key);

  final bool enabled;
  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chrome_reader_mode),
      color: enabled ? Theme.of(context).accentColor : null,
      onPressed: onToggled,
    );
  }
}
