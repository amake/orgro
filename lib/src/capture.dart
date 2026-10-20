import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/start/remembered_files.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';

const _kOrgProtocolSchemes = [
  'org-protocol-debug',
  'org-protocol-profile',
  'org-protocol',
];

bool isCaptureUri(Uri uri) => _kOrgProtocolSchemes.contains(uri.scheme);

bool isValidCapturePayload(Uri uri) {
  if (!_kOrgProtocolSchemes.contains(uri.scheme)) return false;
  if (uri.host.toLowerCase() != 'capture') return false;
  if (!uri.hasQuery) return false;
  if (!uri.queryParameters.keys.any(
    (key) => ['url', 'title', 'body'].contains(key.toLowerCase()),
  )) {
    return false;
  }
  return true;
}

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
  final files = [
    ...rememberedFiles.pinned,
    ...rememberedFiles.recents,
  ].where((f) => !f.isWebUri).toList(growable: false);
  final result = await showDialog<(_CaptureTarget, dynamic)>(
    context: context,
    builder: (context) => _CaptureTargetDialog(files: files),
  );
  switch (result) {
    case null:
      break;
    case (.clipboard, _):
      final (newDoc, _) = captureUriToSection(OrgDocument(null, []), uri);
      await Clipboard.setData(ClipboardData(text: newDoc.toMarkup()));
    case (.scratch, _):
      if (!context.mounted) return;
      await loadAndRememberAsset(
        context,
        LocalAssets.scratch,
        afterOpen: (state) => captureToDocument(state, uri),
      );
    case (.openDocument, final NativeDataSource dataSource):
      if (!context.mounted) return;
      await loadAndRememberFile(
        context,
        dataSource,
        afterOpen: (state) => captureToDocument(state, uri),
      );
    case (.rememberedDocument, final RememberedFile captureTo):
      if (!context.mounted) return;
      final accessibleDirs = Preferences.of(
        context,
        .accessibleDirs,
      ).data.accessibleDirs;
      final (
        :dataSource,
        :recovered,
      ) = await readFileWithIdentifierWithRecoveryStrategy(
        identifier: captureTo.identifier,
        fileName: captureTo.name,
        accessibleDirs: accessibleDirs,
      );
      if (recovered) {
        await loadAndReplaceRememberedFile(
          context,
          captureTo.identifier,
          dataSource,
          afterOpen: (state) => captureToDocument(state, uri),
        );
      } else {
        await loadAndRememberFile(
          context,
          dataSource,
          afterOpen: (state) => captureToDocument(state, uri),
        );
      }
  }
}

enum _CaptureTarget {
  clipboard,
  scratch,
  openDocument,
  // This must come last because it represents a variable number of items in the
  // dialog
  rememberedDocument;

  static _CaptureTarget forDialogIdx(int idx) =>
      idx >= _CaptureTarget.rememberedDocument.index
      ? _CaptureTarget.rememberedDocument
      : _CaptureTarget.values[idx];

  static int rememberedDocIdxFromDialogIdx(int docIdx) =>
      docIdx - _CaptureTarget.rememberedDocument.index;
}

class _CaptureTargetDialog extends StatelessWidget {
  const _CaptureTargetDialog({required this.files});

  final List<RememberedFile> files;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.captureToDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, idx) {
            switch (_CaptureTarget.forDialogIdx(idx)) {
              case .clipboard:
                return ListTile(
                  leading: const Icon(Icons.copy, applyTextScaling: true),
                  title: Text(
                    AppLocalizations.of(context)!.captureToClipboardItem,
                  ),
                  onTap: () =>
                      Navigator.pop(context, (_CaptureTarget.clipboard, null)),
                );
              case .scratch:
                return ListTile(
                  leading: const Icon(Icons.add, applyTextScaling: true),
                  title: Text(
                    AppLocalizations.of(context)!.captureToNewDocumentItem,
                  ),
                  onTap: () =>
                      Navigator.pop(context, (_CaptureTarget.scratch, null)),
                );
              case .openDocument:
                return ListTile(
                  leading: const Icon(
                    Icons.folder_open,
                    applyTextScaling: true,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!
                        .captureToExistingFileToBeChosen,
                  ),
                  onTap: () async {
                    final (:result, :succeeded) = await progressTask(
                      context,
                      dialogTitle: AppLocalizations.of(context)!
                          .preparingProgressDialogTitle,
                      task: pickFile(),
                    );
                    if (result != null) {
                      Navigator.pop(context, (
                        _CaptureTarget.openDocument,
                        result,
                      ));
                    }
                  },
                );
              case .rememberedDocument:
                final file =
                    files[_CaptureTarget.rememberedDocIdxFromDialogIdx(idx)];
                return RememberedFileListTile(
                  file,
                  onTap: () => Navigator.pop(context, (
                    _CaptureTarget.rememberedDocument,
                    file,
                  )),
                );
            }
          },
          itemCount: (_CaptureTarget.values.length - 1) + files.length,
        ),
      ),
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
