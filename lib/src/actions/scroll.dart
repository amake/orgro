import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
  const ScrollTopButton({Key key}) : super(key: key);

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
    child: const Text('Scroll to top'),
    value: () => _scrollToTop(context),
  );
}

class ScrollBottomButton extends StatelessWidget {
  const ScrollBottomButton({Key key}) : super(key: key);

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
    child: const Text('Scroll to bottom'),
    value: () => _scrollToBottom(context),
  );
}
