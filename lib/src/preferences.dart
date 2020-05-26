import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultFontFamily = 'Fira Code';
// Default text scale is from system:
// MediaQuery.textScaleFactorOf(context);
const kDefaultReaderMode = false;

const _kMaxRecentFiles = 10;

const _kFontFamilyKey = 'font_family';
const _kTextScaleKey = 'text_scale';
const _kReaderModeKey = 'reader_mode';
const _kRecentFileIdsKey = 'recent_file_ids';
const _kRecentFileNamesKey = 'recent_file_names';

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

  List<RecentFile> get recentFiles {
    final ids = _prefs.getStringList(_kRecentFileIdsKey) ?? [];
    final names = _prefs.getStringList(_kRecentFileNamesKey) ?? [];
    if (ids.length != names.length) {
      return const [];
    }
    final recents = <RecentFile>[];
    for (var i = 0; i < ids.length; i++) {
      recents.add(RecentFile(ids[i], names[i]));
    }
    return recents;
  }

  Future<bool> addRecentFile(String identifier, String name) async {
    final ids = (_prefs.getStringList(_kRecentFileIdsKey) ?? [])
      ..insert(0, identifier);
    final trimmedIds = ids.sublist(0, min(ids.length, _kMaxRecentFiles));
    final names = (_prefs.getStringList(_kRecentFileNamesKey) ?? [])
      ..insert(0, name);
    final trimmedNames = names.sublist(0, min(names.length, _kMaxRecentFiles));
    final setIds = _prefs.setStringList(_kRecentFileIdsKey, trimmedIds);
    final setNames = _prefs.setStringList(_kRecentFileNamesKey, trimmedNames);
    return await setIds && await setNames;
  }

  static Preferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedPreferences>().prefs;
}

class RecentFile {
  RecentFile(this.identifier, this.name)
      : assert(identifier != null),
        assert(name != null);
  final String identifier;
  final String name;
}

class PreferencesProvider extends StatelessWidget {
  const PreferencesProvider({@required this.child, Key key})
      : assert(child != null),
        super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Preferences>(
      future: Preferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return InheritedPreferences(snapshot.data, child: child);
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class InheritedPreferences extends InheritedWidget {
  const InheritedPreferences(this.prefs, {Widget child, Key key})
      : assert(prefs != null),
        super(child: child, key: key);

  final Preferences prefs;

  @override
  bool updateShouldNotify(InheritedPreferences oldWidget) =>
      prefs != oldWidget.prefs;
}
