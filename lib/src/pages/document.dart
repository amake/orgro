import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/view_settings.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentPage extends StatefulWidget {
  DocumentPage.defaults(
    ViewSettings settings, {
    @required String title,
    @required Widget child,
    Key key,
  }) : this(
          title: title,
          child: child,
          textScale: settings.textScale,
          fontFamily: settings.fontFamily,
          initialQuery: settings.queryString,
          readerMode: settings.readerMode,
          key: key,
        );

  const DocumentPage({
    @required this.title,
    @required this.child,
    this.textScale,
    this.fontFamily,
    this.initialQuery,
    this.readerMode,
    Key key,
  })  : assert(child != null),
        super(key: key);

  final String title;
  final Widget child;
  final double textScale;
  final String fontFamily;
  final String initialQuery;
  final bool readerMode;

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with ViewSettingsState {
  MySearchDelegate _searchDelegate;

  @override
  String get initialFontFamily => widget.fontFamily;

  @override
  bool get initialReaderMode => widget.readerMode;

  @override
  double get initialTextScale => widget.textScale;

  @override
  String get queryString => _searchDelegate.queryString;

  @override
  void initState() {
    super.initState();
    _searchDelegate = MySearchDelegate(
      onQueryChanged: (query) {
        if (query.length > 3) {
          _doQuery(query);
        }
      },
      onQuerySubmitted: _doQuery,
      initialQuery: widget.initialQuery,
    );
  }

  void _doQuery(String query) {
    final pattern = RegExp(
      RegExp.escape(query),
      unicode: true,
      caseSensitive: false,
    );
    OrgController.of(context).search(pattern);
  }

  @override
  void dispose() {
    _searchDelegate.dispose();
    super.dispose();
  }

  Widget _title(bool searchMode) {
    if (searchMode) {
      return _searchDelegate.buildSearchField();
    } else if (widget.title != null) {
      return Text(
        widget.title,
        overflow: TextOverflow.fade,
      );
    } else {
      return const Text('Orgro');
    }
  }

  Iterable<Widget> _actions(bool searchMode) sync* {
    if (!searchMode) {
      yield SearchButton(
        hasQuery: _searchDelegate.hasQuery,
        onPressed: () => _searchDelegate.start(context),
      );
    }
    if (!searchMode || MediaQuery.of(context).size.width > 500) {
      yield TextStyleButton(
        textScale: textScale,
        onTextScaleChanged: (value) => textScale = value,
        fontFamily: fontFamily,
        onFontFamilyChanged: (value) => fontFamily = value,
      );
      if (MediaQuery.of(context).size.width > 600) {
        yield IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: OrgController.of(context).cycleVisibility,
        );
        yield ReaderModeButton(
          enabled: readerMode,
          onToggled: _toggleReaderMode,
        );
        yield const ScrollTopButton();
        yield const ScrollBottomButton();
      } else {
        yield PopupMenuButton<VoidCallback>(
          onSelected: (callback) => callback(),
          itemBuilder: (context) => [
            readerModeMenuItem(context, _toggleReaderMode),
            const PopupMenuDivider(),
            PopupMenuItem<VoidCallback>(
              child: const Text('Cycle visibility'),
              value: OrgController.of(context).cycleVisibility,
            ),
            scrollBottomMenuItem(context),
            scrollTopMenuItem(context),
          ],
        );
      }
    }
  }

  void _toggleReaderMode() {
    final value = !readerMode;
    readerMode = OrgController.of(context).hideMarkup.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchDelegate.searchMode,
      builder: (context, searchMode, child) => Scaffold(
        appBar: AppBar(
          title: _title(searchMode),
          actions: _actions(searchMode).toList(growable: false),
        ),
        body: child,
      ),
      child: buildWithViewSettings(
        builder: (context) => OrgRootWidget(
          child: widget.child,
          style: textStyle,
          onLinkTap: (url) {
            debugPrint('Launching URL: $url');
            return launch(url, forceSafariVC: false);
          },
          onSectionLongPress: (section) =>
              narrow(context, widget.title, section),
          onLocalSectionLinkTap: (section) =>
              narrow(context, widget.title, section),
        ),
      ),
    );
  }
}
