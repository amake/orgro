import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orgro/src/fonts.dart';

PopupMenuEntry<VoidCallback> textScaleMenuItem(
  BuildContext context, {
  required double textScale,
  required Function(double) onChanged,
}) {
  return _PersistentPopupMenuItem<VoidCallback>(
    child: TextSizeAdjuster(
      onChanged: onChanged,
      value: textScale,
    ),
  );
}

PopupMenuEntry<VoidCallback> fontFamilyMenuItem(
  BuildContext context, {
  required String fontFamily,
  required Function(String) onChanged,
}) {
  return _PersistentPopupMenuItem<VoidCallback>(
    child: FontFamilySelector(
      onChanged: onChanged,
      value: fontFamily,
    ),
  );
}

class TextStyleButton extends StatefulWidget {
  const TextStyleButton({
    required this.textScale,
    required this.onTextScaleChanged,
    required this.fontFamily,
    required this.onFontFamilyChanged,
    super.key,
  });

  final double textScale;
  final Function(double) onTextScaleChanged;
  final String fontFamily;
  final Function(String) onFontFamilyChanged;

  @override
  State createState() => _TextStyleButtonState();
}

class _TextStyleButtonState extends State<TextStyleButton>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_size),
      onPressed: () =>
          Overlay.of(context)?.insertAll(_overlays(context).toList()),
    );
  }

  Iterable<OverlayEntry> _overlays(BuildContext context) sync* {
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    final position = _buttonPosition(context);
    late OverlayEntry buttonsOverlay, barrierOverlay;

    Future<void> closeOverlay() async {
      await animationController.reverse();
      barrierOverlay.remove();
      buttonsOverlay.remove();
      animationController.dispose();
    }

    buttonsOverlay = OverlayEntry(builder: (context) {
      return Positioned(
        top: position.top,
        right: position.right,
        child: PopupPalette(
          listenable: animationController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextSizeAdjuster(
                value: widget.textScale,
                onChanged: widget.onTextScaleChanged,
              ),
              FontFamilySelector(
                value: widget.fontFamily,
                onChanged: widget.onFontFamilyChanged,
                onOpen: closeOverlay,
              )
            ],
          ),
        ),
      );
    });
    yield barrierOverlay = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTapDown: (_) => closeOverlay(),
        behavior: HitTestBehavior.opaque,
      );
    });
    yield buttonsOverlay;
    animationController.forward();
  }

  RelativeRect _buttonPosition(BuildContext context) {
    // Copied from PopupMenuButtonState.showButtonMenu()
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)?.context.findRenderObject() as RenderBox;
    return RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
  }
}

class PopupPalette extends AnimatedWidget {
  const PopupPalette({
    required super.listenable,
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Material(
      type: MaterialType.card,
      elevation: PopupMenuTheme.of(context).elevation ?? 8,
      child: SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        axisAlignment: 1,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}

class TextSizeAdjuster extends StatefulWidget {
  const TextSizeAdjuster({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double value;
  final Function(double) onChanged;

  @override
  State createState() => _TextSizeAdjusterState();
}

const _kTextSizeAdjustmentIncrement = 10;
const _kTextSizeAdjustmentFactor = 100;

class _TextSizeAdjusterState extends State<TextSizeAdjuster> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value * _kTextSizeAdjustmentFactor;
  }

  void _setValue(double newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue / _kTextSizeAdjustmentFactor);
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(color: DefaultTextStyle.of(context).style.color),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _setValue(_value - _kTextSizeAdjustmentIncrement),
          ),
          Text(
            '${(_value / _kTextSizeAdjustmentFactor * 100).toStringAsFixed(0)}%',
            style: DefaultTextStyle.of(context).style.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _setValue(_value + _kTextSizeAdjustmentIncrement),
          )
        ],
      ),
    );
  }
}

class FontFamilySelector extends StatefulWidget {
  const FontFamilySelector({
    required this.value,
    required this.onChanged,
    this.onOpen,
    super.key,
  });

  final String value;
  final Function(String) onChanged;
  final VoidCallback? onOpen;

  @override
  State createState() => _FontFamilySelectorState();
}

class _FontFamilySelectorState extends State<FontFamilySelector> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  void _setValue(String? newValue) {
    if (newValue != null) {
      if (mounted) {
        setState(() => _value = newValue);
      }
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.font_download),
      label: Text(_value),
      onPressed: () async {
        widget.onOpen?.call();
        final selection = await _choose(context);
        _setValue(selection);
      },
      style: TextButton.styleFrom(
        foregroundColor: DefaultTextStyle.of(context).style.color,
      ),
    );
  }

  Future<String?> _choose(BuildContext context) async => showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          children: [
            for (final family
                in availableFontFamilies.toList(growable: false)..sort())
              CheckboxListTile(
                value: _value == family,
                title: Text(family),
                onChanged: (_) => Navigator.pop(context, family),
              ),
          ],
        ),
      );
}

/// A popup menu item that doesn't close when tapped and doesn't provide its own
/// [InkWell], unlike [PopupMenuItem].
class _PersistentPopupMenuItem<T> extends PopupMenuEntry<T> {
  const _PersistentPopupMenuItem({required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => _PersistentPopupMenuItemState();

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(Object? value) => false;
}

class _PersistentPopupMenuItemState extends State<_PersistentPopupMenuItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      constraints: BoxConstraints(minHeight: widget.height),
      padding: const EdgeInsets.symmetric(horizontal: _kMenuHorizontalPadding),
      child: widget.child,
    );
  }
}

// Keep in sync with same from popup_menu.dart
const double _kMenuHorizontalPadding = 16;
