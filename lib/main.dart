import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgro',
      theme: ThemeData.localize(ThemeData.light(), Typography.englishLike2018),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const platform = MethodChannel('org.madlonkay.orgro/openFile');

class _MyHomePageState extends State<MyHomePage> {
  String _content = 'Nothing Loaded';

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(handler);
  }

  Future<dynamic> handler(MethodCall call) async {
    switch (call.method) {
      case 'loadString':
        // ignore: avoid_as
        final content = call.arguments as String;
        setState(() {
          _content = content;
        });
        break;
    }
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orgro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Text(
            _content,
            style: GoogleFonts.firaMono(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
