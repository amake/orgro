import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextSizeButton extends StatefulWidget {
  const TextSizeButton({this.value, this.onChanged, Key key}) : super(key: key);

  final double value;
  final Function(double) onChanged;

  @override
  _TextSizeButtonState createState() => _TextSizeButtonState();
}

class _TextSizeButtonState extends State<TextSizeButton>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_size),
      onPressed: () =>
          Overlay.of(context).insertAll(_overlays(context).toList()),
    );
  }

  Iterable<OverlayEntry> _overlays(BuildContext context) sync* {
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    final renderObject = context.findRenderObject();
    final translation = renderObject.getTransformTo(null).getTranslation();
    final bounds =
        renderObject.paintBounds.shift(Offset(translation.x, translation.y));
    final screen = MediaQuery.of(context).size;
    final buttonsOverlay = OverlayEntry(builder: (context) {
      return Positioned(
        top: bounds.bottom - 8,
        right: screen.width - bounds.right,
        child: FadeTransition(
          opacity: animationController,
          child: TextSizePalette(
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      );
    });
    OverlayEntry barrierOverlay;
    yield barrierOverlay = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTap: () async {
          await animationController.reverse();
          barrierOverlay.remove();
          buttonsOverlay.remove();
          animationController.dispose();
        },
        child: Container(color: Colors.transparent),
      );
    });
    yield buttonsOverlay;
    animationController.forward();
  }
}

class TextSizePalette extends StatefulWidget {
  const TextSizePalette({this.value, this.onChanged, Key key})
      : super(key: key);

  final double value;
  final Function(double) onChanged;

  @override
  _TextSizePaletteState createState() => _TextSizePaletteState();
}

const _kTextSizeAdjustmentIncrement = 0.12;

class _TextSizePaletteState extends State<TextSizePalette> {
  double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  void _setValue(double newValue) {
    setState(() {
      _value = newValue;
    });
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      child: InkWell(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () =>
                  _setValue(_value - _kTextSizeAdjustmentIncrement),
            ),
            Text(
              _value.toStringAsFixed(2),
              style:
                  const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () =>
                  _setValue(_value + _kTextSizeAdjustmentIncrement),
            )
          ],
        ),
      ),
    );
  }
}
