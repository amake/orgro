import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/appearance.dart';

PopupMenuItem<VoidCallback> appearanceMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: () async {
      final appearance = Appearance.of(context);
      final newMode = await _chooseThemeMode(context, appearance.mode);
      if (newMode != null) {
        appearance.setMode(newMode);
      }
    },
    child: Text(AppLocalizations.of(context)!.menuItemAppearance),
  );
}

Future<ThemeMode?> _chooseThemeMode(BuildContext context, ThemeMode current) =>
    showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (final mode in ThemeMode.values)
            CheckboxListTile(
              value: current == mode,
              title: Text(themeModeToDisplayString(context, mode)),
              onChanged: (_) => Navigator.pop(context, mode),
            ),
        ],
      ),
    );

String themeModeToDisplayString(BuildContext context, ThemeMode value) {
  switch (value) {
    case ThemeMode.system:
      return AppLocalizations.of(context)!.appearanceModeAutomatic;
    case ThemeMode.light:
      return AppLocalizations.of(context)!.appearanceModeLight;
    case ThemeMode.dark:
      return AppLocalizations.of(context)!.appearanceModeDark;
  }
}
