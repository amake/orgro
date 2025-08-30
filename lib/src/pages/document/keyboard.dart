import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/actions/common.dart';
import 'package:orgro/src/actions/scroll.dart';
import 'package:orgro/src/actions/search.dart';
import 'package:orgro/src/util.dart';

class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    required this.child,
    required this.onEdit,
    required this.onUndo,
    required this.onRedo,
    required this.searchDelegate,
    super.key,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  final MySearchDelegate searchDelegate;

  bool get searchMode => searchDelegate.searchMode.value;

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
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyG):
            const NavigateSearchHitsIntent(forward: true),
        LogicalKeySet(
          platformShortcutKey,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyG,
        ): const NavigateSearchHitsIntent(
          forward: false,
        ),
      },
      child: Actions(
        actions: {
          CloseViewIntent: CloseViewAction(),
          EditIntent: CallbackAction(onInvoke: (_) => onEdit()),
          ScrollToDocumentBoundaryIntent: ScrollToDocumentBoundaryAction(),
          UndoTextIntent: CallbackAction(onInvoke: (_) => onUndo()),
          RedoTextIntent: CallbackAction(onInvoke: (_) => onRedo()),
          SearchIntent: CallbackAction(
            onInvoke: (_) => searchDelegate.start(context),
          ),
          NavigateSearchHitsIntent: CallbackAction<NavigateSearchHitsIntent>(
            onInvoke: (intent) {
              if (searchMode) {
                searchDelegate.navigateSearchHits(forward: intent.forward);
              }
              return null;
            },
          ),
        },
        child: FocusScope(autofocus: true, child: child),
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

class NavigateSearchHitsIntent extends Intent {
  const NavigateSearchHitsIntent({required this.forward});
  final bool forward;
}
