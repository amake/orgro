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

// For some reason on Android the main domain is passed as an empty string
const _mainDomains = {'', 'orgro.org', 'debug.orgro.org', 'profile.orgro.org'};
const _socialFeedDomains = {
  'social.orgro.org',
  'social-debug.orgro.org',
  'social-profile.orgro.org',
};

const _allowedHosts = {..._mainDomains, ..._socialFeedDomains};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  debugPrint('onGenerateRoute: ${settings.name}; ${settings.arguments}');
  if (settings.name == null) return null;

  final uri = Uri.tryParse(settings.name!);
  if (uri == null) return null;

  debugPrint(
    'Received URI with scheme="${uri.scheme}", '
    'host="${uri.host}", path="${uri.path}", query="${uri.query}"',
  );

  if (isCaptureUri(uri)) {
    // This may not ever actually happen
    debugPrint('Suppressing org-protocol URI: $uri');
    return null;
  }

  // Opening a file via "Open with..." on Android will traverse this code path
  // with a content: URL
  if (!_allowedHosts.contains(uri.host)) return null;

  if (_mainDomains.contains(uri.host)) {
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
  } else if (_socialFeedDomains.contains(uri.host)) {
    // TODO(aaron): Handle Org Social fragment that points to a specific post.
    // The problem is that we don't know if we should do the lookup by section
    // title or by ID.
    return DocumentRoute(dataSource: WebDataSource(uri));
  }

  return null;
}
