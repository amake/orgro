import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/pages/editor.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/serialization.dart';

Future<bool> loadHttpUrl(BuildContext context, Uri uri) =>
    loadDocument(context, WebDataSource(uri));

Future<bool> loadAsset(BuildContext context, String key) =>
    loadDocument(context, AssetDataSource(key));

Future<bool> loadDocument(
  BuildContext context,
  FutureOr<DataSource?> dataSource, {
  FutureOr<dynamic> Function()? onClose,
  String? target,
  InitialMode? mode,
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
      if (context.mounted) Navigator.pop(context);
      return Future.value(null);
    }
  });
  final push = Navigator.push<void>(
    context,
    _buildDocumentRoute(context, parsed, target, mode),
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
  InitialMode? mode,
) {
  return MaterialPageRoute<void>(
    builder: (context) => FutureBuilder<ParsedOrgFileInfo?>(
      future: parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DocumentProvider(
            dataSource: snapshot.data!.dataSource,
            doc: snapshot.data!.doc,
            child: _DocumentPageWrapper(
              layer: 0,
              target: target,
              initialMode: mode,
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
    required this.layer,
    required this.target,
    this.initialMode,
  });

  final int layer;
  final String? target;
  final InitialMode? initialMode;

  @override
  Widget build(BuildContext context) {
    final docProvider = DocumentProvider.of(context);
    final dataSource = docProvider.dataSource;
    return RootRestorationScope(
      restorationId: 'org_page_root:${dataSource.id}',
      child: ViewSettings.defaults(
        context,
        // Get ViewSettings into the context
        child: Builder(
          builder: (context) {
            final viewSettings = ViewSettings.of(context);
            return OrgController(
              root: docProvider.doc,
              settings: viewSettings.readerMode
                  ? OrgSettings.hideMarkup
                  : const OrgSettings(),
              interpretEmbeddedSettings: true,
              searchQuery: _searchPattern(viewSettings.queryString),
              sparseQuery: _sparseQuery(viewSettings.filterData),
              // errorHandler is invoked during build, so we need to schedule the
              // snack bar for after the frame
              errorHandler: (e) => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => showErrorSnackBar(context, OrgroError.from(e))),
              restorationId: 'org_page:${dataSource.id}',
              child: DocumentPage(
                layer: layer,
                title: dataSource.name,
                initialTarget: target,
                initialMode: initialMode,
                root: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

Pattern? _searchPattern(String? queryString) => queryString == null
    ? null
    : RegExp(
        RegExp.escape(queryString),
        unicode: true,
        caseSensitive: false,
      );

OrgQueryMatcher? _sparseQuery(FilterData filterData) {
  if (filterData.isEmpty) {
    return null;
  }
  return OrgQueryAndMatcher([
    if (filterData.customFilter.isNotEmpty)
      OrgQueryMatcher.fromMarkup(filterData.customFilter),
    ...filterData.keywords.map((value) =>
        OrgQueryPropertyMatcher(property: 'TODO', operator: '=', value: value)),
    ...filterData.tags.map((value) => OrgQueryTagMatcher(value)),
    ...filterData.priorities.map((value) => OrgQueryPropertyMatcher(
        property: 'PRIORITY', operator: '=', value: value)),
  ]);
}

Future<OrgTree?> narrow(
  BuildContext context,
  DataSource dataSource,
  OrgTree section,
  int layer,
) async {
  final viewSettings = ViewSettings.of(context);
  final orgController = OrgController.of(context);
  final bucket = RestorationScope.of(context);
  OrgTree? result;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (context) => UnmanagedRestorationScope(
        bucket: bucket,
        child: DocumentProvider(
          doc: section,
          dataSource: dataSource,
          onDocChanged: (doc) => result = doc,
          child: ViewSettings(
            data: viewSettings.data,
            child: Builder(builder: (context) {
              final viewSettings = ViewSettings.of(context);
              return OrgController.defaults(
                orgController,
                // Continue to use the true document root so that links to sections
                // outside the narrowed section can be resolved
                root: orgController.root,
                settings: viewSettings.readerMode
                    ? OrgSettings.hideMarkup
                    : const OrgSettings(),
                searchQuery: _searchPattern(viewSettings.queryString),
                sparseQuery: _sparseQuery(viewSettings.filterData),
                restorationId: 'org_narrow_$layer:${dataSource.id}',
                child: DocumentPage(
                  layer: layer,
                  title: AppLocalizations.of(context)!
                      .pageTitleNarrow(dataSource.name),
                  initialQuery: viewSettings.queryString,
                  initialFilter: viewSettings.filterData,
                  root: false,
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
  return result;
}

Future<void> showInteractive(
    BuildContext context, String title, Widget child) async {
  return await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (builder) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: InteractiveViewer(child: Center(child: child)),
      ),
    ),
  );
}

Future<OrgTree?> showTextEditor(
  BuildContext context,
  DataSource dataSource,
  OrgTree tree, {
  required int layer,
  required bool requestFocus,
}) async {
  final viewSettings = ViewSettings.of(context).data;
  final text = tree.toMarkup(serializer: OrgroPlaintextSerializer());
  final result = await Navigator.push<String?>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (builder) => RootRestorationScope(
        restorationId: 'org_editor_$layer:${dataSource.id}',
        child: ViewSettings(
          data: viewSettings,
          child: EditorPage(
            text: text,
            title:
                AppLocalizations.of(context)!.pageTitleEditing(dataSource.name),
            requestFocus: requestFocus,
          ),
        ),
      ),
    ),
  );

  return result == null ? null : await parse(result);
}
