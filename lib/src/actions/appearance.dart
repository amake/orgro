import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/preferences.dart';

PopupMenuItem<VoidCallback> appearanceMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: () async {
      final prefs = Preferences.of(context, PrefsAspect.appearance);
      final newMode = await _chooseThemeMode(context, prefs.themeMode);
      if (newMode != null) {
        prefs.setThemeMode(newMode);
      }
    },
    child: Text(AppLocalizations.of(context)!.menuItemAppearance),
  );
}

class AppearanceSettingListItem extends StatelessWidget {
  const AppearanceSettingListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context, PrefsAspect.appearance);
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsItemTheme),
      subtitle: Text(prefs.themeMode.toDisplayString(context)),
      onTap: () async {
        final newMode = await _chooseThemeMode(context, prefs.themeMode);
        if (newMode != null) {
          prefs.setThemeMode(newMode);
        }
      },
    );
  }
}

Future<ThemeMode?> _chooseThemeMode(BuildContext context, ThemeMode current) =>
    showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (final mode in ThemeMode.values)
            CheckboxListTile(
              value: current == mode,
              title: Text(mode.toDisplayString(context)),
              onChanged: (_) => Navigator.pop(context, mode),
            ),
        ],
      ),
    );

extension ThemeModeDisplayString on ThemeMode {
  String toDisplayString(BuildContext context) => switch (this) {
    ThemeMode.system => AppLocalizations.of(context)!.appearanceModeAutomatic,
    ThemeMode.light => AppLocalizations.of(context)!.appearanceModeLight,
    ThemeMode.dark => AppLocalizations.of(context)!.appearanceModeDark,
  };
}
