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
    required this.onUndo,
    required this.onRedo,
    super.key,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onSearch;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

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
        const SingleActivator(LogicalKeyboardKey.home):
            const ScrollToDocumentBoundaryIntent(forward: false),
        const SingleActivator(LogicalKeyboardKey.end):
            const ScrollToDocumentBoundaryIntent(forward: true),
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyZ):
            const UndoTextIntent(SelectionChangedCause.keyboard),
        LogicalKeySet(
          platformShortcutKey,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoTextIntent(
          SelectionChangedCause.keyboard,
        ),
      },
      child: Actions(
        actions: {
          CloseViewIntent: CloseViewAction(),
          EditIntent: CallbackAction(onInvoke: (_) => onEdit()),
          SearchIntent: CallbackAction(onInvoke: (_) => onSearch()),
          ScrollToDocumentBoundaryIntent: ScrollToDocumentBoundaryAction(),
          UndoTextIntent: CallbackAction(onInvoke: (_) => onUndo()),
          RedoTextIntent: CallbackAction(onInvoke: (_) => onRedo()),
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
