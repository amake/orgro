import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:native_state/native_state.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/preferences.dart';

const _kRestoreOrgControllerStateKey = 'restore_org_controller_state';

Future<bool> loadHttpUrl(BuildContext context, String url) async {
  final title = Uri.parse(url).pathSegments.last;
  final content = time(
    'load url',
    () => http.get(url).then(
      (response) {
        if (response.statusCode == 200) {
          return response.body;
        } else {
          throw Exception();
        }
      },
      onError: _httpError,
    ),
  );
  return loadDocument(context, OpenFileInfo(null, title, content));
}

bool _httpError(Object e, StackTrace s) {
  debugPrint(e.toString());
  debugPrint(s.toString());
  return false;
}

Future<bool> loadAsset(BuildContext context, String key) async {
  final content = rootBundle.loadString(key);
  final file = File(key);
  final title = file.uri.pathSegments.last;
  return loadDocument(context, OpenFileInfo(null, title, content));
}

Future<bool> loadDocument(
  BuildContext context,
  FutureOr<OpenFileInfo> fileInfo, {
  FutureOr<dynamic> Function() onClose,
}) {
  // Create the future here so that it is not recreated on every build; this way
  // the result won't be recomputed e.g. on hot reload
  final parsed = Future.value(fileInfo).then((info) {
    if (info != null) {
      return info.toParsed();
    } else {
      // There was no fileーthe user canceled so close the route. We wait until
      // here to know if the user canceled because when the user doesn't cancel
      // it is expensive to resolve the opened file.
      Navigator.pop(context);
      return Future.value(null);
    }
  });
  final push =
      Navigator.push<void>(context, _buildDocumentRoute(context, parsed))
        ..whenComplete(() => _clearOrgState(context));
  if (onClose != null) {
    push.whenComplete(onClose);
  }
  return parsed.then((value) => value != null);
}

PageRoute _buildDocumentRoute(
  BuildContext context,
  Future<ParsedOrgFileInfo> parsed,
) {
  return MaterialPageRoute<void>(
    builder: (context) => FutureBuilder<ParsedOrgFileInfo>(
      future: parsed,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _DocumentPageWrapper(
            doc: snapshot.data.doc,
            title: snapshot.data.title,
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
    @required this.doc,
    @required this.title,
    Key key,
  })  : assert(doc != null),
        assert(title != null),
        super(key: key);

  final OrgDocument doc;
  final String title;

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context);
    return OrgController(
      root: doc,
      initialState: _restoreOrgState(context),
      stateListener: (state) => _saveOrgState(context, state),
      hideMarkup: prefs.readerMode,
      child: DocumentPage(
        title: title,
        child: OrgDocumentWidget(doc, shrinkWrap: true),
        textScale: prefs.textScale,
        fontFamily: prefs.fontFamily,
        readerMode: prefs.readerMode,
      ),
    );
  }
}

Map<String, dynamic> _restoreOrgState(BuildContext context) {
  final state =
      SavedState.of(context).getString(_kRestoreOrgControllerStateKey);
  if (state != null) {
    return json.decode(state) as Map<String, dynamic>;
  } else {
    return null;
  }
}

void _saveOrgState(BuildContext context, Map<String, dynamic> state) {
  final string = json.encode(state);
  SavedState.of(context).putString(_kRestoreOrgControllerStateKey, string);
}

void _clearOrgState(BuildContext context) =>
    SavedState.of(context).remove(_kRestoreOrgControllerStateKey);

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
            shrinkWrap: true,
          ),
        ),
      ),
    ),
  );
}
