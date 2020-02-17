import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/org_widgets.dart';

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
  String _content;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(handler);
  }

  Future<dynamic> handler(MethodCall call) async {
    switch (call.method) {
      case 'loadString':
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

  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.minScrollExtent);
  }

  void _scrollToBottom(BuildContext context) {
    final controller = PrimaryScrollController.of(context);
    _scrollTo(controller, controller.position.maxScrollExtent);
  }

  void _scrollTo(ScrollController controller, double position) =>
      controller.animateTo(position,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orgro'),
        actions: <Widget>[
          // Builders required to get access to PrimaryScrollController
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () => _scrollToTop(context),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => _scrollToBottom(context),
            ),
          )
        ],
      ),
      body: Center(
        child: _content == null
            ? const Text('Nothing Loaded')
            : OrgDocumentWidget(_content),
      ),
    );
  }
}
