import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

Future<bool> loadHttpUrl(BuildContext context, Uri uri) =>
    loadDocument(context, WebDataSource(uri));

Future<bool> loadAsset(BuildContext context, String key) =>
    loadDocument(context, AssetDataSource(key));

Future<bool> loadDocument(
  BuildContext context,
  FutureOr<DataSource?> dataSource, {
  FutureOr<dynamic> Function()? onClose,
  String? target,
}) {
  // Create the future here so that it is not recreated on every build; this way
  // the result won't be recomputed e.g. on hot reload
  final parsed = Future.value(dataSource).then((source) {
    if (source != null) {
      return ParsedOrgFileInfo.from(source);
    } else {
      // There was no fileーthe user canceled so close the route. We wait until
      // here to know if the user canceled because when the user doesn't cancel
      // it is expensive to resolve the opened file.
      Navigator.pop(context);
      return Future.value(null);
    }
  });
  final push = Navigator.push<void>(
    context,
    _buildDocumentRoute(context, parsed, target),
  );
  if (onClose != null) {
    push.whenComplete(onClose);
  }
  return parsed.then((value) => value != null);
}

PageRoute<void> _buildDocumentRoute(
  BuildContext context,
  Future<ParsedOrgFileInfo?> parsed,
  String? target,
) {
  return MaterialPageRoute<void>(
    builder: (context) => FutureBuilder<ParsedOrgFileInfo?>(
      future: parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DocumentProvider(
            doc: snapshot.data!.doc,
            child: _DocumentPageWrapper(
              dataSource: snapshot.data!.dataSource,
              target: target,
            ),
          );
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return const ProgressPage();
        }
      },
    ),
    fullscreenDialog: true,
  );
}

class _DocumentPageWrapper extends StatelessWidget {
  const _DocumentPageWrapper({
    required this.dataSource,
    required this.target,
  });

  final DataSource dataSource;
  final String? target;

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context);
    return RootRestorationScope(
      restorationId: 'org_page_root:${dataSource.id}',
      child: OrgController(
        root: DocumentProvider.of(context)!.doc,
        hideMarkup: prefs.readerMode,
        restorationId: 'org_page:${dataSource.id}',
        child: ViewSettings.defaults(
          context,
          child: DocumentPage(
            title: dataSource.name,
            dataSource: dataSource,
            initialTarget: target,
          ),
        ),
      ),
    );
  }
}

Future<OrgSection?> narrow(
    BuildContext context, DataSource dataSource, OrgSection section) {
  final viewSettings = ViewSettings.of(context);
  final orgController = OrgController.of(context);
  return Navigator.push<OrgSection>(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentProvider(
        doc: section,
        child: Builder(builder: (context) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              Navigator.pop(context, DocumentProvider.of(context)!.doc);
            },
            child: OrgController.defaults(
              orgController,
              // Continue to use the true document root so that links to sections
              // outside the narrowed section can be resolved
              root: orgController.root,
              child: ViewSettings(
                data: viewSettings,
                child: DocumentPage(
                  title: AppLocalizations.of(context)!
                      .pageTitleNarrow(dataSource.name),
                  dataSource: dataSource,
                  initialQuery: viewSettings.queryString,
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

void showInteractive(BuildContext context, String title, Widget child) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (builder) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: InteractiveViewer(child: Center(child: child)),
      ),
    ),
  );
}

const _kMaxUndoStackSize = 10;

class DocumentProvider extends StatefulWidget {
  static DocumentProviderData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocumentProviderData>();

  const DocumentProvider({required this.doc, required this.child, super.key});

  final OrgTree doc;
  final Widget child;

  @override
  State<DocumentProvider> createState() => _DocumentProviderState();
}

class _DocumentProviderState extends State<DocumentProvider> {
  List<OrgTree> _docs = [];
  late int _cursor;

  @override
  void initState() {
    _docs = [widget.doc];
    _cursor = 0;
    super.initState();
  }

  void _pushDoc(OrgTree doc) {
    setState(() {
      _docs = [
        // +2 is because we keep the doc at _cursor and the new doc, so the
        // total will be _kMaxUndoStackSize.
        ..._docs.sublist(max(0, _cursor - _kMaxUndoStackSize + 2), _cursor + 1),
        doc
      ];
      _cursor = _docs.length - 1;
    });
  }

  bool get _canUndo => _cursor >= 1;

  OrgTree _undo() {
    if (!_canUndo) throw Exception("can't undo");
    final newCursor = _cursor - 1;
    setState(() => _cursor = newCursor);
    return _docs[newCursor];
  }

  bool get _canRedo => _cursor < _docs.length - 1;

  OrgTree _redo() {
    if (!_canRedo) throw Exception("can't redo");
    final newCursor = _cursor + 1;
    setState(() => _cursor = newCursor);
    return _docs[newCursor];
  }

  @override
  Widget build(BuildContext context) {
    return DocumentProviderData(
      doc: _docs[_cursor],
      pushDoc: _pushDoc,
      undo: _undo,
      redo: _redo,
      canUndo: _canUndo,
      canRedo: _canRedo,
      child: widget.child,
    );
  }
}

class DocumentProviderData extends InheritedWidget {
  const DocumentProviderData({
    required this.doc,
    required this.pushDoc,
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
    required super.child,
    super.key,
  });

  final OrgTree doc;
  final void Function(OrgTree) pushDoc;
  final OrgTree Function() undo;
  final OrgTree Function() redo;
  final bool canUndo;
  final bool canRedo;

  @override
  bool updateShouldNotify(DocumentProviderData oldWidget) =>
      doc != oldWidget.doc;
}
