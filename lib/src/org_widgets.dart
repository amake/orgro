import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:org_parser/org_parser.dart';
import 'package:orgro/src/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OrgDocumentWidget extends StatelessWidget {
  const OrgDocumentWidget(this.text, {Key key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    final parser = OrgParser();
    final result = parser.parse(text);
    final topContent = result.value[0] as OrgContent;
    final sections = result.value[1] as List;
    return DefaultTextStyle.merge(
      style: orgStyle,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
  final List<GestureRecognizer> _recognizers = [];

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
          style = style.copyWith(color: orgCodeColor);
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
        style: DefaultTextStyle.of(context).style.copyWith(color: orgLinkColor),
      );
    } else if (content is OrgMeta) {
      return TextSpan(
          text: content.content,
          style:
              DefaultTextStyle.of(context).style.copyWith(color: orgMetaColor));
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
    final color = orgLevelColors[headline.level % orgLevelColors.length];
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
                            ? orgDoneColor
                            : orgTodoColor)),
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
