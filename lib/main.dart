import 'package:flutter/material.dart';
import 'package:orgro/src/pages/pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'orgro',
      theme: ThemeData.from(
        colorScheme: ColorScheme.light(
          primary: Colors.teal,
          primaryVariant: Colors.teal.shade700,
          secondary: Colors.deepOrangeAccent,
          secondaryVariant: Colors.deepOrangeAccent.shade700,
        ),
        textTheme: Typography.englishLike2018,
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          primaryVariant: Colors.teal.shade700,
          secondary: Colors.deepOrangeAccent,
          secondaryVariant: Colors.deepOrangeAccent.shade700,
        ),
        textTheme: Typography.englishLike2018,
      ),
      home: const StartPage(),
    );
  }
}
