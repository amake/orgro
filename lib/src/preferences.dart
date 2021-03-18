import 'package:flutter/widgets.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultFontFamily = 'Fira Code';
// Default text scale is from system:
// MediaQuery.textScaleFactorOf(context);
const String? kDefaultQueryString = null;
const kDefaultReaderMode = false;

const kMaxRecentFiles = 10;

const _kFontFamilyKey = 'font_family';
const _kTextScaleKey = 'text_scale';
const _kReaderModeKey = 'reader_mode';
const _kRecentFilesJsonKey = 'recent_files_json';

const _kThemeModeKey = 'theme_mode';

class Preferences extends InheritedWidget {
  static Preferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Preferences>()!;

  const Preferences(this._prefs, {required Widget child, Key? key})
      : super(child: child, key: key);

  final SharedPreferences _prefs;

  Future<void> reload() => _prefs.reload();

  String? get fontFamily => _prefs.getString(_kFontFamilyKey);

  set fontFamily(String? value) => _setOrRemove(_kFontFamilyKey, value);

  double? get textScale => _prefs.getDouble(_kTextScaleKey);

  set textScale(double? value) => _setOrRemove(_kTextScaleKey, value);

  bool? get readerMode => _prefs.getBool(_kReaderModeKey);

  set readerMode(bool? value) => _setOrRemove(_kReaderModeKey, value);

  List<String> get recentFilesJson =>
      _prefs.getStringList(_kRecentFilesJsonKey) ?? [];

  set recentFilesJson(List<String> value) =>
      _prefs.setStringList(_kRecentFilesJsonKey, value);

  String? get themeMode => _prefs.getString(_kThemeModeKey);

  set themeMode(String? value) => _setOrRemove(_kThemeModeKey, value);

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
