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
  ScrollController _controller;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(handler);
    _controller = ScrollController();
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
    _controller.dispose();
    super.dispose();
  }

  void _scrollTo(double position) => _controller.animateTo(position,
      duration: const Duration(milliseconds: 300), curve: Curves.ease);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orgro'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: () => _scrollTo(_controller.position.minScrollExtent),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => _scrollTo(_controller.position.maxScrollExtent),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _controller,
          child: Text(
            _content,
            style: GoogleFonts.firaMono(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
