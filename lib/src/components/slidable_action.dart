import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:orgro/src/util.dart';

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
    final backgroundColor =
        this.backgroundColor ?? Theme.of(context).colorScheme.secondary;
    final foregroundColor =
        this.foregroundColor ?? Theme.of(context).colorScheme.onSecondary;
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
            builder: (context, constraints) {
              final short =
                  constraints.maxHeight < IconTheme.of(context).size! * 2;
              if (short) {
                return _SmallIconLabel(icon: icon, label: label);
              }
              final veryTall =
                  constraints.maxHeight > MediaQuery.sizeOf(context).height / 2;
              if (veryTall) {
                return _FloatingIconLabel(icon: icon, label: label);
              }
              return _MediumIconLabel(icon: icon, label: label);
            },
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

class _MediumIconLabel extends StatelessWidget {
  const _MediumIconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [Icon(icon), Text(label)],
    );
  }
}

class _FloatingIconLabel extends StatefulWidget {
  const _FloatingIconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
    if (outerBounds == null) return;
    final top = outerBounds.top;
    var offset = top < 0 ? -top : 0.0;
    final innerBounds = _innerKey.currentContext?.globalPaintBounds;
    if (innerBounds != null) {
      final innerHeight = innerBounds.height;
      final outerHeight = outerBounds.height;
      final maxOffset = outerHeight - innerHeight;
      if (offset > maxOffset) {
        offset = maxOffset;
      }
    }
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
    return Column(
      key: _outerKey,
      children: [
        SizedBox(height: _offset),
        Padding(
          key: _innerKey,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [Icon(widget.icon), Text(widget.label)],
          ),
        ),
      ],
    );
  }
}
