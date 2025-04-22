import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/theme.dart';

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

  clearTemporaryAttachments();
}

Widget buildApp() =>
    const SharedPreferencesProvider(waiting: _Splash(), child: _MyApp());

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

class _MyApp extends StatefulWidget {
  const _MyApp();

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  @override
  Widget build(BuildContext context) => MaterialApp(
    restorationScopeId: 'orgro_root',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: !kScreenshotMode,
    onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
    theme: orgroLightTheme,
    darkTheme: orgroDarkTheme,
    themeMode: Preferences.of(context, PrefsAspect.appearance).themeMode,
    // We don't make the home a named route because then for some reason it
    // doesn't get set up with RestorationScope
    home: const StartPage(),
    onGenerateRoute: onGenerateRoute,
  );
}
