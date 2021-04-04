import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/banners.dart';
import 'package:orgro/src/pages/image.dart';
import 'package:orgro/src/pages/view_settings.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    required this.doc,
    required this.title,
    required this.dataSource,
    required this.child,
    this.initialQuery,
    Key? key,
  }) : super(key: key);

  final OrgTree doc;
  final String title;
  final DataSource dataSource;
  final Widget child;
  final String? initialQuery;

  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with ViewSettingsState {
  late MySearchDelegate _searchDelegate;

  @override
  String? get queryString => _searchDelegate.queryString;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initViewSettings();
    _analyzeDoc();
  }

  Future<void> _analyzeDoc({List<String>? accessibleDirs}) async {
    final source = widget.dataSource;
    if (source is NativeDataSource && source.needsToResolveParent) {
      accessibleDirs ??= Preferences.of(context).accessibleDirs;
      await source.resolveParent(accessibleDirs.keyValueListAsMap());
    }

    var hasRemoteImages = _hasRemoteImages ?? false;
    var hasRelativeLinks = _hasRelativeLinks ?? false;
    widget.doc.visit<OrgLink>((link) {
      hasRemoteImages |=
          looksLikeImagePath(link.location) && looksLikeUrl(link.location);
      try {
        hasRelativeLinks |= OrgFileLink.parse(link.location).isRelative;
      } on Exception {
        // Not a file link
      }
      return !(hasRemoteImages && hasRelativeLinks);
    });

    setState(() {
      _hasRemoteImages ??= hasRemoteImages;
      _hasRelativeLinks ??= hasRelativeLinks;
    });
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
    } else {
      return Text(
        widget.title,
        overflow: TextOverflow.fade,
      );
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
            // Disused because icon button is always visible now
            // PopupMenuItem<VoidCallback>(
            //   child: const Text('Cycle visibility'),
            //   value: OrgController.of(context).cycleVisibility,
            // ),
            scrollTopMenuItem(context),
            scrollBottomMenuItem(context),
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
            restorationId: 'document_scroll_view',
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
    required bool searchMode,
  }) {
    return PrimaryScrollController(
      // Context of app bar(?) lacks access to the primary scroll controller, so
      // we supply it explicitly from parent context
      controller: PrimaryScrollController.of(context)!,
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
        DirectoryPermissionsBanner(
          visible: _askForDirectoryPermissions,
          onDismiss: () =>
              setLocalLinksPolicy(LocalLinksPolicy.deny, persist: false),
          onForbid: () =>
              setLocalLinksPolicy(LocalLinksPolicy.deny, persist: true),
          onAllow: _pickDirectory,
        ),
        RemoteImagePermissionsBanner(
          visible: _askPermissionToLoadRemoteImages,
          onResult: setRemoteImagesPolicy,
        ),
        buildWithViewSettings(
          builder: (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: OrgRootWidget(
                style: textStyle,
                onLinkTap: (url) {
                  debugPrint('Launching URL: $url');
                  return launch(url, forceSafariVC: false);
                },
                onSectionLongPress: (section) =>
                    narrow(context, widget.dataSource, section),
                onLocalSectionLinkTap: (section) =>
                    narrow(context, widget.dataSource, section),
                loadImage: _loadImage,
                child: widget.child,
              ),
            ),
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

  Widget? _buildFloatingActionButton(
    BuildContext context, {
    required bool searchMode,
  }) {
    if (searchMode) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () => _searchDelegate.start(context),
      foregroundColor: Theme.of(context).accentTextTheme.button?.color,
      child: _Badge(
        visible: _searchDelegate.hasQuery,
        child: const Icon(Icons.search),
      ),
    );
  }

  bool? _hasRelativeLinks;

  bool get _askForDirectoryPermissions =>
      localLinksPolicy == LocalLinksPolicy.ask &&
      _hasRelativeLinks == true &&
      widget.dataSource.needsToResolveParent;

  Future<void> _pickDirectory() async {
    final source = widget.dataSource;
    if (source is! NativeDataSource) {
      return;
    }
    final dirInfo = await pickDirectory(initialDirUri: source.uri);
    if (dirInfo == null) {
      return;
    }
    final prefs = Preferences.of(context);
    debugPrint(
        'Added accessible dir; uri: ${dirInfo.uri}; identifier: ${dirInfo.identifier}');
    final accessibleDirs = prefs.accessibleDirs
      ..add(dirInfo.uri)
      ..add(dirInfo.identifier);
    await prefs.setAccessibleDirs(accessibleDirs);
    await _analyzeDoc(accessibleDirs: accessibleDirs);
  }

  bool? _hasRemoteImages;

  bool get _askPermissionToLoadRemoteImages =>
      remoteImagesPolicy == RemoteImagesPolicy.ask &&
      _hasRemoteImages == true &&
      !_askForDirectoryPermissions;

  Widget? _loadImage(OrgLink link) {
    if (looksLikeUrl(link.location)) {
      return _loadRemoteImage(link);
    }
    try {
      final fileLink = OrgFileLink.parse(link.location);
      if (fileLink.isRelative) {
        return _loadLocalImage(fileLink);
      }
    } on Exception {
      // Not a file link
    }
    // Absolute paths, and...?
    return null;
  }

  Widget? _loadRemoteImage(OrgLink link) {
    assert(looksLikeUrl(link.location));
    if (remoteImagesPolicy != RemoteImagesPolicy.allow) {
      return null;
    }
    return RemoteImage(link.location);
  }

  Widget? _loadLocalImage(OrgFileLink link) {
    if (widget.dataSource.needsToResolveParent) {
      return null;
    }
    return LocalImage(
      dataSource: widget.dataSource,
      relativePath: link.body,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.child,
    required this.visible,
    Key? key,
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
