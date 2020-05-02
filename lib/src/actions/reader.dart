import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';

PopupMenuItem<VoidCallback> readerModeMenuItem(BuildContext context) {
  return CheckedPopupMenuItem<VoidCallback>(
    checked: OrgController.of(context).hideMarkup.value,
    value: () => _toggleHideMarkup(context),
    child: const Text('Reader mode'),
  );
}

class ReaderModeButton extends StatelessWidget {
  const ReaderModeButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: OrgController.of(context).hideMarkup,
      builder: (context, hideMarkup, child) {
        return IconButton(
          icon: const Icon(Icons.chrome_reader_mode),
          color: hideMarkup ? Theme.of(context).accentColor : null,
          onPressed: () => _toggleHideMarkup(context),
        );
      },
    );
  }
}

void _toggleHideMarkup(BuildContext context) {
  final hideMarkup = OrgController.of(context).hideMarkup;
  hideMarkup.value = !hideMarkup.value;
}
