import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/actions/common.dart';
import 'package:orgro/src/actions/scroll.dart';
import 'package:orgro/src/util.dart';

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    required this.child,
    required this.onEdit,
    required this.onSearch,
    super.key,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW):
            const CloseViewIntent(),
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyE):
            const EditIntent(),
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyF):
            const SearchIntent(),
        SingleActivator(LogicalKeyboardKey.home): const ScrollToTopIntent(),
        SingleActivator(LogicalKeyboardKey.end): const ScrollToBottomIntent(),
      },
      child: Actions(
        actions: {
          CloseViewIntent: CloseViewAction(),
          EditIntent: CallbackAction(onInvoke: (_) => onEdit()),
          SearchIntent: CallbackAction(onInvoke: (_) => onSearch()),
          ScrollToTopIntent: ScrollToTopAction(),
          ScrollToBottomIntent: ScrollToBottomAction(),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class EditIntent extends Intent {
  const EditIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}
