import 'package:flutter/widgets.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

mixin ViewSettingsState<T extends StatefulWidget> on State<T> {
  Preferences get _prefs => Preferences.of(context);
  ViewSettingsData get _parent => ViewSettings.of(context);

  double? _textScale;

  double get textScale => _textScale!;

  set textScale(double value) {
    _prefs.textScale = value;
    setState(() => _textScale = value);
  }

  String? _fontFamily;

  String get fontFamily => _fontFamily!;

  set fontFamily(String value) {
    _prefs.fontFamily = value;
    setState(() => _fontFamily = value);
  }

  bool? _readerMode;

  bool get readerMode => _readerMode!;

  set readerMode(bool value) {
    _prefs.readerMode = value;
    setState(() => _readerMode = value);
  }

  String? get queryString;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fontFamily ??= _parent.fontFamily;
    _readerMode ??= _parent.readerMode;
    _textScale ??= _parent.textScale;
  }

  TextStyle get textStyle =>
      loadFontWithVariants(fontFamily).copyWith(fontSize: 18 * textScale);

  Widget buildWithViewSettings({required WidgetBuilder builder}) {
    return ViewSettings(
      data: ViewSettingsData(
        textScale: textScale,
        fontFamily: fontFamily,
        queryString: queryString!,
        readerMode: readerMode,
      ),
      // Builder required to get ViewSettings into the context
      child: Builder(builder: builder),
    );
  }
}

class ViewSettings extends InheritedWidget {
  ViewSettings.defaults(
    BuildContext context, {
    required Widget child,
    Key? key,
  }) : this(
          data: ViewSettingsData.defaults(context),
          child: child,
          key: key,
        );

  const ViewSettings({
    required Widget child,
    required this.data,
    Key? key,
  }) : super(child: child, key: key);

  final ViewSettingsData data;
  @override
  bool updateShouldNotify(ViewSettings oldWidget) => data != oldWidget.data;

  static ViewSettingsData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewSettings>()?.data ??
      ViewSettingsData.defaults(context);
}

class ViewSettingsData {
  factory ViewSettingsData.defaults(BuildContext context) {
    final prefs = Preferences.of(context);
    return ViewSettingsData(
      textScale: prefs.textScale ?? MediaQuery.textScaleFactorOf(context),
      fontFamily: prefs.fontFamily ?? kDefaultFontFamily,
      queryString: kDefaultQueryString,
      readerMode: prefs.readerMode ?? kDefaultReaderMode,
    );
  }

  const ViewSettingsData({
    required this.textScale,
    required this.fontFamily,
    required this.queryString,
    required this.readerMode,
  });

  final double textScale;
  final String fontFamily;
  final String? queryString;
  final bool readerMode;

  @override
  bool operator ==(Object other) =>
      other is ViewSettingsData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      queryString == other.queryString &&
      readerMode == other.readerMode;

  @override
  int get hashCode =>
      hashValues(textScale, fontFamily, queryString, readerMode);
}
