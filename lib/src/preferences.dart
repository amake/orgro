import 'package:shared_preferences/shared_preferences.dart';

const kDefaultFontFamily = 'Fira Code';
// Default text scale is from system:
// MediaQuery.textScaleFactorOf(context);
const kDefaultReaderMode = false;

const _kFontFamilyKey = 'font_family';
const _kTextScaleKey = 'text_scale';
const _kReaderModeKey = 'reader_mode';

class Preferences {
  static Future<Preferences> getInstance() async =>
      Preferences._(await SharedPreferences.getInstance());

  Preferences._(this._prefs);

  final SharedPreferences _prefs;

  String get fontFamily => _prefs.getString(_kFontFamilyKey);

  set fontFamily(String value) => _prefs.setString(_kFontFamilyKey, value);

  double get textScale => _prefs.getDouble(_kTextScaleKey);

  set textScale(double value) => _prefs.setDouble(_kTextScaleKey, value);

  bool get readerMode => _prefs.getBool(_kReaderModeKey);

  set readerMode(bool value) => _prefs.setBool(_kReaderModeKey, value);
}
