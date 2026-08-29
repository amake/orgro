import 'package:flutter/widgets.dart';

extension ActionsUtil on Actions {
  // Work around https://github.com/flutter/flutter/issues/191045
  static VoidCallback? handler<T extends Intent>(
    BuildContext context,
    T intent,
  ) {
    final Action<Intent>? action = Actions.maybeFind<T>(context);
    if (action != null && action._isEnabled(intent, context)) {
      return () {
        // Could be that the action was enabled when the closure was created,
        // but is now no longer enabled, so check again.
        if (action._isEnabled(intent, context)) {
          Actions.of(context).invokeAction(action, intent, context);
        }
      };
    }
    return null;
  }
}

extension _ActionUtil<T extends Intent> on Action<T> {
  // This merely works around the fact that the real _isEnabled method is
  // private, and we need to call it from the ActionsUtil extension.
  bool _isEnabled(T intent, BuildContext? context) => switch (this) {
    final ContextAction<T> action => action.isEnabled(intent, context),
    _ => isEnabled(intent),
  };
}
