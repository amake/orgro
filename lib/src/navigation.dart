import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/pages/pages.dart';

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
            dataSource: snapshot.data!.dataSource,
            doc: snapshot.data!.doc,
            child: _DocumentPageWrapper(
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
    required this.target,
  });

  final String? target;

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
          builder: (context) => OrgController(
            root: docProvider.doc,
            settings: ViewSettings.of(context).readerMode
                ? OrgSettings.hideMarkup
                : const OrgSettings(),
            interpretEmbeddedSettings: true,
            // errorHandler is invoked during build, so we need to schedule the
            // snack bar for after the frame
            errorHandler: (e) => WidgetsBinding.instance.addPostFrameCallback(
                (_) => showErrorSnackBar(context, OrgroError.from(e))),
            restorationId: 'org_page:${dataSource.id}',
            child: DocumentPage(
              title: dataSource.name,
              initialTarget: target,
            ),
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
        dataSource: dataSource,
        child: ViewSettings(
          data: viewSettings.data,
          child: Builder(builder: (context) {
            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) async {
                if (didPop) return;
                Navigator.pop(context, DocumentProvider.of(context).doc);
              },
              child: OrgController.defaults(
                orgController,
                // Continue to use the true document root so that links to sections
                // outside the narrowed section can be resolved
                root: orgController.root,
                settings: ViewSettings.of(context).readerMode
                    ? OrgSettings.hideMarkup
                    : const OrgSettings(),
                child: DocumentPage(
                  title: AppLocalizations.of(context)!
                      .pageTitleNarrow(dataSource.name),
                  initialQuery: viewSettings.queryString,
                ),
              ),
            );
          }),
        ),
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
