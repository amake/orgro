import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

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
  return content.then((_) => true, onError: _httpError);
}

bool _httpError(Object e, StackTrace s) {
  debugPrint(e.toString());
  debugPrint(s.toString());
  return false;
}

Future<bool> loadFileUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  return loadPath(context, uri.toFilePath());
}

Future<bool> loadPath(BuildContext context, String path) async {
  final file = File(path);
  final title = file.uri.pathSegments.last;
  return loadFile(context, file, title);
}

Future<bool> loadFile(BuildContext context, File file, String title) {
  final content = time('read file', file.readAsString);
  loadDocument(context, title, content);
  return content.then((_) => true);
}

Future<bool> loadAsset(BuildContext context, String key) async {
  final content = rootBundle.loadString(key);
  final file = File(key);
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
            return _buildDocumentPage(context, snapshot.data, title);
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

Widget _buildDocumentPage(BuildContext context, OrgDocument doc, String title) {
  return FutureBuilder<Preferences>(
    future: Preferences.getInstance(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final prefs = snapshot.data;
        return OrgController(
          root: doc,
          hideMarkup: prefs.readerMode,
          child: DocumentPage(
            title: title,
            child: OrgDocumentWidget(doc),
            textScale: prefs.textScale,
            fontFamily: prefs.fontFamily,
            readerMode: prefs.readerMode,
          ),
        );
      } else if (snapshot.hasError) {
        return ErrorPage(error: snapshot.error.toString());
      } else {
        return const ProgressPage();
      }
    },
  );
}

Future<OrgDocument> parse(String content) async =>
    time('parse', () => compute(_parse, content));

OrgDocument _parse(String text) => OrgDocument.parse(text);

void narrow(BuildContext context, String title, OrgSection section) {
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
        child: DocumentPage.defaults(
          viewSettings,
          title: '$title › narrow',
          child: OrgSectionWidget(
            section,
            root: true,
          ),
        ),
      ),
    ),
  );
}
