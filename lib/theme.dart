import 'package:flutter/material.dart';

// https://material.io/resources/color/#!/?view.left=0&view.right=0&primary.color=006058&secondary.color=ff6e40
const orgroPrimaryColor = Color(0xff006058);
const _kPrimaryColorVariant = Color(0xff00352f);
const _kSecondaryColor = Colors.deepOrangeAccent;
final _kSecondaryColorVariant = Colors.deepOrangeAccent.shade700;

// TODO(aaron): Revert 13570c217d60907ff898331c259a1317e6cdbc3d when moving to
// Material 3
const _kUseMaterial3 = false;

final orgroLightTheme = ThemeData.from(
  colorScheme: ColorScheme.light(
    primary: orgroPrimaryColor,
    primaryContainer: _kPrimaryColorVariant,
    onPrimary: Colors.white,
    secondary: _kSecondaryColor,
    secondaryContainer: _kSecondaryColorVariant,
    onSecondary: Colors.white,
  ),
  useMaterial3: _kUseMaterial3,
);

final orgroDarkTheme = ThemeData.from(
  colorScheme: ColorScheme.dark(
    primary: orgroPrimaryColor,
    primaryContainer: _kPrimaryColorVariant,
    onPrimary: Colors.white,
    secondary: _kSecondaryColor,
    secondaryContainer: _kSecondaryColorVariant,
    onSecondary: Colors.white,
  ),
  useMaterial3: _kUseMaterial3,
).copyWith(
  // Very dumb workaround for our primary color (the default label
  // color for TextButton) being too dark in dark mode
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.white),
  ),
);
