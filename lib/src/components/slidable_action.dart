import 'dart:math';

import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orgro/src/util.dart';

const _kFloatingIconLabelPadding = 24.0;
const _kFloatingIconLabelSpacing = 4.0;

class ResponsiveSlidableAction extends StatelessWidget {
  const ResponsiveSlidableAction({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = this.backgroundColor ?? theme.colorScheme.secondary;
    final foregroundColor =
        this.foregroundColor ?? theme.colorScheme.onSecondary;
    final iconSize = IconTheme.of(context).size!;
    final textHeight = theme.textTheme.labelLarge!.fontSize!;
    final shortThreshold =
        iconSize +
        2 * _kFloatingIconLabelPadding +
        _kFloatingIconLabelSpacing +
        textHeight;
    return Expanded(
      child: SizedBox.expand(
        child: OutlinedButton(
          onPressed: () {
            onPressed();
            Slidable.of(context)?.close();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledForegroundColor: backgroundColor.withAlpha(
              (0.38 * 255).round(),
            ),
            foregroundColor: foregroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            side: BorderSide.none,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxHeight < shortThreshold
                ? _SmallIconLabel(icon: icon, label: label)
                : _FloatingIconLabel(
                    icon: icon,
                    label: label,
                    width: constraints.maxWidth,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SmallIconLabel extends StatelessWidget {
  const _SmallIconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [Icon(icon), Text(label)],
    );
  }
}

class _FloatingIconLabel extends StatefulWidget {
  const _FloatingIconLabel({
    required this.icon,
    required this.label,
    required this.width,
  });

  final IconData icon;
  final String label;
  final double width;

  @override
  State<_FloatingIconLabel> createState() => _FloatingIconLabelState();
}

class _FloatingIconLabelState extends State<_FloatingIconLabel> {
  late ScrollController _scrollController;
  final _outerKey = GlobalKey();
  final _innerKey = GlobalKey();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController = PrimaryScrollController.of(context)
      ..addListener(_handleScroll);
  }

  void _handleScroll() {
    final outerBounds = _outerKey.currentContext?.globalPaintBounds;
    final innerBounds = _innerKey.currentContext?.globalPaintBounds;
    if (outerBounds == null || innerBounds == null) return;
    final outerHeight = outerBounds.height;
    final innerHeight = innerBounds.height;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenPadding = MediaQuery.paddingOf(context);
    final usableScreenHeight =
        screenHeight - kToolbarHeight - screenPadding.top;
    double offset;
    if (outerHeight > usableScreenHeight) {
      // If we wanted to align to the middle of the screen we would do:
      // offset = screenHeight / 2 - outerBounds.top - innerHeight / 2;
      // But the label looks disconnected from the content that way.
      //
      // Align to top of outer container
      if (outerBounds.top < kToolbarHeight + screenPadding.top) {
        offset = -outerBounds.top + kToolbarHeight + screenPadding.top;
      } else if (outerBounds.top + innerHeight > screenHeight) {
        offset = screenHeight - outerBounds.top - innerHeight;
      } else {
        offset = 0;
      }
    } else {
      // Align to middle of outer container
      final middleTop = outerHeight / 2 - innerHeight / 2;
      final middleBottom = outerHeight / 2 + innerHeight / 2;
      if (outerBounds.top + middleTop < kToolbarHeight + screenPadding.top) {
        offset = -outerBounds.top + kToolbarHeight + screenPadding.top;
      } else if (outerBounds.top + middleBottom > screenHeight) {
        offset = screenHeight - outerBounds.top - innerHeight;
      } else {
        offset = middleTop;
      }
    }
    final maxOffset = outerHeight - innerHeight;
    offset = min(max(0, offset), maxOffset);
    if (offset != _offset) {
      setState(() => _offset = offset);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _outerKey,
      children: [
        Positioned(
          top: _offset,
          key: _innerKey,
          child: SizedBox(
            width: widget.width,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _kFloatingIconLabelPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: _kFloatingIconLabelSpacing,
                children: [Icon(widget.icon), Text(widget.label)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
