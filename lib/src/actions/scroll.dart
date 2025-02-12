import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

void _scrollTo(ScrollController controller, double position) =>
    controller.animateTo(position,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);

void _scrollToTop(BuildContext context) {
  final controller = PrimaryScrollController.of(context);
  _scrollTo(controller, controller.position.minScrollExtent);
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
      onPressed: () => _scrollToTop(context),
    );
  }
}

PopupMenuItem<VoidCallback> scrollTopMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: () => _scrollToTop(context),
    child: Text(AppLocalizations.of(context)!.menuItemScrollTop),
  );
}

class ScrollBottomButton extends StatelessWidget {
  const ScrollBottomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      onPressed: () => _scrollToBottom(context),
    );
  }
}

PopupMenuItem<VoidCallback> scrollBottomMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: () => _scrollToBottom(context),
    child: Text(AppLocalizations.of(context)!.menuItemScrollBottom),
  );
}
