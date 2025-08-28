import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

void _scrollTo(ScrollController controller, double position) =>
    controller.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );

class ScrollToTopIntent extends Intent {
  const ScrollToTopIntent();
}

class ScrollToTopAction extends ContextAction<ScrollToTopIntent> {
  @override
  void invoke(covariant ScrollToTopIntent intent, [BuildContext? context]) {
    if (context != null) {
      _scrollToTop(context);
    }
  }
}

void _scrollToTop(BuildContext context) {
  final controller = PrimaryScrollController.of(context);
  _scrollTo(controller, controller.position.minScrollExtent);
}

class ScrollToBottomIntent extends Intent {
  const ScrollToBottomIntent();
}

class ScrollToBottomAction extends ContextAction<ScrollToBottomIntent> {
  @override
  void invoke(covariant ScrollToBottomIntent intent, [BuildContext? context]) {
    if (context != null) {
      _scrollToBottom(context);
    }
  }
}

void _scrollToBottom(BuildContext context) {
  final controller = PrimaryScrollController.of(context);
  _scrollTo(controller, controller.position.maxScrollExtent);
}

class ScrollTopButton extends StatelessWidget {
  const ScrollTopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_up),
      onPressed: Actions.handler(context, const ScrollToTopIntent()),
    );
  }
}

PopupMenuItem<VoidCallback> scrollTopMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: Actions.handler(context, ScrollToTopIntent()),
    child: Text(AppLocalizations.of(context)!.menuItemScrollTop),
  );
}

class ScrollBottomButton extends StatelessWidget {
  const ScrollBottomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      onPressed: Actions.handler(context, const ScrollToBottomIntent()),
    );
  }
}

PopupMenuItem<VoidCallback> scrollBottomMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: Actions.handler(context, ScrollToBottomIntent()),
    child: Text(AppLocalizations.of(context)!.menuItemScrollBottom),
  );
}
