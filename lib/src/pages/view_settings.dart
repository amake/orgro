import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orgro/src/preferences.dart';

mixin ViewSettingsState<T extends StatefulWidget> on State<T> {
  double _textScale;

  double get textScale => _textScale;

  set textScale(double value) {
    Preferences.of(context).textScale = value;
    setState(() => _textScale = value);
  }

  String _fontFamily;

  String get fontFamily => _fontFamily;

  set fontFamily(String value) {
    Preferences.of(context).fontFamily = value;
    setState(() => _fontFamily = value);
  }

  bool _readerMode;

  bool get readerMode => _readerMode;

  set readerMode(bool value) {
    Preferences.of(context).readerMode = value;
    setState(() => _readerMode = value);
  }

  double get initialTextScale;

  String get initialFontFamily;

  bool get initialReaderMode;

  String get queryString;

  @override
  void initState() {
    super.initState();
    _fontFamily = initialFontFamily ?? kDefaultFontFamily;
    _readerMode = initialReaderMode ?? kDefaultReaderMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textScale ??= initialTextScale ?? MediaQuery.textScaleFactorOf(context);
  }

  TextStyle get textStyle {
    final fontSize = 18 * _textScale;
    try {
      // Throws if font family not known
      return _loadGoogleFont(_fontFamily, fontSize: fontSize);
    } on Exception {
      return _loadGoogleFont(kDefaultFontFamily, fontSize: fontSize);
    }
  }

  TextStyle _loadGoogleFont(String fontFamily, {double fontSize}) {
    // Load actual bold and italic to avoid synthetics
    GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.bold);
    GoogleFonts.getFont(fontFamily, fontStyle: FontStyle.italic);
    return GoogleFonts.getFont(fontFamily, fontSize: fontSize);
  }

  Widget buildWithViewSettings({@required WidgetBuilder builder}) {
    return ViewSettings(
      textScale: textScale,
      fontFamily: fontFamily,
      queryString: queryString,
      readerMode: readerMode,
      // Builder required to get ViewSettings into the context
      child: Builder(builder: builder),
    );
  }
}

class ViewSettings extends InheritedWidget {
  const ViewSettings({
    @required Widget child,
    @required this.textScale,
    @required this.fontFamily,
    @required this.queryString,
    @required this.readerMode,
    Key key,
  })  : assert(child != null),
        assert(textScale != null),
        assert(fontFamily != null),
        assert(queryString != null),
        assert(readerMode != null),
        super(child: child, key: key);

  final double textScale;
  final String fontFamily;
  final String queryString;
  final bool readerMode;

  @override
  bool updateShouldNotify(ViewSettings oldWidget) =>
      textScale != oldWidget.textScale ||
      fontFamily != oldWidget.fontFamily ||
      queryString != oldWidget.queryString ||
      readerMode != oldWidget.readerMode;

  static ViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewSettings>();
}
