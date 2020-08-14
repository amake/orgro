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

  double get _screenWidth => MediaQuery.of(context).size.width;

  // Not sure why this size
  bool get _biggishScreen => _screenWidth > 500;

  // E.g. iPad mini in portrait (768px), iPhone XS in landscape (812px), Pixel 2
  // in landscape (731px)
  bool get _bigScreen => _screenWidth > 600;

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
    // Disused in favor of Floating Action Button:
    // if (!searchMode) {
    //   yield SearchButton(
    //     hasQuery: _searchDelegate.hasQuery,
    //     onPressed: () => _searchDelegate.start(context),
    //   );
    // }
    if (!searchMode || _biggishScreen) {
      yield IconButton(
        icon: const Icon(Icons.repeat),
        onPressed: OrgController.of(context).cycleVisibility,
      );
      if (_bigScreen) {
        yield TextStyleButton(
          textScale: textScale,
          onTextScaleChanged: (value) => textScale = value,
          fontFamily: fontFamily,
          onFontFamilyChanged: (value) => fontFamily = value,
        );
        yield ReaderModeButton(
          enabled: readerMode,
          onChanged: _setReaderMode,
        );
        yield const ScrollTopButton();
        yield const ScrollBottomButton();
      } else {
        yield PopupMenuButton<VoidCallback>(
          onSelected: (callback) => callback(),
          itemBuilder: (context) => [
            textScaleMenuItem(
              context,
              textScale: textScale,
              onChanged: (value) => textScale = value,
            ),
            fontFamilyMenuItem(
              context,
              fontFamily: fontFamily,
              onChanged: (value) => fontFamily = value,
            ),
            const PopupMenuDivider(),
            readerModeMenuItem(
              context,
              enabled: readerMode,
              onChanged: _setReaderMode,
            ),
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

  void _setReaderMode(bool enabled) =>
      readerMode = OrgController.of(context).hideMarkup = enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchDelegate.searchMode,
      builder: (context, searchMode, child) => Scaffold(
        // Builder is here to ensure that the primary scroll controller set by the
        // Scaffold makes it into the body's context
        body: Builder(
          builder: (context) => CustomScrollView(
            slivers: [
              _buildAppBar(context, searchMode: searchMode),
              _buildDocument(context),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(
          context,
          searchMode: searchMode,
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context, {
    @required bool searchMode,
  }) {
    return PrimaryScrollController(
      // Context of app bar(?) lacks access to the primary scroll controller, so
      // we supply it explicitly from parent context
      controller: PrimaryScrollController.of(context),
      child: SliverAppBar(
        title: _title(searchMode),
        actions: _actions(searchMode).toList(growable: false),
        pinned: searchMode,
        floating: true,
        forceElevated: true,
        snap: true,
      ),
    );
  }

  Widget _buildDocument(BuildContext context) {
    final doc = SliverList(
      delegate: SliverChildListDelegate([
        buildWithViewSettings(
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
        // Bottom padding to compensate for Floating Action Button:
        // FAB height (56px) + padding (16px) = 72px
        const SizedBox(height: 72),
      ]),
    );

    // Add some extra padding on big screens to make things not feel so
    // tight. We can do this instead of adjusting the [OrgTheme.rootPadding]
    // because we are shrinkwapping the document
    return _bigScreen
        ? SliverPadding(padding: const EdgeInsets.all(16), sliver: doc)
        : doc;
  }

  Widget _buildFloatingActionButton(
    BuildContext context, {
    @required bool searchMode,
  }) {
    if (searchMode) {
      return null;
    }
    return FloatingActionButton(
      child: _Badge(
        child: const Icon(Icons.search),
        visible: _searchDelegate.hasQuery,
      ),
      onPressed: () => _searchDelegate.start(context),
      foregroundColor: Theme.of(context).accentTextTheme.button.color,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    @required this.child,
    @required this.visible,
    Key key,
  }) : super(key: key);

  final Widget child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        // Badge indicating an active query. The size and positioning is
        // manually adjusted to match the icon it adorns.
        Positioned(
          top: 0,
          right: 2,
          child: Visibility(
            visible: visible,
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
