import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class HideOnScroll extends StatefulWidget {
  const HideOnScroll({required this.child, super.key});

  final Widget child;

  @override
  State<HideOnScroll> createState() => _HideOnScrollState();
}

class _HideOnScrollState extends State<HideOnScroll> {
  late ScrollController _controller;
  bool _showFab = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PrimaryScrollController.of(context);
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_controller.hasClients &&
        _controller.position.userScrollDirection != ScrollDirection.idle) {
      setState(() {
        _showFab =
            _controller.position.userScrollDirection == ScrollDirection.forward;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: _showFab ? 1 : 0,
      child: widget.child,
    );
  }
}
