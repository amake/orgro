import 'package:flutter/material.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/pages/settings.dart';
import 'package:orgro/src/routes/routes.dart';

class SettingsRoute extends MaterialPageRoute<void> {
  SettingsRoute()
    : super(
        builder: (context) =>
            ViewSettings.defaults(context, child: const SettingsPage()),
        settings: const RouteSettings(name: Routes.settings),
        fullscreenDialog: true,
      );
}
