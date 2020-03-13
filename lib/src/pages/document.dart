import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/navigation.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: ViewSettings(
        textScale: _textScale,
        // Builder required to get ViewSettings into the context
        child: Builder(
          builder: (context) => ListView(
            padding: const EdgeInsets.all(8),
            children: <Widget>[
              OrgRootWidget(
                child: widget.child,
                style: GoogleFonts.firaMono(fontSize: 18 * _textScale),
                onLinkTap: (url) {
                  debugPrint('Launching URL: $url');
                  return launch(url, forceSafariVC: false);
                },
                onSectionLongPress: (section) =>
                    narrow(context, widget.title, section),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ViewSettings extends InheritedWidget {
  const ViewSettings({
    @required Widget child,
    @required this.textScale,
    Key key,
  }) : super(child: child, key: key);

  final double textScale;

  @override
  bool updateShouldNotify(ViewSettings oldWidget) =>
      textScale != oldWidget.textScale;

  static ViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewSettings>();
}
