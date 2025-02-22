import 'package:flutter/material.dart';

class BottomInputBar extends StatelessWidget {
  const BottomInputBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Hack around bottom sheet not respecting bottom safe area:
    // https://github.com/flutter/flutter/issues/69676
    //
    // Get the padding here because it will be zero in the BottomSheet's
    // builder's context.
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return BottomSheet(
      enableDrag: false,
      showDragHandle: false,
      onClosing: () {
        // This should never happen
        debugPrint('Closing bottom sheet');
      },
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: child,
          ),
    );
  }
}
