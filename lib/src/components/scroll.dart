import 'dart:async';

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
  Timer? _timer;
  bool _isScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PrimaryScrollController.of(context);
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (_timer != null) return;

    // If we check the scroll direction immediately, we will never find the idle
    // state. Thus we *would* schedule the check for the next frame, but
    // sometimes it seems that the next frame won't reliably find the idle state
    // either. Thus we poll until we find the idle state.
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final isScrolling =
          _controller.hasClients &&
          _controller.position.userScrollDirection != ScrollDirection.idle;
      if (isScrolling != _isScrolling) {
        setState(() => _isScrolling = isScrolling);
      }
      if (!isScrolling) {
        timer.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isScrolling);
}
