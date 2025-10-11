import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/quick_actions.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

final startKey = GlobalKey<StartPageState>();

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'google_fonts',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'LineReader',
    ], await rootBundle.loadString('assets/licenses/LICENSE-LineReader.txt'));
  });

  if (kReleaseMode) {
    // Disable debug printing for release builds
    debugPrint = (_, {wrapWidth}) {};
  }

  runApp(buildApp());

  Workmanager().initialize(backgroundTaskDispatcher);

  initNotifications();

  clearTemporaryAttachments();
}

Widget buildApp({bool isTest = false}) => Preferences(
  isTest: isTest,
  child: RememberedFiles(child: const _MyApp()),
);

// Not the "real" splash screen; just something to cover the blank while waiting
// for Preferences to load
class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: orgroPrimaryColor,
    );
  }
}

class _MyApp extends StatelessWidget {
  const _MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'orgro_root',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: !kScreenshotMode,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: orgroLightTheme,
      darkTheme: orgroDarkTheme,
      themeMode: Preferences.of(context, PrefsAspect.appearance).themeMode,
      home: QuickActions(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Preferences.of(context, PrefsAspect.init).isInitialized
              ? StartPage(key: startKey)
              : const _Splash(),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      onGenerateRoute: onGenerateRoute,
    );
  }
}

@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case kAgendaUpdateTask:
        // Custom task to update agenda notifications
        await _handleBackgroundFetch();
        break;
      case Workmanager.iOSBackgroundTask:
        // iOS Background Fetch task
        await _handleBackgroundFetch();
        break;
      default:
        debugPrint('Unknown background task: $task');
    }

    return Future.value(true);
  });
}

Future<void> _handleBackgroundFetch() async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await PreferencesData.fromSharedPreferences(
    SharedPreferencesAsync(),
  );
  // TODO(aaron): Update agenda also on launch because background tasks are
  // rarely run?
  await setNotificationsForAllAgendaDocuments(prefs.agendaFileJsons);
}
