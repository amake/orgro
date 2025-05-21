import 'dart:async';

import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/pages/editor.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/routes/narrow.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/src/serialization.dart';

Future<void> loadHttpUrl(BuildContext context, Uri uri) => Navigator.pushNamed(
  context,
  Routes.document,
  arguments: DocumentRouteArgs(dataSource: WebDataSource(uri)),
);

Future<void> loadAsset(BuildContext context, String key, {InitialMode? mode}) =>
    Navigator.pushNamed(
      context,
      Routes.document,
      arguments: DocumentRouteArgs(
        dataSource: AssetDataSource(key),
        mode: mode,
      ),
    );

Future<void> loadDocument(
  BuildContext context,
  DataSource dataSource, {
  String? target,
  InitialMode? mode,
}) => Navigator.pushNamed(
  context,
  Routes.document,
  arguments: DocumentRouteArgs(
    dataSource: dataSource,
    target: target,
    mode: mode,
  ),
);

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
  await Navigator.pushNamed(
    context,
    Routes.narrow,
    arguments: NarrowRouteArgs(
      dataSource: dataSource,
      section: section,
      layer: layer,
      viewSettings: viewSettings,
      orgController: orgController,
      bucket: bucket,
      onDocChanged: (doc) => result = doc,
    ),
  );
  return result;
}

Future<void> showInteractive(
  BuildContext context,
  String title,
  Widget child,
) async {
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
            docId: dataSource.id,
            text: text,
            title: AppLocalizations.of(
              context,
            )!.pageTitleEditing(dataSource.name),
            requestFocus: requestFocus,
          ),
        ),
      ),
    ),
  );

  return result == null ? null : await parse(result);
}
