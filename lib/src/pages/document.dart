import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/geometry.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/components/banners.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/fab.dart';
import 'package:orgro/src/components/image.dart';
import 'package:orgro/src/components/slidable_action.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/encryption.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/native_search.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/serialization.dart';
import 'package:orgro/src/util.dart';
import 'package:url_launcher/url_launcher.dart';

const _kBigScreenDocumentPadding = EdgeInsets.all(16);

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    required this.title,
    this.initialTarget,
    this.initialQuery,
    this.initialFilter,
    required this.root,
    super.key,
  });

  final String title;
  final String? initialTarget;
  final String? initialQuery;
  final FilterData? initialFilter;
  final bool root;

  @override
  State createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late MySearchDelegate _searchDelegate;

  OrgTree get _doc => DocumentProvider.of(context).doc;
  DataSource get _dataSource => DocumentProvider.of(context).dataSource;

  InheritedViewSettings get _viewSettings => ViewSettings.of(context);

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
        if (query.isEmpty || query.length > 3) {
          _doQuery(query);
        }
      },
      onQuerySubmitted: _doQuery,
      initialQuery: widget.initialQuery,
      initialFilter: widget.initialFilter,
      onFilterChanged: (value) => _viewSettings.filterData = value,
    );
    canObtainNativeDirectoryPermissions().then(
      (value) => setState(() => _canResolveRelativeLinks = value),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialTarget();
      _ensureOpenOnNarrow();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analysis = DocumentProvider.of(context).analysis;
    _searchDelegate.keywords = analysis.keywords ?? [];
    _searchDelegate.tags = analysis.tags ?? [];
    _searchDelegate.priorities = analysis.priorities ?? [];
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

  void _ensureOpenOnNarrow() {
    if (widget.root) return;
    OrgController.of(context).setVisibilityOf(
      _doc,
      (state) => switch (state) {
        OrgVisibilityState.folded => OrgVisibilityState.children,
        _ => state,
      },
    );
  }

  Future<void> _doNarrow(OrgSection section) async {
    final newSection = await narrow(context, _dataSource, section);
    if (newSection == null || identical(newSection, section)) {
      return;
    }
    try {
      final newDoc = _applyNarrowResult(before: section, after: newSection);
      if (newDoc != null) await _updateDocument(newDoc as OrgTree);
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  OrgNode? _applyNarrowResult({
    required OrgSection before,
    required OrgTree after,
  }) {
    switch (after) {
      case OrgSection():
        return _doc.editNode(before)!.replace(after).commit();
      case OrgDocument():
        // If the narrowed section was edited, an OrgDocument will come back.
        //
        // The document may be empty:
        if (after.content == null && after.sections.isEmpty) {
          return null;
        }
        OrgSection toReplace;
        Iterable<OrgSection> toInsert;
        if (after.content != null) {
          // The document may have leading content. The expected thing if
          // editing plain text would be to append it to the previous section,
          // but that's pretty annoying to do with zippers, so instead we wrap
          // it in a section just so it's not lost.
          toInsert = after.sections;
          final headline = AppLocalizations.of(context)!.editInsertedHeadline;
          toReplace = OrgSection(
            OrgHeadline(
              toInsert.firstOrNull?.headline.stars ?? before.headline.stars,
              null,
              null,
              OrgContent([OrgPlainText(headline)]),
              headline,
              null,
              '\n',
            ),
            after.content!,
          );
        } else {
          // If there is no leading content then we can just insert all the
          // sections. Note that if the sections' levels have been changed then
          // the resulting document could be one that is impossible to obtain
          // from parsing (i.e. improper nesting). This is hard to fix and at
          // the moment doesn't seem to cause any problems other than surprising
          // folding/unfolding behavior, so we just let it be.
          toReplace = after.sections.first;
          toInsert = after.sections.skip(1);
        }
        var zipper = _doc.editNode(before)!.replace(toReplace);
        for (final newSec in toInsert) {
          zipper = zipper.insertRight(newSec);
        }
        final newDoc = zipper.commit();
        OrgController.of(context).adaptVisibility(newDoc as OrgTree,
            defaultState: OrgVisibilityState.children);
        return newDoc;
      default:
        throw Exception('Unexpected section type: $after');
    }
  }

  void _onSectionLongPress(OrgSection section) async => _doNarrow(section);

  List<Widget> _onSectionSlide(OrgSection section) {
    return [
      ResponsiveSlidableAction(
        label: AppLocalizations.of(context)!.sectionActionCycleTodo,
        icon: Icons.repeat,
        onPressed: () {
          final newDoc = _doc
              .editNode(section.headline)!
              .replace(section.headline.cycleTodo())
              .commit() as OrgTree;
          _updateDocument(newDoc);
        },
      ),
    ];
  }

  void _doQuery(String query) => _viewSettings.queryString = query;

  @override
  void dispose() {
    _searchDelegate.dispose();
    _dirty.dispose();
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
    final viewSettings = _viewSettings;
    if (!searchMode || _biggishScreen) {
      yield IconButton(
        icon: const Icon(Icons.repeat),
        onPressed: OrgController.of(context).cycleVisibility,
      );
      if (_bigScreen) {
        yield TextStyleButton(
          textScale: viewSettings.textScale,
          onTextScaleChanged: (value) => viewSettings.textScale = value,
          fontFamily: viewSettings.fontFamily,
          onFontFamilyChanged: (value) => viewSettings.fontFamily = value,
        );
        yield ReaderModeButton(
          enabled: viewSettings.readerMode,
          onChanged: (value) => viewSettings.readerMode = value,
        );
        if (_allowFullScreen(context)) {
          yield FullWidthButton(
            enabled: viewSettings.fullWidth,
            onChanged: (value) => viewSettings.fullWidth = value,
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
              textScale: viewSettings.textScale,
              onChanged: (value) => viewSettings.textScale = value,
            ),
            fontFamilyMenuItem(
              context,
              fontFamily: viewSettings.fontFamily,
              onChanged: (value) => viewSettings.fontFamily = value,
            ),
            const PopupMenuDivider(),
            readerModeMenuItem(
              context,
              enabled: viewSettings.readerMode,
              onChanged: (value) => viewSettings.readerMode = value,
            ),
            if (_allowFullScreen(context))
              fullWidthMenuItem(
                context,
                enabled: viewSettings.fullWidth,
                onChanged: (value) => viewSettings.fullWidth = value,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchDelegate.searchMode,
      builder: (context, searchMode, _) => ValueListenableBuilder<bool>(
        valueListenable: _dirty,
        builder: (context, dirty, _) {
          return PopScope(
            canPop:
                searchMode || !dirty || _doc is! OrgDocument || !widget.root,
            onPopInvokedWithResult: _onPopInvoked,
            child: Scaffold(
              body: _KeyboardShortcuts(
                // Builder is here to ensure that the primary scroll controller set by the
                // Scaffold makes it into the body's context
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
              // Builder is here to ensure that the Scaffold makes it into the
              // body's context
              floatingActionButton: Builder(
                builder: (context) => _buildFloatingActionButton(
                  context,
                  searchMode: searchMode,
                ),
              ),
              bottomSheet:
                  searchMode ? _searchDelegate.buildBottomSheet(context) : null,
            ),
          );
        },
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
    final viewSettings = _viewSettings;
    final doc = _doc;
    final result = SliverList(
      delegate: SliverChildListDelegate([
        DirectoryPermissionsBanner(
          visible: _askForDirectoryPermissions,
          onDismiss: () => viewSettings
              .setLocalLinksPolicy(LocalLinksPolicy.deny, persist: false),
          onForbid: () => viewSettings
              .setLocalLinksPolicy(LocalLinksPolicy.deny, persist: true),
          onAllow: _pickDirectory,
        ),
        RemoteImagePermissionsBanner(
          visible: _askPermissionToLoadRemoteImages,
          onResult: viewSettings.setRemoteImagesPolicy,
        ),
        SavePermissionsBanner(
          visible: _askPermissionToSaveChanges,
          onResult: (value, {required bool persist}) {
            viewSettings.setSaveChangesPolicy(value, persist: persist);
            if (_dirty.value) _onDocChanged(_doc);
          },
        ),
        DecryptContentBanner(
          visible: _askToDecrypt,
          onAccept: _decryptContent,
          onDeny: viewSettings.setDecryptPolicy,
        ),
        _maybeConstrainWidth(
          context,
          child: SelectionArea(
            child: OrgRootWidget(
              style: viewSettings.textStyle,
              onLinkTap: _openLink,
              onSectionLongPress: _onSectionLongPress,
              onSectionSlide: _onSectionSlide,
              onLocalSectionLinkTap: _doNarrow,
              onListItemTap: _onListItemTap,
              loadImage: _loadImage,
              child: switch (doc) {
                OrgDocument() => OrgDocumentWidget(doc, shrinkWrap: true),
                OrgSection() =>
                  OrgSectionWidget(doc, root: true, shrinkWrap: true),
                _ => throw Exception('Unexpected document type: $doc'),
              },
            ),
          ),
        ),
        // Bottom padding to compensate for Floating Action Button:
        // FAB height (56px) + padding (16px) = 72px
        //
        // TODO(aaron): Include edit FAB?
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
    if (_viewSettings.fullWidth || !_bigScreen || !_allowFullScreen(context)) {
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
      Text.rich(const TextSpan(text: 'M'), style: _viewSettings.textStyle),
    );
    return 72 * mBox.toRect().width;
  }

  Widget _buildFloatingActionButton(
    BuildContext context, {
    required bool searchMode,
  }) =>
      searchMode
          ? const SearchResultsNavigation()
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _doEdit,
                  heroTag: '${widget.title}EditFAB',
                  mini: true,
                  child: const Icon(Icons.edit),
                ),
                const SizedBox(height: 16),
                BadgableFloatingActionButton(
                  badgeVisible: _searchDelegate.hasQuery,
                  onPressed: () => _searchDelegate.start(context),
                  heroTag: '${widget.title}FAB',
                  child: const Icon(Icons.search),
                ),
              ],
            );

  Future<void> _doEdit() async {
    final controller = OrgController.of(context);
    final newDoc = await showTextEditor(context, _dataSource.name, _doc);
    if (newDoc != null) {
      controller.adaptVisibility(newDoc,
          defaultState: OrgVisibilityState.children);
      await _updateDocument(newDoc);
    }
  }

  Future<bool> _openLink(OrgLink link) async {
    try {
      final fileLink = convertLinkResolvingAttachments(_doc, link);
      return _openFileLink(fileLink);
    } on Exception {
      // Wasn't a file link
    }

    if (isOrgIdUrl(link.location)) {
      return await _openExternalIdLink(link.location);
    }

    // Handle as a general URL
    try {
      debugPrint('Launching URL: ${link.location}');
      final handled = await launchUrl(Uri.parse(link.location),
          mode: LaunchMode.externalApplication);
      if (!handled && mounted) {
        showErrorSnackBar(context,
            AppLocalizations.of(context)!.errorLinkNotHandled(link.location));
      }
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
    return false;
  }

  Future<bool> _openExternalIdLink(String url) async {
    assert(isOrgIdUrl(url));

    final dataSource = _dataSource;
    if (dataSource is! NativeDataSource) {
      debugPrint('Unsupported data source: ${dataSource.runtimeType}');
      // TODO(aaron): report unsupported data source type to user
      return false;
    }

    if (dataSource.needsToResolveParent) {
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final targetId = parseOrgIdUrl(url);

    final accessibleDirs = Preferences.of(context).accessibleDirs;

    // TODO(aaron): Find a way to make this operation cancelable
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      ),
    );

    try {
      // TODO(aaron): Search accessible dir that contains this document first
      for (final dir in accessibleDirs) {
        final foundFile = await findFileForId(id: targetId, dirIdentifier: dir);
        if (foundFile != null && mounted) {
          Navigator.pop(context);
          return loadDocument(context, foundFile, target: url);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        showErrorSnackBar(context,
            AppLocalizations.of(context)!.errorExternalIdNotFound(targetId));
      }
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) {
        Navigator.pop(context);
        showErrorSnackBar(context, e);
      }
    }
    return false;
  }

  Future<bool> _openFileLink(OrgFileLink link) async {
    if (!link.isRelative || !link.body.endsWith('.org')) {
      return false;
    }
    final source = _dataSource;
    if (source.needsToResolveParent) {
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }
    try {
      final resolved = await source.resolveRelative(link.body);
      if (!mounted) return false;
      return loadDocument(context, resolved, target: link.extra);
    } on Exception catch (e, s) {
      // TODO(aaron): Investigate failure to open relative link on iOS
      //
      // It seems that somehow we can have an accessibleDir that allows
      // resolving this document, a link.body that points to a real file, but
      // resolveRelative fails with Domain=NSCocoaErrorDomain Code=260 "The file
      // couldn’t be opened because it doesn’t exist."
      //
      // Clearing accessibleDirs and making the user re-choose a parent dir
      // seems to fix it, so maybe prompt for directory permissions again here.
      logError(e, s);
      showErrorSnackBar(context, e);
    }
    return false;
  }

  bool? get _hasRelativeLinks =>
      DocumentProvider.of(context).analysis.hasRelativeLinks;

  // Android 4.4 and earlier doesn't have APIs to get directory info
  bool? _canResolveRelativeLinks;

  bool get _askForDirectoryPermissions =>
      _viewSettings.localLinksPolicy == LocalLinksPolicy.ask &&
      _hasRelativeLinks == true &&
      _canResolveRelativeLinks == true &&
      _dataSource.needsToResolveParent;

  Future<void> _pickDirectory() async {
    try {
      final source = _dataSource;
      if (source is! NativeDataSource) {
        return;
      }
      final dirInfo = await pickDirectory(initialDirUri: source.uri);
      if (dirInfo == null) return;
      if (!mounted) return;
      debugPrint(
          'Added accessible dir; uri: ${dirInfo.uri}; identifier: ${dirInfo.identifier}');
      await DocumentProvider.of(context).addAccessibleDir(dirInfo.identifier);
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

  bool? get _hasRemoteImages =>
      DocumentProvider.of(context).analysis.hasRemoteImages;

  bool get _askPermissionToLoadRemoteImages =>
      _viewSettings.remoteImagesPolicy == RemoteImagesPolicy.ask &&
      _hasRemoteImages == true &&
      !_askForDirectoryPermissions;

  Widget? _loadImage(OrgLink link) {
    if (looksLikeUrl(link.location)) {
      return _loadRemoteImage(link);
    }
    try {
      final fileLink = convertLinkResolvingAttachments(_doc, link);
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
    if (_viewSettings.remoteImagesPolicy != RemoteImagesPolicy.allow) {
      return null;
    }
    return RemoteImage(link.location);
  }

  Widget? _loadLocalImage(OrgFileLink link) {
    final source = _dataSource;
    if (source.needsToResolveParent) {
      return null;
    }
    return LocalImage(
      dataSource: source,
      relativePath: link.body,
    );
  }

  bool get _askPermissionToSaveChanges =>
      _viewSettings.saveChangesPolicy == SaveChangesPolicy.ask &&
      _canSaveChanges &&
      !_askForDirectoryPermissions &&
      !_askPermissionToLoadRemoteImages;

  bool get _canSaveChanges =>
      _dataSource is NativeDataSource && _doc is OrgDocument && widget.root;

  Timer? _writeTimer;
  Future<void>? _writeFuture;

  final ValueNotifier<bool> _dirty = ValueNotifier(false);

  Future<bool> _updateDocument(OrgTree newDoc, {bool dirty = true}) async {
    final pushed = await DocumentProvider.of(context).pushDoc(newDoc);
    if (pushed && dirty) {
      await _onDocChanged(newDoc);
    }
    return pushed;
  }

  Future<void> _undo() async {
    final doc = DocumentProvider.of(context).undo();
    await _onDocChanged(doc);
  }

  Future<void> _redo() async {
    final doc = DocumentProvider.of(context).redo();
    await _onDocChanged(doc);
  }

  Future<void> _onDocChanged(OrgTree doc) async {
    _dirty.value = true;
    final source = _dataSource;
    if (_viewSettings.saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource &&
        doc is OrgDocument) {
      _writeTimer?.cancel();
      _writeTimer = Timer(const Duration(seconds: 3), () {
        _writeFuture = time('save', () async {
          try {
            debugPrint('starting auto save');
            final markup = await serialize(doc);
            await time('write', () => source.write(markup));
            _dirty.value = false;
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
        }).whenComplete(() => _writeFuture = null);
      });
    }
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;

    assert(_dirty.value);

    final doc = _doc;
    // Don't try to save anything other than a root document
    if (doc is! OrgDocument || !widget.root) return;

    final navigator = Navigator.of(context);

    // If we are already in the middle of saving, wait for that to finish
    final writeFuture = _writeFuture;
    if (writeFuture != null) {
      debugPrint('waiting for autosave to finish');
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProgressIndicatorDialog(
          title: AppLocalizations.of(context)!.savingProgressDialogTitle,
        ),
      );
      await writeFuture.whenComplete(() => navigator.pop());
      if (!_dirty.value) {
        navigator.pop();
        return;
      }
    }

    if (!mounted) return;

    // Save now, if possible
    final viewSettings = _viewSettings;
    var saveChangesPolicy = viewSettings.saveChangesPolicy;
    final source = _dataSource;
    if (viewSettings.saveChangesPolicy == SaveChangesPolicy.ask &&
        _canSaveChanges) {
      final result = await showDialog<(SaveChangesPolicy, bool)>(
        context: context,
        builder: (context) => const SavePermissionDialog(),
      );
      if (result == null) {
        return;
      } else {
        final (newPolicy, persist) = result;
        saveChangesPolicy = newPolicy;
        viewSettings.setSaveChangesPolicy(newPolicy, persist: persist);
      }
    }

    if (saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource) {
      debugPrint('synchronously saving now');
      _writeTimer?.cancel();
      final markup = await serializeWithProgressUI(context, doc);
      if (markup == null) return;
      await time('write', () => source.write(markup));
      navigator.pop();
      return;
    }

    // Prompt to share
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ShareUnsaveableChangesDialog(doc: doc),
    );

    if (result == true) navigator.pop();
  }

  bool? get _hasEncryptedContent =>
      DocumentProvider.of(context).analysis.hasEncryptedContent;

  bool get _askToDecrypt =>
      _viewSettings.decryptPolicy == DecryptPolicy.ask &&
      _hasEncryptedContent == true &&
      !_askForDirectoryPermissions &&
      !_askPermissionToLoadRemoteImages &&
      !_askPermissionToSaveChanges;

  Future<void> _decryptContent() async {
    final blocks = <OrgPgpBlock>[];
    _doc.visit<OrgPgpBlock>((block) {
      blocks.add(block);
      return true;
    });
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const InputPasswordDialog(),
    );
    if (password == null) return;
    if (!mounted) return;
    var canceled = false;
    time('decrypt', () => compute(decrypt, (blocks, password)))
        .then((decrypted) {
      if (!canceled && mounted) Navigator.pop(context, decrypted);
    }).onError((error, stackTrace) {
      if (mounted) showErrorSnackBar(context, error);
      logError(error, stackTrace);
      if (!canceled && mounted) Navigator.pop(context);
    });
    final result = await showDialog<List<String?>>(
      context: context,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.decryptingProgressDialogTitle,
        dismissable: true,
      ),
    );
    if (!mounted) return;
    if (result == null) {
      // Canceled
      canceled = true;
      return;
    }
    OrgTree newDoc = _doc;
    for (final (i, cleartext) in result.indexed) {
      if (cleartext == null) {
        showErrorSnackBar(
            context, AppLocalizations.of(context)!.errorDecryptionFailed);
        continue;
      }
      final block = blocks[i];
      try {
        final replacement = OrgDecryptedContent.fromDecryptedResult(
          cleartext,
          OrgroSerializer(block, cleartext: cleartext, password: password),
        );
        newDoc =
            newDoc.editNode(block)!.replace(replacement).commit() as OrgTree;
      } catch (e, s) {
        logError(e, s);
        showErrorSnackBar(context, e);
        continue;
      }
    }
    await _updateDocument(newDoc, dirty: false);
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
