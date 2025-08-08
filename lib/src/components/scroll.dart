import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ScrollingBuilder extends StatefulWidget {
  const ScrollingBuilder({required this.builder, super.key});

  final Widget Function(BuildContext, bool) builder;

  @override
  State<ScrollingBuilder> createState() => _ScrollingBuilderState();
}

class _ScrollingBuilderState extends State<ScrollingBuilder> {
  late final ScrollController _controller;
  bool _isScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PrimaryScrollController.of(context);
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    // If we check the scroll direction immediately, we will never find the idle
    // state. Thus we schedule the check for the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isScrolling =
          _controller.hasClients &&
          _controller.position.userScrollDirection != ScrollDirection.idle;
      if (isScrolling != _isScrolling) {
        setState(() => _isScrolling = isScrolling);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isScrolling);
}
