import 'package:flutter/widgets.dart';

class CloseViewIntent extends Intent {
  const CloseViewIntent();
}

class CloseViewAction extends ContextAction<CloseViewIntent> {
  @override
  void invoke(covariant CloseViewIntent intent, [BuildContext? context]) {
    if (context != null) {
      Navigator.maybePop(context);
    }
  }
}
