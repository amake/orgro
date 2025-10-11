import 'dart:async';

import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/geometry.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/components/banners.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/fab.dart';
import 'package:orgro/src/components/scroll.dart';
import 'package:orgro/src/components/slidable_action.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/encryption.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/agenda.dart';
import 'package:orgro/src/pages/document/citations.dart';
import 'package:orgro/src/pages/document/encryption.dart';
import 'package:orgro/src/pages/document/images.dart';
import 'package:orgro/src/pages/document/keyboard.dart';
import 'package:orgro/src/pages/document/links.dart';
import 'package:orgro/src/pages/document/narrow.dart';
import 'package:orgro/src/pages/document/restoration.dart';
import 'package:orgro/src/pages/document/timestamps.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/serialization.dart';
import 'package:orgro/src/statistics.dart';
import 'package:orgro/src/util.dart';

const _kBigScreenDocumentPadding = EdgeInsets.all(16);

enum InitialMode { view, edit }

extension InitialModePersistence on InitialMode? {
  String? get persistableString => switch (this) {
    InitialMode.view => 'view',
    InitialMode.edit => 'edit',
    null => null,
  };

  static InitialMode? fromString(String? value) => switch (value) {
    'view' => InitialMode.view,
    'edit' => InitialMode.edit,
    _ => null,
  };
}

const _kDefaultInitialMode = InitialMode.view;

const kRestoreNarrowTargetKey = 'restore_narrow_target';
const kRestoreModeKey = 'restore_mode';
const kRestoreSearchQueryKey = 'restore_search_query';
const kRestoreSearchFilterKey = 'restore_search_filter';
const kRestoreDirtyDocumentKey = 'restore_dirty_document';

class DocumentPage extends StatefulWidget {
  const DocumentPage({
    required this.layer,
    required this.title,
    this.initialMode,
    this.initialTarget,
    this.initialQuery,
    this.initialFilter,
    required this.root,
    super.key,
  });

  final int layer;
  final String title;
  final String? initialTarget;
  final String? initialQuery;
  final InitialMode? initialMode;
  final FilterData? initialFilter;
  final bool root;

  @override
  State createState() => DocumentPageState();
}

class DocumentPageState extends State<DocumentPage> with RestorationMixin {
  @override
  String get restorationId => 'document_page_${widget.layer}';

  late MySearchDelegate searchDelegate;

  OrgTree get _doc => DocumentProvider.of(context).doc;
  DataSource get _dataSource => DocumentProvider.of(context).dataSource;

  InheritedViewSettings get _viewSettings => ViewSettings.of(context);

  double get _screenWidth => MediaQuery.sizeOf(context).width;

  // Not sure why this size
  bool get _biggishScreen => _screenWidth > 500;

  // E.g. iPad mini in portrait (768px), iPhone XS in landscape (812px), Pixel 2
  // in landscape (731px)
  bool get _bigScreen => _screenWidth > 600;

  @override
  void initState() {
    super.initState();
    searchDelegate = MySearchDelegate(
      onQueryChanged: (query) {
        if (query.isEmpty || query.length > 3) {
          _doQuery(query);
        }
      },
      onQuerySubmitted: _doQuery,
      initialQuery: widget.initialQuery,
      initialFilter: widget.initialFilter,
      onFilterChanged: _doSearchFilter,
    );
    canObtainNativeDirectoryPermissions().then(
      (value) => setState(() => canResolveRelativeLinks = value),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openNarrowTarget(widget.initialTarget);
      ensureOpenOnNarrow();
      if (widget.initialTarget == null) {
        switch (widget.initialMode ?? _kDefaultInitialMode) {
          case InitialMode.view:
            // do nothing
            break;
          case InitialMode.edit:
            doEdit(requestFocus: true);
            break;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analysis = DocumentProvider.of(context).analysis;
    searchDelegate.keywords = analysis.keywords ?? [];
    searchDelegate.tags = analysis.tags ?? [];
    searchDelegate.priorities = analysis.priorities ?? [];
    searchDelegate.todoSettings = OrgSettings.of(context).settings.todoSettings;
    if (analysis.loaded && isAgendaFile) {
      // The same file's persistent identifier may change; re-add to overwrite
      // stale entry.
      setAgendaFile();
      debugPrint('AMK setting notifications!');
      setNotifications();
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final restoreDoc = restoreDocument();
      restoreSearchState();

      if (!initialRestore) return;

      // Wait for doc to finish restoring before opening narrow target
      await restoreDoc;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = bucket!.read<String>(kRestoreNarrowTargetKey);
        if (widget.initialTarget == null) {
          openNarrowTarget(target);
        }
        if (widget.initialMode == null && target == null) {
          restoreMode();
        }
      });
    });
  }

  void _onSectionLongPress(OrgSection section) async => doNarrow(section);

