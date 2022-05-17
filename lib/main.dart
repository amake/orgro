import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/appearance.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  if (kReleaseMode) {
    // Disable debug printing for release builds
    debugPrint = (_, {wrapWidth}) {};
  }

  runApp(buildApp());
}

Widget buildApp() => const PreferencesProvider(
      waiting: _Splash(),
      child: _MyApp(),
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
      color: _kPrimaryColor,
    );
  }
}

// https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=006058&secondary.color=ff6e40
const _kPrimaryColor = Color(0xff006058);
const _kPrimaryColorVariant = Color(0xff00352f);
const _kSecondaryColor = Colors.deepOrangeAccent;
final _kSecondaryColorVariant = Colors.deepOrangeAccent.shade700;

class _MyApp extends StatefulWidget {
  const _MyApp();

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> with AppearanceState {
  @override
  Widget build(BuildContext context) {
    return buildWithAppearance(builder: (context) {
      return MaterialApp(
        restorationScopeId: 'orgro_root',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: !kScreenshotMode,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: ThemeData.from(
          colorScheme: ColorScheme.light(
            primary: _kPrimaryColor,
            primaryContainer: _kPrimaryColorVariant,
            onPrimary: Colors.white,
            secondary: _kSecondaryColor,
            secondaryContainer: _kSecondaryColorVariant,
            onSecondary: Colors.white,
          ),
          textTheme: Typography.englishLike2018,
        ),
        darkTheme: ThemeData.from(
          colorScheme: ColorScheme.dark(
            primary: _kPrimaryColor,
            primaryContainer: _kPrimaryColorVariant,
            onPrimary: Colors.white,
            secondary: _kSecondaryColor,
            secondaryContainer: _kSecondaryColorVariant,
            onSecondary: Colors.white,
          ),
          textTheme: Typography.englishLike2018,
        ),
        themeMode: Appearance.of(context).mode,
        home: const StartPage(),
      );
    });
  }
}
