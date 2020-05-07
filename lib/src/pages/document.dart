import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/navigation.dart';
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
          initialQuery: settings.queryString,
          readerMode: settings.readerMode,
          key: key,
        );

  const DocumentPage({
    @required this.title,
    @required this.child,
    this.textScale,
    this.initialQuery,
    this.readerMode,
    Key key,
  })  : assert(child != null),
        super(key: key);

  final String title;
  final Widget child;
  final double textScale;
  final String initialQuery;
  final bool readerMode;

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  double _textScale;
  MySearchDelegate _searchDelegate;
  bool _readerMode;

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
    _readerMode = widget.readerMode ?? false;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textScale ??= widget.textScale ?? MediaQuery.textScaleFactorOf(context);
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
      return Text(widget.title);
    } else {
      return const Text('orgro');
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
      yield TextSizeButton(
        value: _textScale,
        onChanged: (value) => setState(() => _textScale = value),
      );
      if (MediaQuery.of(context).size.width > 600) {
        yield IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: OrgController.of(context).cycleVisibility,
        );
        yield ReaderModeButton(
          enabled: _readerMode,
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
    setState(() {
      _readerMode = !_readerMode;
      OrgController.of(context).hideMarkup.value = _readerMode;
    });
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
      child: ViewSettings(
        textScale: _textScale,
        queryString: _searchDelegate.queryString,
        readerMode: _readerMode,
        // Builder required to get ViewSettings into the context
        child: Builder(
          builder: (context) {
            return OrgRootWidget(
              child: widget.child,
              style: GoogleFonts.firaMono(fontSize: 18 * _textScale),
              onLinkTap: (url) {
                debugPrint('Launching URL: $url');
                return launch(url, forceSafariVC: false);
              },
              onSectionLongPress: (section) =>
                  narrow(context, widget.title, section),
              onLocalSectionLinkTap: (section) =>
                  narrow(context, widget.title, section),
            );
          },
        ),
      ),
    );
  }
}

class ViewSettings extends InheritedWidget {
  const ViewSettings({
    @required Widget child,
    @required this.textScale,
    @required this.queryString,
    @required this.readerMode,
    Key key,
  })  : assert(child != null),
        assert(textScale != null),
        assert(queryString != null),
        assert(readerMode != null),
        super(child: child, key: key);

  final double textScale;
  final String queryString;
  final bool readerMode;

  @override
  bool updateShouldNotify(ViewSettings oldWidget) =>
      textScale != oldWidget.textScale ||
      queryString != oldWidget.queryString ||
      readerMode != oldWidget.readerMode;

  static ViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewSettings>();
}
