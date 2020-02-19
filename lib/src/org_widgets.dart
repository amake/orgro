import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

class OrgSectionWidget extends StatelessWidget {
  const OrgSectionWidget(this.section, {Key key}) : super(key: key);
  final OrgSection section;

  @override
  Widget build(BuildContext context) {
    final open = ValueNotifier<bool>(section.level == 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          child: OrgHeadlineWidget(section.headline),
          onTap: () => open.value = !open.value,
        ),
        AnimatedShowHide(
          open,
          shownChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (section.content != null) OrgContentWidget(section.content),
              ...section.children.map((child) => OrgSectionWidget(child)),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedShowHide extends StatelessWidget {
  const AnimatedShowHide(
    this.visible, {
    @required this.shownChild,
    this.hiddenChild = const SizedBox.shrink(),
    this.duration = const Duration(milliseconds: 100),
    Key key,
  })  : assert(visible != null),
        assert(shownChild != null),
        assert(hiddenChild != null),
        assert(duration != null),
        super(key: key);

  final ValueNotifier<bool> visible;
  final Widget shownChild;
  final Widget hiddenChild;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, value, child) => AnimatedCrossFade(
        alignment: Alignment.topLeft,
        duration: duration,
        firstChild: child,
        secondChild: hiddenChild,
        crossFadeState:
            value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
      child: shownChild,
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
      return TextSpan(
        text: content.content,
        style: fontStyleForOrgStyle(
          DefaultTextStyle.of(context).style,
          content.style,
        ),
      );
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
              if (headline.title != null)
                WidgetSpan(
                  child: IdentityTextScale(
                    child: OrgContentWidget(headline.title),
                  ),
                ),
              if (headline.tags.isNotEmpty)
                TextSpan(text: ':${headline.tags.join(':')}:'),
            ],
          ),
        ),
      ),
    );
  }
}

class IdentityTextScale extends StatelessWidget {
  const IdentityTextScale({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
      child: child,
    );
  }
}
