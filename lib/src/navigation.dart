import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';

Future<bool> loadHttpUrl(BuildContext context, String url) async {
  final title = Uri.parse(url).pathSegments.last;
  final content = time(
    'load url',
    () => http.get(url).then((response) {
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception();
      }
    }),
  );
  loadDocument(context, title, content);
  return content.then((_) => true, onError: () => false);
}

Future<bool> loadFileUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  return loadPath(context, uri.toFilePath());
}

Future<bool> loadPath(BuildContext context, String path) async {
  final file = File(path);
  final content = time('read file', file.readAsString);
  final title = file.uri.pathSegments.last;
  loadDocument(context, title, content);
  return content.then((_) => true);
}

void loadDocument(BuildContext context, String title, Future<String> content) {
  // Create the future here so that it is not recreated on every build; this way
  // the result won't be recomputed e.g. on hot reload
  final parsed = content.then(parse, onError: logError);
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (context) => FutureBuilder<OrgDocument>(
        future: parsed,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return OrgController(
              root: snapshot.data,
              child: DocumentPage(
                title: title,
                child: OrgDocumentWidget(snapshot.data),
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
    ),
  );
}

Future<OrgDocument> parse(String content) async =>
    time('parse', () => compute(_parse, content));

OrgDocument _parse(String text) => OrgDocument.parse(text);

void narrow(BuildContext context, String title, OrgSection section) {
  final textScale = ViewSettings.of(context).textScale;
  // Continue to use the true document root so that links to sections outside
  // the narrowed section can be resolved
  final parent = OrgController.of(context).root;
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (context) => OrgController(
        root: parent,
        child: DocumentPage(
          title: '$title › narrow',
          child: OrgSectionWidget(
            section,
            initiallyOpen: true,
          ),
          textScale: textScale,
        ),
      ),
    ),
  );
}
