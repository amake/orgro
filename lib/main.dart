import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  runApp(const PreferencesProvider(child: MyApp()));
}

// https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=006058&secondary.color=ff6e40
const _kPrimaryColor = Color(0xff006058);
const _kPrimaryColorVariant = Color(0xff00352f);
const _kSecondaryColor = Colors.deepOrangeAccent;
final _kSecondaryColorVariant = Colors.deepOrangeAccent.shade700;

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: !kScreenshotMode,
      title: 'Orgro',
      theme: ThemeData.from(
        colorScheme: ColorScheme.light(
          primary: _kPrimaryColor,
          primaryVariant: _kPrimaryColorVariant,
          secondary: _kSecondaryColor,
          secondaryVariant: _kSecondaryColorVariant,
        ),
        textTheme: Typography.englishLike2018,
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.dark(
          primary: _kPrimaryColor,
          primaryVariant: _kPrimaryColorVariant,
          secondary: _kSecondaryColor,
          secondaryVariant: _kSecondaryColorVariant,
        ),
        textTheme: Typography.englishLike2018,
      ),
      home: const StartPage(),
    );
  }
}
