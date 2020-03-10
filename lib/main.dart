import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/platform.dart';
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

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    @required this.title,
    @required this.child,
    this.textScale,
    Key key,
  })  : assert(child != null),
        super(key: key);

  final String title;
  final Widget child;
  final double textScale;

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  double _textScale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textScale ??= widget.textScale ?? MediaQuery.textScaleFactorOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title == null ? const Text('Orgro') : Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.repeat),
            onPressed: OrgController.of(context).cycleVisibility,
          ),
          TextSizeButton(
            value: _textScale,
            onChanged: (value) => setState(() => _textScale = value),
          ),
          const ScrollTopButton(),
          const ScrollBottomButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: _textScale),
            // Builder required to get modified textScaleFactor into the context
            child: Builder(
              builder: (context) => OrgRootWidget(
                child: widget.child,
                style: GoogleFonts.firaMono(fontSize: 18),
                onLinkTap: (url) => launch(url, forceSafariVC: false),
                onSectionLongPress: (section) =>
                    narrow(context, widget.title, section),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({this.error, Key key}) : super(key: key);

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error),
              const SizedBox(height: 16),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
