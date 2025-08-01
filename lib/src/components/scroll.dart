import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class HideOnScroll extends StatelessWidget {
  const HideOnScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PrimaryScrollController.of(context),
      builder: (context, child) {
        final controller = PrimaryScrollController.of(context);
        var showFab = true;
        if (controller.hasClients &&
            controller.position.userScrollDirection != ScrollDirection.idle) {
          showFab =
              controller.position.userScrollDirection ==
              ScrollDirection.forward;
        }
        return AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: showFab ? 1 : 0,
          child: child,
        );
      },
      child: child,
    );
  }
}
