import 'package:flutter/material.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/capture.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/routes/narrow.dart';
import 'package:orgro/src/routes/settings.dart';
import 'package:orgro/src/util.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// This does an end-run around _WidgetsAppState.didPushRouteInformation which
// strips the host off of incoming deep links.
class _DeepLinkInterceptor extends WidgetsBindingObserver {
  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    debugPrint(
      'Received route information: ${routeInformation.uri}; '
      '${routeInformation.state}',
    );
    navigatorKey.currentState!.pushNamed(routeInformation.uri.toString());
    return true;
  }
}

/// Call this before [runApp]. Make sure the [navigatorKey] is passed to the
/// [MaterialApp].
void initDeepLinks() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(_DeepLinkInterceptor());
}

const kRestoreRouteKey = 'restore_route_key';

class Routes {
  const Routes._();

  static const document = '/document';
  static const settings = '/settings';
  static const manual = '/manual';
  static const narrow = '/narrow';
}

// Calling [Navigator.pushNamed] gives a [RouteSettings] with an empty host
const _internalHost = '';
const _mainHosts = {'orgro.org', 'debug.orgro.org', 'profile.orgro.org'};
const _socialFeedHosts = {
  'social.orgro.org',
  'social-debug.orgro.org',
  'social-profile.orgro.org',
};

const _allowedHosts = {_internalHost, ..._mainHosts, ..._socialFeedHosts};

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

  if (uri.host == _internalHost || _mainHosts.contains(uri.host)) {
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
  } else if (_socialFeedHosts.contains(uri.host)) {
    // TODO(aaron): Handle Org Social fragment that points to a specific post.
    // The problem is that we don't know if we should do the lookup by section
    // title or by ID.
    return DocumentRoute(dataSource: WebDataSource(uri));
  }

  return null;
}
