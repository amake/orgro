import 'package:flutter/material.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';

void main() => runApp(MyApp());

// https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=006058&secondary.color=ff6e40
const _kPrimaryColor = Color(0xff006058);
const _kPrimaryColorVariant = Color(0xff00352f);
const _kSecondaryColor = Colors.deepOrangeAccent;
final _kSecondaryColorVariant = Colors.deepOrangeAccent.shade700;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: !kScreenshotMode,
      title: 'orgro',
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
