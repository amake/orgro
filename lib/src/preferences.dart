import 'package:flutter/widgets.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RemoteImagesPolicy { allow, deny, ask }
enum LocalLinksPolicy { deny, ask }

const kDefaultFontFamily = 'Fira Code';
// Default text scale is from system:
// MediaQuery.textScaleFactorOf(context);
const String? kDefaultQueryString = null;
const kDefaultReaderMode = false;
const kDefaultRemoteImagesPolicy = RemoteImagesPolicy.ask;
const kDefaultLocalLinksPolicy = LocalLinksPolicy.ask;

const kMaxRecentFiles = 10;

const _kFontFamilyKey = 'font_family';
const _kTextScaleKey = 'text_scale';
const _kReaderModeKey = 'reader_mode';
const _kRemoteImagesPolicyKey = 'remote_images_policy';
const _kLocalLinksPolicyKey = 'local_links_policy';
const _kRecentFilesJsonKey = 'recent_files_json';
const _kAccessibleDirectoriesKey = 'accessible_directories_json';

const _kThemeModeKey = 'theme_mode';

class Preferences extends InheritedWidget {
  static Preferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Preferences>()!;

  const Preferences(this._prefs, {required Widget child, Key? key})
      : super(child: child, key: key);

  final SharedPreferences _prefs;

  Future<void> reload() => _prefs.reload();

  String? get fontFamily => _prefs.getString(_kFontFamilyKey);

  Future<bool> setFontFamily(String? value) =>
      _setOrRemove(_kFontFamilyKey, value);

  double? get textScale => _prefs.getDouble(_kTextScaleKey);

  Future<bool> setTextScale(double? value) =>
      _setOrRemove(_kTextScaleKey, value);

  bool? get readerMode => _prefs.getBool(_kReaderModeKey);

  // ignore: avoid_positional_boolean_parameters
  Future<bool> setReaderMode(bool? value) =>
      _setOrRemove(_kReaderModeKey, value);

  List<String> get recentFilesJson =>
      _prefs.getStringList(_kRecentFilesJsonKey) ?? [];

  Future<bool> setRecentFilesJson(List<String> value) =>
      _prefs.setStringList(_kRecentFilesJsonKey, value);

  String? get themeMode => _prefs.getString(_kThemeModeKey);

  Future<bool> setThemeMode(String? value) =>
      _setOrRemove(_kThemeModeKey, value);

  RemoteImagesPolicy? get remoteImagesPolicy =>
      remoteImagesPolicyFromString(_prefs.getString(_kRemoteImagesPolicyKey));

  Future<bool> setRemoteImagesPolicy(RemoteImagesPolicy? value) =>
      _setOrRemove(_kRemoteImagesPolicyKey, remoteImagesPolicyToString(value));

  LocalLinksPolicy? get localLinksPolicy =>
      localLinksPolicyFromString(_prefs.getString(_kLocalLinksPolicyKey));

  Future<bool> setLocalLinksPolicy(LocalLinksPolicy? value) =>
      _setOrRemove(_kLocalLinksPolicyKey, localLinksPolicyToString(value));

  /// Pairs of [URI, Identifier] splatted into a flat list
  List<String> get accessibleDirs =>
      _prefs.getStringList(_kAccessibleDirectoriesKey) ?? [];

  Future<bool> setAccessibleDirs(List<String> value) =>
      _prefs.setStringList(_kAccessibleDirectoriesKey, value);

  @override
  bool updateShouldNotify(Preferences oldWidget) => _prefs != oldWidget._prefs;

  Future<bool> _setOrRemove<T>(String key, T? value) {
    if (value == null) {
      return _prefs.remove(key);
    } else if (value is String) {
      return _prefs.setString(key, value);
    } else if (value is bool) {
      return _prefs.setBool(key, value);
    } else if (value is double) {
      return _prefs.setDouble(key, value);
    } else {
      throw Exception('Unknown type: $T');
    }
  }
}

class PreferencesProvider extends StatelessWidget {
  const PreferencesProvider({required this.child, this.waiting, Key? key})
      : super(key: key);
  final Widget child;
  final Widget? waiting;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Preferences(snapshot.data!, child: child);
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return waiting ?? const SizedBox.shrink();
        }
      },
    );
  }
}

RemoteImagesPolicy? remoteImagesPolicyFromString(String? value) {
  switch (value) {
    case _kRemoteImagesPolicyAllow:
      return RemoteImagesPolicy.allow;
    case _kRemoteImagesPolicyDeny:
      return RemoteImagesPolicy.deny;
    case _kRemoteImagesPolicyAsk:
      return RemoteImagesPolicy.ask;
  }
  return null;
}

String? remoteImagesPolicyToString(RemoteImagesPolicy? value) {
  switch (value) {
    case RemoteImagesPolicy.allow:
      return _kRemoteImagesPolicyAllow;
    case RemoteImagesPolicy.deny:
      return _kRemoteImagesPolicyDeny;
    case RemoteImagesPolicy.ask:
      return _kRemoteImagesPolicyAsk;
    case null:
      return null;
  }
}

const _kRemoteImagesPolicyAllow = 'remote_images_policy_allow';
const _kRemoteImagesPolicyDeny = 'remote_images_policy_deny';
const _kRemoteImagesPolicyAsk = 'remote_images_policy_ask';

LocalLinksPolicy? localLinksPolicyFromString(String? value) {
  switch (value) {
    case _kLocalLinksPolicyDeny:
      return LocalLinksPolicy.deny;
    case _kLocalLinksPolicyAsk:
      return LocalLinksPolicy.ask;
  }
  return null;
}

String? localLinksPolicyToString(LocalLinksPolicy? value) {
  switch (value) {
    case LocalLinksPolicy.deny:
      return _kLocalLinksPolicyDeny;
    case LocalLinksPolicy.ask:
      return _kLocalLinksPolicyAsk;
    case null:
      return null;
  }
}

const _kLocalLinksPolicyDeny = 'remote_images_policy_deny';
const _kLocalLinksPolicyAsk = 'remote_images_policy_ask';
