import 'package:flutter/material.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/routes/narrow.dart';
import 'package:orgro/src/routes/settings.dart';
import 'package:orgro/src/util.dart';
import 'package:url_launcher/url_launcher.dart';

class Routes {
  const Routes._();

  static const document = '/document';
  static const settings = '/settings';
  static const manual = '/manual';
  static const narrow = '/narrow';
}

const _allowedHosts = {'', 'debug.orgro.org', 'profile.orgro.org', 'orgro.org'};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  debugPrint('onGenerateRoute: ${settings.name}; ${settings.arguments}');
  if (settings.name == null) return null;

  final uri = Uri.tryParse(settings.name!);
  if (uri == null) return null;
  // Opening a file via "Open with..." on Android will traverse this code path
  // with a content: URL
  if (!_allowedHosts.contains(uri.host)) return null;

  switch (uri.path.trimSuff('/')) {
    case Routes.document:
      return DocumentRoute.fromSettings(settings);
    case Routes.narrow:
      return NarrowRoute.fromSettings(settings);
    case Routes.manual:
      return DocumentRoute(dataSource: AssetDataSource(LocalAssets.manual));
    case Routes.settings:
      return SettingsRoute();
  }

  // We shouldn't be receiving any unknown paths here, but if the deep link
  // settings change out from under us then it's possible. In that case we
  // should kick back to the browser.
  final externalUri = Uri.https('orgro.org', uri.path);
  launchUrl(externalUri, mode: LaunchMode.externalApplication).onError((e, s) {
    debugPrint('Error launching "$externalUri": $e');
    return false;
  });

  return null;
}
