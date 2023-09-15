import 'package:flutter/material.dart';
import 'package:orgro/src/preferences.dart';

class Appearance extends InheritedWidget {
  const Appearance({
    required this.mode,
    required this.setMode,
    required super.child,
    super.key,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> setMode;

  @override
  bool updateShouldNotify(Appearance oldWidget) => mode != oldWidget.mode;

  static Appearance of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Appearance>()!;
}

mixin AppearanceState<T extends StatefulWidget> on State<T> {
  Preferences get _prefs => Preferences.of(context);
  late ThemeMode _mode;

  void _load() {
    _mode =
        ThemeModePersistence.fromString(_prefs.themeMode) ?? _kDefaultThemeMode;
  }

  void setMode(ThemeMode mode) {
    setState(() {
      _mode = mode;
    });
    _prefs.setThemeMode(mode.persistableString);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Doing this here instead of [initState] because we need to pull in an
    // InheritedWidget
    _load();
  }

  Widget buildWithAppearance({required WidgetBuilder builder}) {
    return Appearance(
      mode: _mode,
      setMode: setMode,
      child: Builder(builder: builder),
    );
  }
}

extension ThemeModePersistence on ThemeMode? {
  String? get persistableString => switch (this) {
        ThemeMode.system => _kThemeModeSystem,
        ThemeMode.light => _kThemeModeLight,
        ThemeMode.dark => _kThemeModeDark,
        null => null
      };

  static ThemeMode? fromString(String? value) {
    switch (value) {
      case _kThemeModeSystem:
        return ThemeMode.system;
      case _kThemeModeLight:
        return ThemeMode.light;
      case _kThemeModeDark:
        return ThemeMode.dark;
    }
    return null;
  }
}

const _kThemeModeSystem = 'theme_mode_system';
const _kThemeModeLight = 'theme_mode_light';
const _kThemeModeDark = 'theme_mode_dark';

const _kDefaultThemeMode = ThemeMode.system;
