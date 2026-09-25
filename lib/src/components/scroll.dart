import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SnapDirectionScrollController extends ScrollController {
  SnapDirectionScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _SnapDirectionScrollPosition(
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

// This filters ordinary end-of-drag thumb adjustments but remains small enough
// that a deliberate reversal feels immediate.
const _kDirectionChangeThreshold = 24;

class _SnapDirectionScrollPosition extends ScrollPositionWithSingleContext {
  _SnapDirectionScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  ScrollDirection? _pendingDirection;
  double _pendingDistance = 0;
  bool _applyingUserOffset = false;
  bool _allowDirectionUpdate = false;

  @override
  void applyUserOffset(double delta) {
    final direction = delta > 0
        ? ScrollDirection.forward
        : ScrollDirection.reverse;

    if (direction == userScrollDirection || userScrollDirection == .idle) {
      _pendingDirection = null;
      _pendingDistance = 0;
      _allowDirectionUpdate = true;
    } else {
      if (_pendingDirection != direction) {
        _pendingDirection = direction;
        _pendingDistance = 0;
      }
      _pendingDistance += delta.abs();
      _allowDirectionUpdate = _pendingDistance >= _kDirectionChangeThreshold;
      if (_allowDirectionUpdate) {
        _pendingDirection = null;
        _pendingDistance = 0;
      }
    }
    _applyingUserOffset = true;
    try {
      super.applyUserOffset(delta);
    } finally {
      _applyingUserOffset = false;
      _allowDirectionUpdate = false;
    }
  }

  @override
  void updateUserScrollDirection(ScrollDirection value) {
    if (value == .idle) {
      _pendingDirection = null;
      _pendingDistance = 0;
      super.updateUserScrollDirection(value);
    } else if (!_applyingUserOffset || _allowDirectionUpdate) {
      super.updateUserScrollDirection(value);
    }
  }
}

class SnapDirectionScrollScope extends StatefulWidget {
  const SnapDirectionScrollScope({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<SnapDirectionScrollScope> createState() =>
      _SnapDirectionScrollScopeState();
}

class _SnapDirectionScrollScopeState extends State<SnapDirectionScrollScope> {
  final _scrollController = SnapDirectionScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _scrollController,
    child: Builder(builder: widget.builder),
  );
}

class ScrollingBuilder extends StatefulWidget {
  const ScrollingBuilder({required this.builder, super.key});

  final Widget Function(BuildContext, bool) builder;

  @override
  State<ScrollingBuilder> createState() => _ScrollingBuilderState();
}

class _ScrollingBuilderState extends State<ScrollingBuilder> {
  ScrollController? _controller;
  Timer? _timer;
  bool _isScrolling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This can be called multiple times, especially in e.g. an Android
    // predictive back gesture.
    _controller?.removeListener(_onScroll);
    _controller = PrimaryScrollController.of(context)..addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (_timer != null) return;

    // If we check the scroll direction immediately, we will never find the idle
    // state. Thus we *would* schedule the check for the next frame, but
    // sometimes it seems that the next frame won't reliably find the idle state
    // either. Thus we poll until we find the idle state.
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final controller = _controller;
      final isScrolling =
          controller != null &&
          controller.hasClients &&
          controller.position.userScrollDirection != ScrollDirection.idle;
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
    _controller?.removeListener(_onScroll);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isScrolling);
}
