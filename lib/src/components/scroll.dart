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
        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: showFab ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showFab ? 1.0 : 0.0,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
