import 'package:flutter/material.dart';
import 'package:orgro/src/appearance.dart';

PopupMenuItem<VoidCallback> appearanceMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    child: const Text('Appearance…'),
    value: () async {
      final appearance = Appearance.of(context);
      final newMode = await _chooseThemeMode(context, appearance.mode);
      if (newMode != null) {
        appearance.setMode(newMode);
      }
    },
  );
}

Future<ThemeMode> _chooseThemeMode(BuildContext context, ThemeMode current) =>
    showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (final mode in ThemeMode.values)
            CheckboxListTile(
              value: current == mode,
              title: Text(themeModeToDisplayString(mode)),
              onChanged: (_) => Navigator.pop(context, mode),
            ),
        ],
      ),
    );

String themeModeToDisplayString(ThemeMode value) {
  switch (value) {
    case ThemeMode.system:
      return 'Automatic';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
  return null;
}
