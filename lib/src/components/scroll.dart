import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ScrollingBuilder extends StatelessWidget {
  const ScrollingBuilder({required this.builder, super.key});

  final Widget Function(BuildContext, bool) builder;

  @override
  Widget build(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isScrolling =
            controller.hasClients &&
            controller.position.userScrollDirection != ScrollDirection.idle;
        return builder(context, isScrolling);
      },
    );
  }
}
