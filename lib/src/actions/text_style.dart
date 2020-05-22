import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleButton extends StatefulWidget {
  const TextStyleButton({
    @required this.textScale,
    @required this.onTextScaleChanged,
    @required this.fontFamily,
    @required this.onFontFamilyChanged,
    Key key,
  })  : assert(textScale != null),
        assert(onTextScaleChanged != null),
        assert(fontFamily != null),
        assert(onFontFamilyChanged != null),
        super(key: key);

  final double textScale;
  final Function(double) onTextScaleChanged;
  final String fontFamily;
  final Function(String) onFontFamilyChanged;

  @override
  _TextStyleButtonState createState() => _TextStyleButtonState();
}

class _TextStyleButtonState extends State<TextStyleButton>
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
    final position = _buttonPosition(context);
    OverlayEntry buttonsOverlay, barrierOverlay;

    Future<void> _closeOverlay() async {
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
          animation: animationController,
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
                onOpen: _closeOverlay,
              )
            ],
          ),
        ),
      );
    });
    yield barrierOverlay = OverlayEntry(builder: (context) {
      return GestureDetector(
        onTapDown: (_) => _closeOverlay(),
        behavior: HitTestBehavior.opaque,
      );
    });
    yield buttonsOverlay;
    animationController.forward();
  }

  RelativeRect _buttonPosition(BuildContext context) {
    // Copied from PopupMenuButtonState.showButtonMenu()
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
    @required Animation<double> animation,
    @required this.child,
    Key key,
  })  : assert(child != null),
        super(key: key, listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Material(
      type: MaterialType.card,
      elevation: PopupMenuTheme.of(context)?.elevation ?? 8,
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
    @required this.value,
    @required this.onChanged,
    Key key,
  })  : assert(value != null),
        assert(onChanged != null),
        super(key: key);

  final double value;
  final Function(double) onChanged;

  @override
  _TextSizeAdjusterState createState() => _TextSizeAdjusterState();
}

const _kTextSizeAdjustmentIncrement = 10;
const _kTextSizeAdjustmentFactor = 100;

class _TextSizeAdjusterState extends State<TextSizeAdjuster> {
  double _value;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _setValue(_value - _kTextSizeAdjustmentIncrement),
        ),
        Text(
          '${(_value / _kTextSizeAdjustmentFactor * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _setValue(_value + _kTextSizeAdjustmentIncrement),
        )
      ],
    );
  }
}

class FontFamilySelector extends StatefulWidget {
  const FontFamilySelector({
    @required this.value,
    @required this.onChanged,
    this.onOpen,
    Key key,
  })  : assert(value != null),
        assert(onChanged != null),
        super(key: key);

  final String value;
  final Function(String) onChanged;
  final VoidCallback onOpen;

  @override
  _FontFamilySelectorState createState() => _FontFamilySelectorState();
}

class _FontFamilySelectorState extends State<FontFamilySelector> {
  String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  void _setValue(String newValue) {
    if (newValue != null) {
      if (mounted) {
        setState(() => _value = newValue);
      }
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      icon: const Icon(Icons.font_download),
      label: Text(_value),
      onPressed: () async {
        widget.onOpen();
        final selection = await _choose(context);
        _setValue(selection);
      },
    );
  }

  Future<String> _choose(BuildContext context) async => showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          children: [
            for (final family in GoogleFonts.asMap().keys)
              CheckboxListTile(
                value: _value == family,
                title: Text(family),
                onChanged: (_) => Navigator.pop(context, family),
              ),
          ],
        ),
      );
}
