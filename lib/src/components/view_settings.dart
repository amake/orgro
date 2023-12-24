import 'package:flutter/widgets.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

class ViewSettings extends StatefulWidget {
  static InheritedViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedViewSettings>()!;

  ViewSettings.defaults(
    BuildContext context, {
    required Widget child,
    Key? key,
  }) : this(
          data: ViewSettingsData.defaults(context),
          child: child,
          key: key,
        );

  const ViewSettings({required this.data, required this.child, super.key});

  final Widget child;
  final ViewSettingsData data;

  @override
  State<ViewSettings> createState() => _ViewSettingsState();
}

class _ViewSettingsState extends State<ViewSettings> {
  late ViewSettingsData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  void _update(ViewSettingsData data) => setState(() => _data = data);

  @override
  Widget build(BuildContext context) =>
      InheritedViewSettings(_data, _update, Preferences.of(context),
          child: widget.child);
}

class InheritedViewSettings extends InheritedWidget {
  const InheritedViewSettings(
    this.data,
    this._update,
    this._prefs, {
    required super.child,
    super.key,
  });

  final ViewSettingsData data;
  final Preferences _prefs;
  final void Function(ViewSettingsData) _update;

  TextStyle get textStyle => loadFontWithVariants(fontFamily).copyWith(
        fontSize: TextScaler.linear(textScale).scale(18),
      );

  double get textScale => data.textScale;
  set textScale(double value) {
    _prefs.setTextScale(value);
    _update(data.copyWith(textScale: value));
  }

  String get fontFamily => data.fontFamily;
  set fontFamily(String value) {
    _prefs.setFontFamily(value);
    _update(data.copyWith(fontFamily: value));
  }

  String? get queryString => data.queryString;
  set queryString(String? value) => _update(data.copyWith(queryString: value));

  bool get readerMode => data.readerMode;
  set readerMode(bool value) {
    _prefs.setReaderMode(value);
    _update(data.copyWith(readerMode: value));
  }

  RemoteImagesPolicy get remoteImagesPolicy => data.remoteImagesPolicy;
  void setRemoteImagesPolicy(RemoteImagesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setRemoteImagesPolicy(value);
    }
    _update(data.copyWith(remoteImagesPolicy: value));
  }

  LocalLinksPolicy get localLinksPolicy => data.localLinksPolicy;
  void setLocalLinksPolicy(LocalLinksPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setLocalLinksPolicy(value);
    }
    _update(data.copyWith(localLinksPolicy: value));
  }

  SaveChangesPolicy get saveChangesPolicy => data.saveChangesPolicy;
  void setSaveChangesPolicy(SaveChangesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setSaveChangesPolicy(value);
    }
    _update(data.copyWith(saveChangesPolicy: value));
  }

  DecryptPolicy get decryptPolicy => data.decryptPolicy;
  void setDecryptPolicy(DecryptPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setDecryptPolicy(value);
    }
    _update(data.copyWith(decryptPolicy: value));
  }

  bool get fullWidth => data.fullWidth;
  set fullWidth(bool value) => _update(data.copyWith(fullWidth: value));

  @override
  bool updateShouldNotify(InheritedViewSettings oldWidget) =>
      data != oldWidget.data;
}

class ViewSettingsData {
  factory ViewSettingsData.defaults(BuildContext context) {
    final prefs = Preferences.of(context);
    return ViewSettingsData(
      textScale: prefs.textScale ?? kDefaultTextScale,
      fontFamily: prefs.fontFamily ?? kDefaultFontFamily,
      queryString: kDefaultQueryString,
      readerMode: prefs.readerMode ?? kDefaultReaderMode,
      remoteImagesPolicy:
          prefs.remoteImagesPolicy ?? kDefaultRemoteImagesPolicy,
      localLinksPolicy: prefs.localLinksPolicy ?? kDefaultLocalLinksPolicy,
      saveChangesPolicy: prefs.saveChangesPolicy ?? kDefaultSaveChangesPolicy,
      decryptPolicy: prefs.decryptPolicy ?? kDefaultDecryptPolicy,
      fullWidth: prefs.fullWidth ?? kDefaultFullWidth,
    );
  }

  const ViewSettingsData({
    required this.textScale,
    required this.fontFamily,
    required this.queryString,
    required this.readerMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
    required this.saveChangesPolicy,
    required this.decryptPolicy,
    required this.fullWidth,
  });

  final double textScale;
  final String fontFamily;
  final String? queryString;
  final bool readerMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;
  final SaveChangesPolicy saveChangesPolicy;
  final DecryptPolicy decryptPolicy;
  final bool fullWidth;

  ViewSettingsData copyWith({
    double? textScale,
    String? fontFamily,
    String? queryString,
    bool? readerMode,
    RemoteImagesPolicy? remoteImagesPolicy,
    LocalLinksPolicy? localLinksPolicy,
    SaveChangesPolicy? saveChangesPolicy,
    DecryptPolicy? decryptPolicy,
    bool? fullWidth,
  }) =>
      ViewSettingsData(
        textScale: textScale ?? this.textScale,
        fontFamily: fontFamily ?? this.fontFamily,
        queryString: queryString ?? this.queryString,
        readerMode: readerMode ?? this.readerMode,
        remoteImagesPolicy: remoteImagesPolicy ?? this.remoteImagesPolicy,
        localLinksPolicy: localLinksPolicy ?? this.localLinksPolicy,
        saveChangesPolicy: saveChangesPolicy ?? this.saveChangesPolicy,
        decryptPolicy: decryptPolicy ?? this.decryptPolicy,
        fullWidth: fullWidth ?? this.fullWidth,
      );

  @override
  bool operator ==(Object other) =>
      other is ViewSettingsData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      queryString == other.queryString &&
      readerMode == other.readerMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy &&
      saveChangesPolicy == other.saveChangesPolicy &&
      decryptPolicy == other.decryptPolicy &&
      fullWidth == other.fullWidth;

  @override
  int get hashCode => Object.hash(
        textScale,
        fontFamily,
        queryString,
        readerMode,
        remoteImagesPolicy,
        localLinksPolicy,
        saveChangesPolicy,
        decryptPolicy,
        fullWidth,
      );
}
