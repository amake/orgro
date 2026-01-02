import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/start/util.dart';

const kOrgProtocolSchemes = [
  'org-protocol-debug',
  'org-protocol-profile',
  'org-protocol',
];

bool isCaptureUri(Uri uri) => kOrgProtocolSchemes.contains(uri.scheme);

bool isValidCapturePayload(Uri uri) {
  if (!kOrgProtocolSchemes.contains(uri.scheme)) return false;
  if (uri.host.toLowerCase() != 'capture') return false;
  if (!uri.hasQuery) return false;
  if (!uri.queryParameters.keys.any(
    (key) => ['url', 'title', 'body'].contains(key.toLowerCase()),
  )) {
    return false;
  }
  return true;
}

enum CaptureTarget { clipboard, scratch, document }

Future<void> captureUri(BuildContext context, Uri uri) async {
  if (!isValidCapturePayload(uri)) {
    debugPrint('Invalid capture URI: $uri');
    showErrorSnackBar(
      context,
      AppLocalizations.of(context)!.snackbarMessageInvalidCaptureUri,
    );
    return;
  }
  final rememberedFiles = RememberedFiles.of(context);
  final files = [...rememberedFiles.pinned, ...rememberedFiles.recents];
  final result = await showDialog<(CaptureTarget, RememberedFile?)>(
    context: context,
    builder: (context) => CaptureTargetDialog(
      title: AppLocalizations.of(context)!.captureToDialogTitle,
      files: files,
    ),
  );
  switch (result) {
    case null:
      break;
    case (CaptureTarget.clipboard, _):
      final (newDoc, _) = captureUriToSection(OrgDocument(null, []), uri);
      await Clipboard.setData(ClipboardData(text: newDoc.toMarkup()));
    case (CaptureTarget.scratch, _):
      if (!context.mounted) return;
      await loadAndRememberAsset(
        context,
        LocalAssets.scratch,
        afterOpen: (state) => captureToDocument(state, uri),
      );
    case (CaptureTarget.document, final captureTo!):
      if (!context.mounted) return;
      await loadAndRememberFile(
        context,
        readFileWithIdentifier(captureTo.identifier),
        afterOpen: (state) => captureToDocument(state, uri),
      );
  }
}

void captureToDocument(DocumentPageState state, Uri uri) {
  final doc = DocumentProvider.of(state.context).doc;
  // We are assuming we are capturing into a document, not a subtree.
  if (doc is! OrgDocument) return;

  final (newDoc, newSection) = captureUriToSection(doc, uri);
  state.updateDocument(newDoc);
  OrgController.of(state.context).ensureVisible([newSection]);
  // TODO(aaron): Consider scrolling specifically to new section instead (with
  // highlight flash?)
  scrollToBottom(state.context);
}

(OrgTree, OrgSection) captureUriToSection(
  OrgDocument doc,
  Uri uri, [
  DateTime? now,
]) {
  now ??= DateTime.now();
  final capturedMessage = OrgContent([
    OrgPlainText('Captured On: '),
    OrgSimpleTimestamp('[', now.toOrgDate(), now.toOrgTime(), [], ']'),
  ]);

  final params = uri.queryParameters;
  final url = params['url'];
  final haveUrl = url != null && url.isNotEmpty;
  final title = params['title'];
  final haveTitle = title != null && title.isNotEmpty;
  final body = params['body'];
  final haveBody = body != null && body.isNotEmpty;

  // TODO(aaron): Maybe don't linkify the URL in the title because it's hard
  // to open and close the headline without accidentally opening the link
  final header = haveUrl && haveTitle
      ? OrgContent([
          OrgBracketLink(url, OrgContent([OrgPlainText(title)])),
        ])
      : haveUrl
      ? OrgContent([OrgBracketLink(url, null)])
      : haveTitle
      ? OrgContent([OrgPlainText(title)])
      : capturedMessage;

  final newSection = OrgSection(
    OrgHeadline(
      (value: '*', trailing: ' '),
      null,
      null,
      header,
      header.toMarkup(),
      null,
      haveUrl || haveTitle ? '\n' : '\n\n',
    ),
    OrgContent([
      if (haveUrl || haveTitle)
        OrgParagraph('  ', capturedMessage, haveBody ? '\n\n' : '\n'),
      if (haveBody) OrgParagraph('  ', OrgContent([OrgPlainText(body)]), '\n'),
    ]),
  );
  OrgTree newDoc;
  if (doc.sections.isEmpty) {
    newDoc = doc.copyWith(sections: [newSection]);
  } else {
    final [...sections, lastSection] = doc.sections;
    newDoc = doc.copyWith(
      sections: [...sections, lastSection.ensureTrailingNewLine(), newSection],
    );
  }
  return (newDoc, newSection);
}