  List<Widget> _onSectionSlide(OrgSection section) {
    return [
      ResponsiveSlidableAction(
        label: AppLocalizations.of(context)!.sectionActionCycleTodo,
        icon: Icons.repeat,
        onPressed: () {
          final todoSettings = OrgSettings.of(context).settings.todoSettings;
          try {
            final replacement = section.headline.cycleTodo(todoSettings);
            var newDoc =
                _doc.editNode(section.headline)!.replace(replacement).commit()
                    as OrgTree;
            newDoc = recalculateHeadlineStats(newDoc, replacement);
            updateDocument(newDoc);
          } catch (e, s) {
            logError(e, s);
            // TODO(aaron): Make this more friendly?
            showErrorSnackBar(context, e);
          }
        },
      ),
    ];
  }

  void _doQuery(String query) {
    if (query.isEmpty) {
      bucket!.remove<String>(kRestoreSearchQueryKey);
    } else {
      bucket!.write(kRestoreSearchQueryKey, query);
    }
    _viewSettings.queryString = query;
  }

  void _doSearchFilter(FilterData filterData) {
    if (filterData.isEmpty) {
      bucket!.remove<void>(kRestoreSearchFilterKey);
    } else {
      bucket!.write(kRestoreSearchFilterKey, filterData.toJson());
    }
    _viewSettings.filterData = filterData;
  }

  @override
  void dispose() {
    searchDelegate.dispose();
    _dirty.dispose();
    super.dispose();
  }

  Widget _title(bool searchMode) {
    if (searchMode) {
      return searchDelegate.buildSearchField();
    } else {
      return Text(widget.title, overflow: TextOverflow.fade);
    }
  }

