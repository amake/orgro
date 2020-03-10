import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void _scrollTo(ScrollController controller, double position) =>
    controller.animateTo(position,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);

class ScrollTopButton extends StatelessWidget {
  const ScrollTopButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.vertical_align_top),
      onPressed: () => _scrollToTop(context),
    );
  }

  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.minScrollExtent);
  }
}

class ScrollBottomButton extends StatelessWidget {
  const ScrollBottomButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.vertical_align_bottom),
      onPressed: () => _scrollToBottom(context),
    );
  }

  void _scrollToBottom(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.maxScrollExtent);
  }
}
