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
  MySearchDelegate _searchDelegate;

  @override
  void initState() {
    super.initState();
    _searchDelegate = MySearchDelegate(
        onQueryChanged: (pattern) => OrgController.of(context).search(pattern));
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
      yield TextSizeButton(
        value: _textScale,
        onChanged: (value) => setState(() => _textScale = value),
      );
      if (MediaQuery.of(context).size.width > 600) {
        yield IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: OrgController.of(context).cycleVisibility,
        );
        yield const ScrollTopButton();
        yield const ScrollBottomButton();
      } else {
        yield PopupMenuButton<VoidCallback>(
          onSelected: (callback) => callback(),
          itemBuilder: (context) => [
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
        // Builder required to get ViewSettings into the context
        child: Builder(
          builder: (context) {
            return ListView(
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
                  onLocalSectionLinkTap: (section) =>
                      narrow(context, widget.title, section),
                ),
              ],
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
    Key key,
  }) : super(child: child, key: key);

  final double textScale;

  @override
  bool updateShouldNotify(ViewSettings oldWidget) =>
      textScale != oldWidget.textScale;

  static ViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewSettings>();
}
