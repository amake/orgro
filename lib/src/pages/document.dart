import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/geometry.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/banners.dart';
import 'package:orgro/src/pages/image.dart';
import 'package:orgro/src/pages/view_settings.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _kBigScreenDocumentPadding = EdgeInsets.all(16);

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    required this.title,
    required this.dataSource,
    this.initialTarget,
    this.initialQuery,
    super.key,
  });

  final String title;
  final DataSource dataSource;
  final String? initialTarget;
  final String? initialQuery;

  @override
  State createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with ViewSettingsState {
  late MySearchDelegate _searchDelegate;

  OrgTree get _doc => DocumentProvider.of(context)!.doc;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialTarget());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initViewSettings();
    time('analyze', _analyzeDoc);
  }

  void _openInitialTarget() {
    final target = widget.initialTarget;
    if (target == null || target.isEmpty) {
      return;
    }
    OrgSection? section;
    try {
      section = OrgController.of(context).sectionForTarget(target);
    } on Exception catch (e, s) {
      logError(e, s);
    }
    if (section != null) {
      _doNarrow(section);
    }
  }

  void _doNarrow(OrgSection section) async {
    final newSection = await narrow(context, widget.dataSource, section);
    if (newSection == null || identical(newSection, section)) {
      return;
    }
    final newDoc = _doc.editNode(section)!.replace(newSection).commit();
    _updateDocument(newDoc as OrgTree);
  }

  void _onSectionLongPress(OrgSection section) async {
    final action = await showDialog<SectionAction>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (final action in SectionAction.values)
            ListTile(
              title: Text(action.toDisplayString(context)),
              onTap: () => Navigator.pop(context, action),
            ),
        ],
      ),
    );

    if (!mounted) return;

    switch (action) {
      case SectionAction.narrow:
        _doNarrow(section);
        return;
      case SectionAction.cycleTodo:
        final newDoc = _doc
            .editNode(section.headline)!
            .replace(section.headline.cycleTodo())
            .commit() as OrgTree;
        _updateDocument(newDoc);
        return;
      case null:
        return;
    }
  }

  Future<void> _analyzeDoc({List<String>? accessibleDirs}) async {
    final source = widget.dataSource;
    if (source is NativeDataSource && source.needsToResolveParent) {
      accessibleDirs ??= Preferences.of(context).accessibleDirs;
      await source.resolveParent(accessibleDirs);
    }

    final canResolveRelativeLinks =
        _canResolveRelativeLinks ?? await canObtainNativeDirectoryPermissions();
    var hasRemoteImages = _hasRemoteImages ?? false;
    var hasRelativeLinks = _hasRelativeLinks ?? false;
    _doc.visit<OrgLink>((link) {
      hasRemoteImages |=
          looksLikeImagePath(link.location) && looksLikeUrl(link.location);
      try {
        hasRelativeLinks |= OrgFileLink.parse(link.location).isRelative;
      } on Exception {
        // Not a file link
      }
      return !hasRemoteImages || (!hasRelativeLinks && canResolveRelativeLinks);
    });

    setState(() {
      _hasRemoteImages ??= hasRemoteImages;
      _hasRelativeLinks ??= hasRelativeLinks;
      _canResolveRelativeLinks ??= canResolveRelativeLinks;
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
        if (_allowFullScreen(context)) {
          yield FullWidthButton(
            enabled: fullWidth,
            onChanged: (value) => fullWidth = value,
          );
        }
        yield const ScrollTopButton();
        yield const ScrollBottomButton();
      } else {
        yield PopupMenuButton<VoidCallback>(
          onSelected: (callback) => callback(),
          itemBuilder: (context) => [
            undoMenuItem(context, onChanged: _undo),
            redoMenuItem(context, onChanged: _redo),
            const PopupMenuDivider(),
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
            if (_allowFullScreen(context))
              fullWidthMenuItem(
                context,
                enabled: fullWidth,
                onChanged: (value) => fullWidth = value,
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
      builder: (context, searchMode, child) => PopScope(
        canPop: !_dirty || _doc is! OrgDocument,
        onPopInvoked: _onPopInvoked,
        child: Scaffold(
          // Builder is here to ensure that the primary scroll controller set by the
          // Scaffold makes it into the body's context
          body: _KeyboardShortcuts(
            child: Builder(
              builder: (context) => CustomScrollView(
                restorationId: 'document_scroll_view',
                slivers: [
                  _buildAppBar(context, searchMode: searchMode),
                  _buildDocument(context),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(
            context,
            searchMode: searchMode,
          ),
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
    final doc = _doc;
    final result = SliverList(
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
        SavePermissionsBanner(
          visible: _askPermissionToSaveChanges,
          onResult: (value, {required bool persist}) {
            setSaveChangesPolicy(value, persist: persist);
            if (_dirty) _onDocChanged(_doc);
          },
        ),
        buildWithViewSettings(
          builder: (context) => _maybeConstrainWidth(
            context,
            child: SelectionArea(
              child: OrgRootWidget(
                style: textStyle,
                onLinkTap: _openLink,
                onSectionLongPress: _onSectionLongPress,
                onLocalSectionLinkTap: _doNarrow,
                onListItemTap: _onListItemTap,
                loadImage: _loadImage,
                child: switch (doc) {
                  OrgDocument() => OrgDocumentWidget(doc, shrinkWrap: true),
                  OrgSection() =>
                    OrgSectionWidget(doc, root: true, shrinkWrap: true)
                },
              ),
            ),
          ),
        ),
        // Bottom padding to compensate for Floating Action Button:
        // FAB height (56px) + padding (16px) = 72px
        const SizedBox(height: 72),
      ]),
    );

    return _maybePadForBigScreen(result);
  }

  // Add some extra padding on big screens to make things not feel so
  // tight. We can do this instead of adjusting the [OrgTheme.rootPadding]
  // because we are shrinkwapping the document
  Widget _maybePadForBigScreen(Widget child) => _bigScreen
      ? SliverPadding(padding: _kBigScreenDocumentPadding, sliver: child)
      : child;

  Widget _maybeConstrainWidth(BuildContext context, {required Widget child}) {
    if (fullWidth || !_bigScreen || !_allowFullScreen(context)) {
      return child;
    }
    final inset = (_screenWidth -
            _maxRecommendedWidth(context) -
            _kBigScreenDocumentPadding.left) /
        2;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: child,
    );
  }

  bool _allowFullScreen(BuildContext context) =>
      _maxRecommendedWidth(context) +
          _kBigScreenDocumentPadding.left +
          _kBigScreenDocumentPadding.right +
          // org_flutter default theme has 8px padding on left + right
          // TODO(aaron): make this publically accessible
          16 <
      _screenWidth;

  // Calculate the maximum document width as 72 of the character 'M' with the
  // user's preferred font size and family
  double _maxRecommendedWidth(BuildContext context) {
    final mBox = renderedBounds(
      context,
      const BoxConstraints(),
      Text.rich(const TextSpan(text: 'M'), style: textStyle),
    );
    return 72 * mBox.toRect().width;
  }

  Widget? _buildFloatingActionButton(
    BuildContext context, {
    required bool searchMode,
  }) {
    if (searchMode) {
      return const SearchResultsNavigation();
    }
    return FloatingActionButton(
      onPressed: () => _searchDelegate.start(context),
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      child: _Badge(
        visible: _searchDelegate.hasQuery,
        child: const Icon(Icons.search),
      ),
    );
  }

  Future<bool> _openLink(String url) async {
    try {
      final link = OrgFileLink.parse(url);
      return _openFileLink(link);
    } on Exception {
      // Wasn't a file link
    }

    // Handle as a general URL
    try {
      debugPrint('Launching URL: $url');
      return await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } on Exception catch (e, s) {
      logError(e, s);
      showErrorSnackBar(context, e);
    }
    return false;
  }

  Future<bool> _openFileLink(OrgFileLink link) async {
    if (!link.isRelative || !link.body.endsWith('.org')) {
      return false;
    }
    if (widget.dataSource.needsToResolveParent) {
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }
    try {
      final resolved = await widget.dataSource.resolveRelative(link.body);
      if (!mounted) return false;
      return loadDocument(context, resolved, target: link.extra);
    } on Exception catch (e, s) {
      logError(e, s);
      showErrorSnackBar(context, e);
    }
    return false;
  }

  bool? _hasRelativeLinks;

  // Android 4.4 and earlier doesn't have APIs to get directory info
  bool? _canResolveRelativeLinks;

  bool get _askForDirectoryPermissions =>
      localLinksPolicy == LocalLinksPolicy.ask &&
      _hasRelativeLinks == true &&
      _canResolveRelativeLinks == true &&
      widget.dataSource.needsToResolveParent;

  Future<void> _pickDirectory() async {
    try {
      final source = widget.dataSource;
      if (source is! NativeDataSource) {
        return;
      }
      final dirInfo = await pickDirectory(initialDirUri: source.uri);
      if (dirInfo == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      final prefs = Preferences.of(context);
      debugPrint(
          'Added accessible dir; uri: ${dirInfo.uri}; identifier: ${dirInfo.identifier}');
      final accessibleDirs = prefs.accessibleDirs..add(dirInfo.identifier);
      await prefs.setAccessibleDirs(accessibleDirs);
      await _analyzeDoc(accessibleDirs: accessibleDirs);
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  void _showDirectoryPermissionsSnackBar(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .snackbarMessageNeedsDirectoryPermissions,
          ),
          action: _canResolveRelativeLinks == true
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!
                      .snackbarActionGrantAccess
                      .toUpperCase(),
                  onPressed: _pickDirectory,
                )
              : null,
        ),
      );

  void _onListItemTap(OrgListItem item) {
    final newTree =
        _doc.editNode(item)!.replace(item.toggleCheckbox()).commit();
    _updateDocument(newTree as OrgTree);
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

  bool get _askPermissionToSaveChanges =>
      saveChangesPolicy == SaveChangesPolicy.ask &&
      _canSaveChanges &&
      !_askForDirectoryPermissions &&
      !_askPermissionToLoadRemoteImages;

  bool get _canSaveChanges =>
      widget.dataSource is NativeDataSource && _doc is OrgDocument;

  Timer? _writeTimer;

  bool _dirty = false;

  Future<void> _updateDocument(OrgTree newDoc) async {
    DocumentProvider.of(context)!.pushDoc(newDoc);
    await _onDocChanged(newDoc);
  }

  Future<void> _undo() async {
    final doc = DocumentProvider.of(context)!.undo();
    await _onDocChanged(doc);
  }

  Future<void> _redo() async {
    final doc = DocumentProvider.of(context)!.redo();
    await _onDocChanged(doc);
  }

  Future<void> _onDocChanged(OrgTree doc) async {
    _dirty = true;
    final source = widget.dataSource;
    if (saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource &&
        doc is OrgDocument) {
      _writeTimer?.cancel();
      _writeTimer = Timer(const Duration(seconds: 3), () async {
        try {
          await source.write(doc.toMarkup());
          _dirty = false;
          if (mounted) {
            showErrorSnackBar(
              context,
              AppLocalizations.of(context)!.savedMessage,
            );
          }
        } on Exception catch (e, s) {
          logError(e, s);
          if (mounted) showErrorSnackBar(context, e);
        }
      });
    }
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (!_dirty) return;

    // Don't try to save anything other than a root document
    final doc = _doc;
    if (doc is! OrgDocument) return;

    final navigator = Navigator.of(context);

    // Save now, if possible
    final source = widget.dataSource;
    if (saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource) {
      await source.write(doc.toMarkup());
      navigator.pop();
      return;
    }

    // Prompt to share
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.save),
        title: Text(AppLocalizations.of(context)!.saveChangesDialogTitle),
        content: Text(AppLocalizations.of(context)!.saveChangesDialogMessage),
        actions: [
          Builder(builder: (context) {
            return ListTile(
              title: Text(SaveAction.share.toDisplayString(context)),
              onTap: () async {
                final navigator = Navigator.of(context);

                // Compute origin of share sheet for tablets
                final box = context.findRenderObject() as RenderBox?;
                final origin = box!.localToGlobal(Offset.zero) & box.size;

                final result = await Share.shareWithResult(
                  doc.toMarkup(),
                  sharePositionOrigin: origin,
                );

                // Don't close popup unless user successfully shared
                if (result.status == ShareResultStatus.success) {
                  navigator.pop(true);
                }
              },
            );
          }),
          ListTile(
            title: Text(SaveAction.discard.toDisplayString(context)),
            onTap: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) navigator.pop();
  }
}

class _KeyboardShortcuts extends StatelessWidget {
  const _KeyboardShortcuts({required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW): () =>
            Navigator.maybePop(context),
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.child,
    required this.visible,
  });

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

enum SectionAction { narrow, cycleTodo }

extension SectionActionDisplayString on SectionAction {
  String toDisplayString(BuildContext context) => switch (this) {
        SectionAction.narrow =>
          AppLocalizations.of(context)!.sectionActionNarrow,
        SectionAction.cycleTodo =>
          AppLocalizations.of(context)!.sectionActionCycleTodo
      };
}

enum SaveAction { share, discard }

extension SaveActionDisplayString on SaveAction {
  String toDisplayString(BuildContext context) => switch (this) {
        SaveAction.share => AppLocalizations.of(context)!.saveActionShare,
        SaveAction.discard => AppLocalizations.of(context)!.saveActionDiscard,
      };
}
