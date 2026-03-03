import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/native_search.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/pages/document/links.dart';

extension TransclusionHandler on DocumentPageState {
  Widget loadTransclusion(OrgMeta meta) {
    final (node: link, path: _) = meta.find<OrgLink>((_) => true)!;

    final doc = DocumentProvider.of(context).doc;

    final level = doc.findContainingTree(meta)!.level;

    try {
      final fileLink = convertLinkResolvingAttachments(context, doc, link);
      return Transclusion(
        widget.metadata.layer,
        level,
        fileLink,
        meta,
        key: ValueKey(meta.toMarkup()),
      );
    } on Exception {
      // Wasn't a file link
      return _TransclusionError(
        message: AppLocalizations.of(
          context,
        )!.errorUnsupportedLinkType(link.location),
      );
    }
  }
}

class Transclusion extends StatefulWidget {
  const Transclusion(
    this.layer,
    this.level,
    this.fileLink,
    this.meta, {
    super.key,
  });

  final int layer;
  final int level;
  final OrgFileLink fileLink;
  final OrgMeta meta;

  @override
  State<Transclusion> createState() => _TransclusionState();
}

class _TransclusionState extends State<Transclusion> {
  DataSource? _dataSource;
  String? _findFileRequestId;
  Widget? _child;

  @override
  void dispose() {
    if (_findFileRequestId != null) {
      cancelFindFileForId(requestId: _findFileRequestId!).onError((e, s) {
        logError(e, s);
        return false;
      });
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dataSource = DocumentProvider.of(context).dataSource;
    if (dataSource != _dataSource) {
      _dataSource = dataSource;
      _child = null;
    }

    if (_child == null) {
      _resolveFileLink(widget.fileLink).then((child) {
        if (mounted) setState(() => _child = child);
      });
    }
  }

  Future<Widget> _resolveExternalIdLink(OrgFileLink fileLink) async {
    assert(fileLink.scheme == 'id:');

    final dataSource = _dataSource;
    final localizations = AppLocalizations.of(context)!;

    if (dataSource is! NativeDataSource) {
      return _TransclusionError(
        message: localizations.errorUnsupportedDataSource(
          dataSource.runtimeType,
        ),
      );
    }

    if (dataSource.needsToResolveParent) {
      return const _DirectoryPermissionsDisclosure();
    }

    _findFileRequestId = Object().hashCode.toString();

    final targetId = fileLink.body;
    final foundFile = await time(
      'find file with ID',
      () => findFileForId(
        requestId: _findFileRequestId!,
        orgId: targetId,
        dirIdentifier: dataSource.rootDirIdentifier!,
      ),
    );

    if (foundFile == null) {
      return _TransclusionError(
        message: localizations.errorExternalIdNotFound(targetId),
      );
    }
    return _TranscludedContent(
      widget.layer,
      widget.level,
      foundFile,
      fileLink.toString(),
      widget.meta,
    );
  }

  Future<Widget> _resolveFileLink(OrgFileLink fileLink) async {
    if (fileLink.scheme == 'id:') {
      // An internal ID link within the current document would have been handled
      // within org_flutter, so it must be external.
      return await _resolveExternalIdLink(fileLink);
    }

    if (!fileLink.isRelative) {
      return _TransclusionError(
        message: AppLocalizations.of(
          context,
        )!.errorUnsupportedLinkType(fileLink.body),
      );
    }

    final dataSource = _dataSource!;

    if (dataSource.needsToResolveParent) {
      return const _DirectoryPermissionsDisclosure();
    }

    try {
      final resolved = await dataSource.resolveRelative(fileLink.body);
      return _TranscludedContent(
        widget.layer,
        widget.level,
        resolved,
        fileLink.extra,
        widget.meta,
      );
    } catch (e, s) {
      logError(e, s);
      return _TransclusionError(message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _child ??
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        );
  }
}

class _TransclusionError extends StatelessWidget {
  const _TransclusionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      titleAlignment: .center,
      leading: const Icon(Icons.error),
      title: Text(message),
    );
  }
}

class _TranscludedContent extends StatefulWidget {
  const _TranscludedContent(
    this.layer,
    this.level,
    this.dataSource,
    this.target,
    this.meta,
  );

  final int layer;
  final int level;
  final DataSource dataSource;
  final String? target;
  final OrgMeta meta;

  @override
  State<_TranscludedContent> createState() => _TranscludedContentState();
}

