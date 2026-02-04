import 'package:flutter/material.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/capture.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/routes/narrow.dart';
import 'package:orgro/src/routes/settings.dart';
import 'package:orgro/src/util.dart';

const kRestoreRouteKey = 'restore_route_key';

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

  debugPrint(
    'Received URI with scheme="${uri.scheme}", '
    'host="${uri.host}", path="${uri.path}", query="${uri.query}"',
  );

  if (kOrgProtocolSchemes.contains(uri.scheme)) {
    // This may not ever actually happen
    debugPrint('Suppressing org-protocol URI: $uri');
    return null;
  }

  // Opening a file via "Open with..." on Android will traverse this code path
  // with a content: URL
  if (!_allowedHosts.contains(uri.host)) return null;

  // org-protocol URLs on Android pass through here for some reason. We
  // shouldn't be going to '/' because it should always be present at the root
  // of the navigation stack.
  if (uri.path == '/') return null;

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

  return null;
}
