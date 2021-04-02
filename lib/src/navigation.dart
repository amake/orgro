import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  final push =
      Navigator.push<void>(context, _buildDocumentRoute(context, parsed));
  if (onClose != null) {
    push.whenComplete(onClose);
  }
  return parsed.then((value) => value != null);
}

PageRoute _buildDocumentRoute(
  BuildContext context,
  Future<ParsedOrgFileInfo?> parsed,
) {
  return MaterialPageRoute<void>(
    builder: (context) => FutureBuilder<ParsedOrgFileInfo?>(
      future: parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _DocumentPageWrapper(
            doc: snapshot.data!.doc,
            dataSource: snapshot.data!.dataSource,
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
    required this.doc,
    required this.dataSource,
    Key? key,
  }) : super(key: key);

  final OrgDocument doc;
  final DataSource dataSource;

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context);
    return RootRestorationScope(
      restorationId: 'org_page_root',
      child: OrgController(
        root: doc,
        hideMarkup: prefs.readerMode,
        restorationId: 'org_page',
        child: ViewSettings.defaults(
          context,
          child: DocumentPage(
            doc: doc,
            title: dataSource.name,
            dataSource: dataSource,
            child: OrgDocumentWidget(doc, shrinkWrap: true),
          ),
        ),
      ),
    );
  }
}

void narrow(BuildContext context, DataSource dataSource, OrgSection section) {
  final viewSettings = ViewSettings.of(context);
  final orgController = OrgController.of(context);
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (context) => OrgController.defaults(
        orgController,
        // Continue to use the true document root so that links to sections
        // outside the narrowed section can be resolved
        root: orgController.root,
        child: ViewSettings(
          data: viewSettings,
          child: DocumentPage(
            doc: section,
            title: '${dataSource.name} › narrow',
            dataSource: dataSource,
            initialQuery: viewSettings.queryString,
            child: OrgSectionWidget(
              section,
              root: true,
              shrinkWrap: true,
            ),
          ),
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
