import 'package:flutter/widgets.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

mixin ViewSettingsState<T extends StatefulWidget> on State<T> {
  Preferences get _prefs => Preferences.of(context);
  ViewSettingsData get _parent => ViewSettings.of(context);

  double? _textScale;

  double get textScale => _textScale!;

  set textScale(double value) {
    _prefs.setTextScale(value);
    setState(() => _textScale = value);
  }

  String? _fontFamily;

  String get fontFamily => _fontFamily!;

  set fontFamily(String value) {
    _prefs.setFontFamily(value);
    setState(() => _fontFamily = value);
  }

  bool? _readerMode;

  bool get readerMode => _readerMode!;

  set readerMode(bool value) {
    _prefs.setReaderMode(value);
    setState(() => _readerMode = value);
  }

  RemoteImagesPolicy? _remoteImagesPolicy;

  RemoteImagesPolicy get remoteImagesPolicy => _remoteImagesPolicy!;

  void setRemoteImagesPolicy(RemoteImagesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setRemoteImagesPolicy(value);
    }
    setState(() => _remoteImagesPolicy = value);
  }

  LocalLinksPolicy? _localLinksPolicy;

  LocalLinksPolicy get localLinksPolicy => _localLinksPolicy!;

  void setLocalLinksPolicy(LocalLinksPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setLocalLinksPolicy(value);
    }
    setState(() => _localLinksPolicy = value);
  }

  String? get queryString;

  /// Call this from [State.didChangeDependencies]
  void initViewSettings() {
    _fontFamily ??= _parent.fontFamily;
    _readerMode ??= _parent.readerMode;
    _textScale ??= _parent.textScale;
    _remoteImagesPolicy ??= _parent.remoteImagesPolicy;
    _localLinksPolicy ??= _parent.localLinksPolicy;
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
        remoteImagesPolicy: remoteImagesPolicy,
        localLinksPolicy: localLinksPolicy,
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
    required super.child,
    required this.data,
    super.key,
  });

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
      remoteImagesPolicy:
          prefs.remoteImagesPolicy ?? kDefaultRemoteImagesPolicy,
      localLinksPolicy: prefs.localLinksPolicy ?? kDefaultLocalLinksPolicy,
    );
  }

  const ViewSettingsData({
    required this.textScale,
    required this.fontFamily,
    required this.queryString,
    required this.readerMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
  });

  final double textScale;
  final String fontFamily;
  final String? queryString;
  final bool readerMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;

  @override
  bool operator ==(Object other) =>
      other is ViewSettingsData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      queryString == other.queryString &&
      readerMode == other.readerMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy;

  @override
  int get hashCode => hashValues(
        textScale,
        fontFamily,
        queryString,
        readerMode,
        remoteImagesPolicy,
        localLinksPolicy,
      );
}