  Iterable<Widget> _actions(bool searchMode) sync* {
    final viewSettings = _viewSettings;
    final scopeKey = _dataSource.id;
    final scopedViewSettings = viewSettings.forScope(scopeKey);
    if (!searchMode || _biggishScreen) {
      yield IconButton(
        icon: const Icon(Icons.repeat),
        onPressed: OrgController.of(context).cycleVisibility,
      );
      if (_bigScreen) {
        yield TextStyleButton(
          textScale: scopedViewSettings.textScale,
          onTextScaleChanged: (value) =>
              viewSettings.setTextScale(scopeKey, value),
          fontFamily: scopedViewSettings.fontFamily,
          onFontFamilyChanged: (value) =>
              viewSettings.setFontFamily(scopeKey, value),
        );
        yield ReaderModeButton(
          enabled: scopedViewSettings.readerMode,
          onChanged: (value) => viewSettings.readerMode = value,
        );
        if (_allowFullScreen(context)) {
          yield FullWidthButton(
            enabled: scopedViewSettings.fullWidth,
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
              textScale: scopedViewSettings.textScale,
              onChanged: (value) => viewSettings.setTextScale(scopeKey, value),
            ),
            fontFamilyMenuItem(
              context,
              fontFamily: scopedViewSettings.fontFamily,
              onChanged: (value) => viewSettings.setFontFamily(scopeKey, value),
            ),
            const PopupMenuDivider(),
            readerModeMenuItem(
              context,
              enabled: scopedViewSettings.readerMode,
              onChanged: (value) => viewSettings.readerMode = value,
            ),
            if (_allowFullScreen(context))
              fullWidthMenuItem(
                context,
                enabled: scopedViewSettings.fullWidth,
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
      valueListenable: searchDelegate.searchMode,
      builder: (context, searchMode, _) => ValueListenableBuilder<bool>(
        valueListenable: _dirty,
        builder: (context, dirty, _) {
          return PopScope(
            canPop:
                searchMode || !dirty || _doc is! OrgDocument || !widget.root,
            onPopInvokedWithResult: _onPopInvoked,
            child: KeyboardShortcuts(
              onEdit: doEdit,
              onUndo: _undo,
              onRedo: _redo,
              searchDelegate: searchDelegate,
              child: Scaffold(
                body: CustomScrollView(
                  restorationId: 'document_scroll_view_${widget.layer}',
                  slivers: [
                    _buildAppBar(context, searchMode: searchMode),
                    _buildDocument(context),
                  ],
                ),
                // Builder is here to ensure that the Scaffold makes it into the
                // body's context
                floatingActionButton: Builder(
                  builder: (context) => _buildFloatingActionButton(
                    context,
                    searchMode: searchMode,
                  ),
                ),
                bottomSheet: searchMode
                    ? searchDelegate.buildBottomSheet(context)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, {required bool searchMode}) {
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
    final docProvider = DocumentProvider.of(context);
    final doc = docProvider.doc;
    final analysis = docProvider.analysis;
    final result = SliverList(
      delegate: SliverChildListDelegate([
        DirectoryPermissionsBanner(
          visible: _askForDirectoryPermissions,
          onDismiss: () => viewSettings.setLocalLinksPolicy(
            LocalLinksPolicy.deny,
            persist: false,
          ),
          onForbid: () => viewSettings.setLocalLinksPolicy(
            LocalLinksPolicy.deny,
            persist: true,
          ),
          onAllow: doPickDirectory,
        ),
        RemoteImagePermissionsBanner(
          visible: _askPermissionToLoadRemoteImages,
          onResult: viewSettings.setRemoteImagesPolicy,
        ),
        SavePermissionsBanner(
          visible: _askPermissionToSaveChanges,
          onResult: (value, {required bool persist}) {
            viewSettings.setSaveChangesPolicy(value, persist: persist);
            if (_dirty.value) _onDocChanged(doc, analysis);
          },
        ),
        DecryptContentBanner(
          visible: _askToDecrypt,
          onAccept: decryptContent,
          onDeny: viewSettings.setDecryptPolicy,
        ),
        AgendaNotificationsBanner(
          visible: _askAboutAgendaNotifications,
          onAccept: setAgendaFile,
          onDeny: viewSettings.setAgendaNotificationsPolicy,
        ),
        _maybeConstrainWidth(
          context,
          child: SelectionArea(
            child: OrgRootWidget(
              style: viewSettings.forScope(_dataSource.id).textStyle,
              onLinkTap: openLink,
              onSectionLongPress: _onSectionLongPress,
              onSectionSlide: _onSectionSlide,
              onLocalSectionLinkTap: doNarrow,
              onListItemTap: _onListItemTap,
              onCitationTap: openCitation,
              onTimestampTap: onTimestampTap,
              loadImage: loadImage,
              child: switch (doc) {
                OrgDocument() => OrgDocumentWidget(doc, shrinkWrap: true),
                OrgSection() => OrgSectionWidget(
                  doc,
                  root: true,
                  shrinkWrap: true,
                ),
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
    final inset =
        (_screenWidth -
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
  }) => searchMode
      ? searchDelegate.buildSearchResultsNavigation()
      : ScrollingBuilder(
          builder: (context, scrolling) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 16,
            children: [
              FloatingActionButton(
                onPressed: () {
                  if (scrolling) return;
                  doEdit();
                },
                heroTag: '${widget.title}EditFAB',
                mini: true,
                child: const Icon(Icons.edit),
              ),
              BadgableFloatingActionButton(
                badgeVisible: searchDelegate.hasQuery,
                onPressed: () {
                  if (scrolling) return;
                  searchDelegate.start(context);
                },
                heroTag: '${widget.title}FAB',
                child: const Icon(Icons.search),
              ),
            ],
          ),
        );

  Future<void> doEdit({bool requestFocus = false}) async {
    final controller = OrgController.of(context);
    bucket!.write(kRestoreModeKey, InitialMode.edit.persistableString);
    final newDoc = await showTextEditor(
      context,
      _dataSource,
      _doc,
      requestFocus: requestFocus,
      layer: widget.layer,
    );
    bucket!.remove<String>(kRestoreModeKey);
    if (newDoc != null) {
      controller.adaptVisibility(
        newDoc,
        defaultState: OrgVisibilityState.children,
      );
      await updateDocument(newDoc);
    }
  }

  bool? get _hasRelativeLinks =>
      DocumentProvider.of(context).analysis.hasRelativeLinks;

  // Android 4.4 and earlier doesn't have APIs to get directory info
  bool? canResolveRelativeLinks;

  bool get _askForDirectoryPermissions =>
      _viewSettings.localLinksPolicy == LocalLinksPolicy.ask &&
      _hasRelativeLinks == true &&
      canResolveRelativeLinks == true &&
      _dataSource.needsToResolveParent;

  void _showMissingEncryptionKeySnackBar(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarMessageNeedsEncryptionKey,
          ),
          action: SnackBarAction(
            label: AppLocalizations.of(
              context,
            )!.snackbarActionEnterEncryptionKey.toUpperCase(),
            onPressed: () async {
              final password = await showDialog<String>(
                context: context,
                builder: (context) => InputPasswordDialog(
                  title: AppLocalizations.of(
                    context,
                  )!.inputEncryptionPasswordDialogTitle,
                ),
              );
              if (password == null || !context.mounted) return;
              final docProvider = DocumentProvider.of(context);
              final passwords = docProvider.addPasswords([
                (password: password, predicate: (_) => true),
              ]);
              if (_dirty.value) {
                _onDocChanged(docProvider.doc, docProvider.analysis, passwords);
              }
            },
          ),
        ),
      );

  void _onListItemTap(OrgListItem item) {
    final replacement = item.toggleCheckbox();
    var newTree = _doc.editNode(item)!.replace(replacement).commit() as OrgTree;
    newTree = recalculateListStats(newTree, replacement);
    updateDocument(newTree);
  }

  bool? get _hasRemoteImages =>
      DocumentProvider.of(context).analysis.hasRemoteImages;

  bool get _askPermissionToLoadRemoteImages =>
      _viewSettings.remoteImagesPolicy == RemoteImagesPolicy.ask &&
      _hasRemoteImages == true &&
      !_askForDirectoryPermissions;

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

  Future<bool> updateDocument(OrgTree newDoc, {bool dirty = true}) async {
    final (pushed, analysis) = await DocumentProvider.of(
      context,
    ).pushDoc(newDoc);
    if (pushed && dirty) {
      await _onDocChanged(newDoc, analysis);
    }
    return pushed;
  }

  Future<void> _undo() async {
    final (doc, analysis) = DocumentProvider.of(context).undo();
    await _onDocChanged(doc, analysis);
  }

  Future<void> _redo() async {
    final (doc, analysis) = DocumentProvider.of(context).redo();
    await _onDocChanged(doc, analysis);
  }

  Future<void> _onDocChanged(
    OrgTree doc,
    DocumentAnalysis analysis, [
    List<OrgroPassword>? passwords,
  ]) async {
    _dirty.value = true;
    final docProvider = DocumentProvider.of(context);
    final source = docProvider.dataSource;
    passwords ??= docProvider.passwords;
    if (analysis.needsEncryption == true &&
        doc.missingEncryptionKey(passwords)) {
      _showMissingEncryptionKeySnackBar(context);
      return;
    }
    final doWrite =
        _viewSettings.saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource &&
        doc is OrgDocument;
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(seconds: 3), () {
      _writeFuture = time('save', () async {
        try {
          debugPrint('starting auto save');
          final serializer = OrgroSerializer.get(analysis, passwords!);
          final markup = await serialize(doc, serializer);
          try {
            // Because of the timer delay this can be called when the bucket is
            // not available, so we conditionally access the bucket.
            //
            // "Some platforms restrict the size of the restoration data", and
            // the markup is potentially large, thus the try-catch. See:
            // https://api.flutter.dev/flutter/services/RestorationManager-class.html
            bucket?.write(kRestoreDirtyDocumentKey, markup);
          } catch (e, s) {
            logError(e, s);
          }
          if (doWrite) {
            await time('write', () => source.write(markup));
            if (mounted) {
              showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.savedMessage,
              );
            }
            bucket?.remove<String>(kRestoreDirtyDocumentKey);
            _dirty.value = false;
          }
        } on Exception catch (e, s) {
          logError(e, s);
          if (mounted) showErrorSnackBar(context, e);
        }
      }).whenComplete(() => _writeFuture = null);
    });
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

    if (!mounted) return;

    final docProvider = DocumentProvider.of(context);
    var passwords = docProvider.passwords;
    if (docProvider.analysis.needsEncryption == true &&
        doc.missingEncryptionKey(passwords)) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => InputPasswordDialog(
          title: AppLocalizations.of(
            context,
          )!.inputEncryptionPasswordDialogTitle,
          bodyText: AppLocalizations.of(
            context,
          )!.inputEncryptionPasswordDialogBody,
        ),
      );
      if (!mounted) return;
      if (password == null) {
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => const DiscardChangesDialog(),
        );
        if (discard == true) {
          navigator.pop();
        }
        return;
      } else {
        passwords = docProvider.addPasswords([
          (password: password, predicate: (_) => true),
        ]);
      }
    }

    if (!mounted) return;

    final serializer = OrgroSerializer.get(docProvider.analysis, passwords);

    if (saveChangesPolicy == SaveChangesPolicy.allow &&
        _canSaveChanges &&
        source is NativeDataSource) {
      debugPrint('synchronously saving now');
      _writeTimer?.cancel();
      final markup = await serializeWithProgressUI(context, doc, serializer);
      if (markup == null) return;
      await time('write', () => source.write(markup));
      navigator.pop();
      return;
    }

    final isScratchDocument =
        source is AssetDataSource && source.key == LocalAssets.scratch;

    // Prompt to save or share
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveChangesDialog(
        doc: doc,
        serializer: serializer,
        message: isScratchDocument
            ? null
            : AppLocalizations.of(context)!.saveChangesDialogMessage,
      ),
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

  bool? get _hasAgendaEntries =>
      DocumentProvider.of(context).analysis.hasAgendaEntries;

  bool get _askAboutAgendaNotifications =>
      _viewSettings.agendaNotificationsPolicy ==
          AgendaNotificationsPolicy.ask &&
      canBeAgendaFile &&
      !isAgendaFile &&
      _hasAgendaEntries == true &&
      !_askForDirectoryPermissions &&
      !_askPermissionToLoadRemoteImages &&
      !_askPermissionToSaveChanges &&
      !_askToDecrypt;
}
