import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/util.dart';

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({required this.child, super.key});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW):
            () => Navigator.maybePop(context),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
