import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_parser/org_parser.dart';
import 'package:url_launcher/url_launcher.dart';

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
        child: Org(_content),
      ),
    );
  }
}

class Org extends StatelessWidget {
  const Org(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    final parser = OrgParser();
    final result = parser.parse(text);
    final topContent = result.value[0] as OrgContent;
    final sections = result.value[1] as List;
    return DefaultTextStyle.merge(
      style: _orgStyle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (topContent != null) OrgContentWidget(topContent),
          ...sections.map((section) => OrgSectionWidget(section as OrgSection)),
        ],
      ),
    );
  }
}

class OrgSectionWidget extends StatefulWidget {
  const OrgSectionWidget(this.section, {Key key}) : super(key: key);
  final OrgSection section;

  @override
  _OrgSectionWidgetState createState() => _OrgSectionWidgetState();
}

class _OrgSectionWidgetState extends State<OrgSectionWidget> {
  bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.section.level == 1;
  }

  void _toggle() => setState(() {
        _open = !_open;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          child: OrgHeadlineWidget(widget.section.headline),
          onTap: _toggle,
        ),
        if (_open) ...[
          if (widget.section.content != null)
            OrgContentWidget(widget.section.content),
          ...widget.section.children.map((child) => OrgSectionWidget(child)),
        ]
      ],
    );
  }
}

class OrgContentWidget extends StatefulWidget {
  const OrgContentWidget(this.content, {Key key}) : super(key: key);
  final OrgContent content;

  @override
  _OrgContentWidgetState createState() => _OrgContentWidgetState();
}

class _OrgContentWidgetState extends State<OrgContentWidget> {
  List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final item in _recognizers) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(_textTree(widget.content));
  }

  InlineSpan _textTree(OrgContent content) {
    if (content is OrgPlainText) {
      return TextSpan(text: content.content);
    } else if (content is OrgMarkup) {
      var style = DefaultTextStyle.of(context).style;
      switch (content.style) {
        case OrgStyle.bold:
          style = style.copyWith(fontWeight: FontWeight.bold);
          break;
        case OrgStyle.verbatim: // fallthrough
        case OrgStyle.code:
          style = style.copyWith(color: _orgCodeColor);
          break;
        case OrgStyle.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case OrgStyle.strikeThrough:
          style = style.copyWith(decoration: TextDecoration.lineThrough);
          break;
        case OrgStyle.underline:
          style = style.copyWith(decoration: TextDecoration.underline);
          break;
      }
      return TextSpan(text: content.content, style: style);
    } else if (content is OrgLink) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launch(content.location);
      _recognizers.add(recognizer);
      return TextSpan(
        recognizer: recognizer,
        text: content.description ?? content.location,
        style:
            DefaultTextStyle.of(context).style.copyWith(color: _orgLinkColor),
      );
    } else {
      return TextSpan(children: content.children.map(_textTree).toList());
    }
  }
}

class OrgHeadlineWidget extends StatelessWidget {
  const OrgHeadlineWidget(this.headline, {Key key}) : super(key: key);
  final OrgHeadline headline;

  @override
  Widget build(BuildContext context) {
    final color = _orgLevelColors[headline.level % _orgLevelColors.length];
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        height: 1.8,
      ),
      child: Builder(
        // Builder here to make modified default text style accessible
        builder: (context) => Text.rich(
          TextSpan(
            text: '${headline.stars} ',
            children: [
              if (headline.keyword != null)
                TextSpan(
                    text: '${headline.keyword} ',
                    style: DefaultTextStyle.of(context).style.copyWith(
                        color: headline.keyword == 'DONE'
                            ? _orgDoneColor
                            : _orgTodoColor)),
              if (headline.priority != null)
                TextSpan(text: '${headline.priority} '),
              if (headline.title != null) TextSpan(text: headline.title),
              if (headline.tags.isNotEmpty)
                TextSpan(text: ':${headline.tags.join(':')}:'),
            ],
          ),
        ),
      ),
    );
  }
}

const _orgLevelColors = [
  Color(0xff0000ff),
  Color(0xffa0522d),
  Color(0xffa020f0),
  Color(0xffb22222),
  Color(0xff228b22),
  Color(0xff008b8b),
  Color(0xff483d8b),
  Color(0xff8b2252),
];
const _orgTodoColor = Color(0xffff0000);
const _orgDoneColor = Color(0xff228b22);
const _orgCodeColor = Color(0xff7f7f7f);
const _orgLinkColor = Color(0xff3a5fcd);
final _orgStyle = GoogleFonts.firaMono(fontSize: 18);
