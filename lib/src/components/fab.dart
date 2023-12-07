import 'package:flutter/material.dart';

class BadgableFloatingActionButton extends StatelessWidget {
  const BadgableFloatingActionButton({
    required this.child,
    required this.badgeVisible,
    required this.onPressed,
    required this.heroTag,
    super.key,
  });

  final Widget child;
  final bool badgeVisible;
  final VoidCallback onPressed;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      child: _Badge(
        visible: badgeVisible,
        child: child,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.child,
    required this.visible,
  });

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        // Badge indicating an active query. The size and positioning is
        // manually adjusted to match the icon it adorns.
        Positioned(
          top: 0,
          right: 2,
          child: Visibility(
            visible: visible,
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
