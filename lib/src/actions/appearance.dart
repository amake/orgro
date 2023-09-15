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
              title: Text(mode.toDisplayString(context)),
              onChanged: (_) => Navigator.pop(context, mode),
            ),
        ],
      ),
    );

extension ThemeModeDisplayString on ThemeMode {
  String toDisplayString(BuildContext context) => switch (this) {
        ThemeMode.system =>
          AppLocalizations.of(context)!.appearanceModeAutomatic,
        ThemeMode.light => AppLocalizations.of(context)!.appearanceModeLight,
        ThemeMode.dark => AppLocalizations.of(context)!.appearanceModeDark,
      };
}
