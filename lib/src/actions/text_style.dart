import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/fonts.dart';

PopupMenuEntry<VoidCallback> textScaleMenuItem(
  BuildContext context, {
  required double textScale,
  required void Function(double) onChanged,
}) {
  return _PersistentPopupMenuItem<VoidCallback>(
    child: TextSizeAdjuster(onChanged: onChanged, value: textScale),
  );
}

class TextScaleSettingListItem extends StatelessWidget {
  const TextScaleSettingListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final viewSettings = ViewSettings.of(context);
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(AppLocalizations.of(context)!.settingsItemTextScale),
          ),
          TextSizeAdjuster(
            value: viewSettings.textScale,
            onChanged: (value) => viewSettings.textScale = value,
          ),
        ],
      ),
    );
  }
}

PopupMenuEntry<VoidCallback> fontFamilyMenuItem(
  BuildContext context, {
  required String fontFamily,
  required void Function(String) onChanged,
}) {
  return _PersistentPopupMenuItem<VoidCallback>(
    child: FontFamilySelector(onChanged: onChanged, value: fontFamily),
  );
}

class FontFamilySettingListItem extends StatelessWidget {
  const FontFamilySettingListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final viewSettings = ViewSettings.of(context);
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsItemFontFamily),
      subtitle: Text(viewSettings.fontFamily),
      onTap: () async {
        final selection = await _chooseFont(context, viewSettings.fontFamily);
        if (selection != null) {
          viewSettings.fontFamily = selection;
        }
      },
    );
  }
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
  final void Function(double) onTextScaleChanged;
  final String fontFamily;
  final void Function(String) onFontFamilyChanged;

  @override
  State createState() => _TextStyleButtonState();
}

class _TextStyleButtonState extends State<TextStyleButton>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.tooltipTextStyle,
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
    late final OverlayEntry buttonsOverlay, barrierOverlay;

    Future<void> closeOverlay() async {
      await animationController.reverse();
      barrierOverlay.remove();
      buttonsOverlay.remove();
      animationController.dispose();
    }

    buttonsOverlay = OverlayEntry(
      builder: (context) {
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
                ),
              ],
            ),
          ),
        );
      },
    );
    yield barrierOverlay = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTapDown: (_) => closeOverlay(),
          behavior: HitTestBehavior.opaque,
        );
      },
    );
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
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
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
        child: FadeTransition(opacity: animation, child: child),
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
  final void Function(double) onChanged;

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
  void didUpdateWidget(covariant TextSizeAdjuster oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _value = widget.value * _kTextSizeAdjustmentFactor;
    }
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
            tooltip: AppLocalizations.of(context)!.tooltipDecreaseTextScale,
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
            tooltip: AppLocalizations.of(context)!.tooltipIncreaseTextScale,
            icon: const Icon(Icons.add),
            onPressed: () => _setValue(_value + _kTextSizeAdjustmentIncrement),
          ),
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
  final void Function(String) onChanged;
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
        final selection = await _chooseFont(context, _value);
        _setValue(selection);
      },
      style: TextButton.styleFrom(
        foregroundColor: DefaultTextStyle.of(context).style.color,
      ),
    );
  }
}

Future<String?> _chooseFont(BuildContext context, String currentValue) async =>
    showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (final family in availableFontFamilies.toList(
            growable: false,
          )..sort())
            CheckboxListTile(
              value: currentValue == family,
              title: Text(family),
              onChanged: (_) => Navigator.pop(context, family),
            ),
        ],
      ),
    );

/// A popup menu item that doesn't close when tapped and doesn't provide its own
/// [InkWell], unlike [PopupMenuItem].
class _PersistentPopupMenuItem<T> extends PopupMenuEntry<T> {
  const _PersistentPopupMenuItem({required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => _PersistentPopupMenuItemState<T>();

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(Object? value) => false;
}

class _PersistentPopupMenuItemState<T>
    extends State<_PersistentPopupMenuItem<T>> {
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