class _TranscludedContentState extends State<_TranscludedContent> {
  late Future<(OrgTree, Plist)> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<(OrgTree, Plist)> _load() async {
    final content = await widget.dataSource.content;
    final params = Plist.from(widget.meta.value!.toMarkup());
    final src = params.get(':src');
    final lines = params.get(':lines');
    final trimmedContent = extractLines(content, lines);
    if (src != null) {
      final doc = OrgDocument(
        OrgContent([
          OrgSrcBlock(
            src,
            '',
            '#+begin_src :src $src',
            OrgPlainText(trimmedContent),
            '#+end_src',
            '\n',
          ),
        ]),
        null,
      );
      return (doc, params);
    }
    OrgTree doc = await parse(content);
    if (widget.target != null) {
      try {
        final target = doc.sectionForTarget(widget.target!);
        if (target != null) doc = target;
      } catch (e, s) {
        logError(e, s);
      }
    }
    // TODO(aaron): Support targeting named elements, dedicated targets, etc.
    final hasLevel = params.has(':level');
    if (hasLevel) {
      final rawLevel = params.get(':level') ?? 'auto';
      final level = rawLevel == 'auto'
          ? widget.level + 1
          : int.tryParse(rawLevel);
      if (level != null) {
        doc = applyLevel(doc, level);
      }
    }
    return (doc, params);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _TransclusionError(message: snapshot.error.toString());
        }
        final (doc, params) = snapshot.requireData;
        final events = OrgEvents.of(context);
        final theme = OrgTheme.of(context);
        final viewSettings = ViewSettings.of(context);
        return OrgEvents(
          // TODO(aaron): If not for the desire to adjust event handling, this
          // entire widget could live in org_flutter
          onLinkTap: events.onLinkTap,
          onLocalSectionLinkTap: (tree, {searchOption}) =>
              doNarrow(context, tree, searchOption: searchOption),
          onSectionLongPress: (section) => doNarrow(context, section),
          onCitationTap: events.onCitationTap,
          loadImage: events.loadImage,
          // Don't allow editing
          //
          // TODO(aaron): It would be nice to allow excluding just specific events
          // instead of having to specify all of them
          onSectionSlide: null,
          onListItemTap: null,
          onTimestampTap: null,
          // Don't allow nested transclusion
          loadTransclusion: null,
          child: OrgTheme(
            dark: theme.dark.copyWith(rootPadding: EdgeInsets.zero),
            light: theme.light.copyWith(rootPadding: EdgeInsets.zero),
            child: OrgController(
              root: doc,
              settings: _settings(params),
              interpretEmbeddedSettings: true,
              searchQuery: viewSettings.searchQuery.asPattern(),
              sparseQuery: viewSettings.filterData.asSparseQuery(),
              errorHandler: (e) => WidgetsBinding.instance.addPostFrameCallback(
                (_) => showErrorSnackBar(context, OrgroError.from(e)),
              ),
              child: switch (doc) {
                OrgDocument() => OrgDocumentWidget(
                  doc,
                  shrinkWrap: true,
                  safeArea: false,
                ),
                OrgSection() => OrgSectionWidget(
                  doc,
                  shrinkWrap: true,
                  root: true,
                ),
                _ => throw UnimplementedError(
                  'Unexpected document type: ${doc.runtimeType}',
                ),
              },
            ),
          ),
        );
      },
    );
  }

  OrgSettings _settings(Plist params) {
    final excluded =
        params.get(':exclude-elements')?.split(RegExp(r'\s+')) ?? [];
    if (params.has(':only-contents')) {
      excluded.add('headline');
    }
    if (!excluded.contains('property-drawer')) {
      excluded.add('property-drawer');
    }
    return OrgSettings(
      hiddenElements: excluded,
      startupFolded: OrgVisibilityState.subtree,
    );
  }

  Future<void> doNarrow(
    BuildContext context,
    OrgTree section, {
    String? searchOption,
  }) async {
    final docProvider = DocumentProvider.of(context);
    final doc = docProvider.doc;
    if (section == doc) {
      debugPrint('Suppressing narrow to currently open document');
      return;
    }
    await narrow(
      context,
      widget.dataSource,
      section,
      searchOption,
      widget.layer + 1,
      true,
    );
  }
}

class _DirectoryPermissionsDisclosure extends StatelessWidget {
  const _DirectoryPermissionsDisclosure();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.link),
      titleAlignment: .center,
      title: Text(AppLocalizations.of(context)!.transclusionPermissionsMessage),
      trailing: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
        ),
        onPressed: () => doPickDirectory(context),
        child: Text(
          AppLocalizations.of(context)!.bannerBodyActionGrantNow.toUpperCase(),
        ),
      ),
    );
  }
}

String extractLines(String content, String? linesParam) {
  if (linesParam == null) return content;
  final lineNumbers = linesParam
      .split('-')
      .map((s) => int.tryParse(s.trim()))
      .toList(growable: false);
  if (lineNumbers.length != 2) return content;

  final minLine = lineNumbers[0] ?? 1;
  final maxLine = lineNumbers[1] ?? -1;

  // Return everything if the parameters are invalid
  if (minLine <= 0 && maxLine < 0) return content;
  if (minLine > 0 && maxLine >= 0 && maxLine < minLine) return content;

  var start = 0, end = content.length, line = 1, i = 0;
  do {
    if (line == minLine) {
      start = i;
      if (maxLine < 0) break;
    }
    if (line == maxLine + 1) {
      end = i;
      break;
    }
    i = content.indexOf('\n', i);
    if (i == -1) break;
    i++; // Move past the line break
    line++;
  } while (i >= 0 && i < content.length);

  if (line < minLine) return '\n';

  return content.substring(start, end);
}

OrgTree applyLevel(OrgTree doc, int level) {
  if (level < 1 || level > 9) return doc;

  OrgSection applyToSection(OrgSection section) {
    final delta = level - section.level;
    if (delta == 0) return section;

    (bool, OrgZipper?) visitor(OrgZipper location) {
      if (location.node is OrgHeadline) {
        final node = location.node as OrgHeadline;
        location = location.replace(
          node.copyWith(
            stars: (
              value: '*' * (node.stars.value.length + delta),
              trailing: node.stars.trailing,
            ),
          ),
        );
      }
      return (true, location);
    }

    return section.edit().visit(visitor).commit<OrgSection>();
  }

  return switch (doc) {
    OrgDocument() => doc.copyWith(
      sections: doc.sections.map(applyToSection).toList(growable: false),
    ),
    OrgSection() => applyToSection(doc),
    _ => throw UnimplementedError(
      'Unexpected document type: ${doc.runtimeType}',
    ),
  };
}
