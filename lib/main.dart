import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgro',
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

Future<T> time<T>(String tag, FutureOr<T> Function() func) async {
  final start = DateTime.now();
  final ret = await func();
  final end = DateTime.now();
  debugPrint('$tag: ${end.difference(start).inMilliseconds} ms');
  return ret;
}

Future<bool> loadUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  return loadPath(context, uri.toFilePath());
}

Future<bool> loadPath(BuildContext context, String path) async {
  final file = File(path);
  final content = time('read file', file.readAsString);
  final title = file.uri.pathSegments.last;
  loadDocument(context, title, content);
  return content.then((_) => true);
}

void loadDocument(BuildContext context, String title, Future<String> content) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FutureBuilder<OrgDocument>(
        future: content.then(parse),
        builder: (context, snapshot) {
          final document = snapshot.data;
          return document == null
              ? const ProgressPage(title: 'Loading...')
              : DocumentPage(
                  title: title,
                  child: OrgDocumentWidget(document),
                );
        },
      ),
      fullscreenDialog: true,
    ),
  );
}

Future<OrgDocument> parse(String content) async =>
    time('parse', () => compute(_parse, content));

OrgDocument _parse(String text) {
  try {
    return OrgDocument(text);
    // ignore: avoid_catches_without_on_clauses
  } catch (e, s) {
    debugPrint(e.toString());
    debugPrint(s.toString());
    rethrow;
  }
}

void narrow(BuildContext context, String title, OrgSection section) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentPage(
        title: '$title › narrow',
        child: OrgSectionWidget(
          section,
          initiallyOpen: true,
        ),
      ),
    ),
  );
}

const platform = MethodChannel('org.madlonkay.orgro/openFile');

class PlatformOpenHandler extends StatefulWidget {
  const PlatformOpenHandler({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final Widget child;

  @override
  _PlatformOpenHandlerState createState() => _PlatformOpenHandlerState();
}

class _PlatformOpenHandlerState extends State<PlatformOpenHandler> {
  @override
  void initState() {
    super.initState();
    platform
      ..setMethodCallHandler(_handler)
      ..invokeMethod('ready');
  }

  Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case 'loadString':
        return loadDocument(
          context,
          null,
          Future.value(call.arguments as String),
        );
      case 'loadUrl':
        return loadUrl(context, call.arguments as String);
    }
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class StartPage extends StatelessWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orgro')),
      body: PlatformOpenHandler(
        child: Center(
          child: PickFileButton(onSelected: (path) => loadPath(context, path)),
        ),
      ),
    );
  }
}

class PickFileButton extends StatelessWidget {
  const PickFileButton({@required this.onSelected, Key key})
      : assert(onSelected != null),
        super(key: key);

  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open File'),
      onPressed: () async {
        final path = await FilePicker.getFilePath(type: FileType.ANY);
        if (path != null) {
          onSelected(path);
        }
      },
    );
  }
}

class DocumentPage extends StatelessWidget {
  const DocumentPage({@required this.title, @required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final String title;
  final Widget child;

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
        title: title == null ? const Text('Orgro') : Text(title),
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
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          OrgRootWidget(
            child: child,
            style: GoogleFonts.firaMono(fontSize: 18),
            onLinkTap: (url) => launch(url, forceSafariVC: false),
            onSectionLongPress: (section) => narrow(context, title, section),
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({this.title, Key key}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title == null ? null : Text(title),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
