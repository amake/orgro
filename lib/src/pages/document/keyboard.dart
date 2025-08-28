import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/actions/common.dart';
import 'package:orgro/src/actions/scroll.dart';
import 'package:orgro/src/util.dart';

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({required this.child, super.key});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW):
            const CloseViewIntent(),
        SingleActivator(LogicalKeyboardKey.home): const ScrollToTopIntent(),
        SingleActivator(LogicalKeyboardKey.end): const ScrollToBottomIntent(),
      },
      child: Actions(
        actions: {
          CloseViewIntent: CloseViewAction(),
          ScrollToTopIntent: ScrollToTopAction(),
          ScrollToBottomIntent: ScrollToBottomAction(),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
