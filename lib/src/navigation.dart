import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/main.dart';
import 'package:orgro/src/debug.dart';

Future<bool> loadUrl(BuildContext context, String url) async {
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
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FutureBuilder<OrgDocument>(
        future: content.then(parse, onError: logError),
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

OrgDocument _parse(String text) => OrgDocument(text);

void narrow(BuildContext context, String title, OrgSection section) {
  final textScale = MediaQuery.textScaleFactorOf(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrgController(
        root: section,
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
