import 'package:flutter/material.dart';
import 'package:orgro/src/pages/pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'orgro',
      theme: ThemeData.localize(
          ThemeData(
            primaryColor: Colors.teal,
            accentColor: Colors.deepOrangeAccent,
          ),
          Typography.englishLike2018),
      darkTheme:
          ThemeData.localize(ThemeData.dark(), Typography.englishLike2018),
      home: const StartPage(),
    );
  }
}
