import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:open_file/open_file.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/native_search.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/util.dart';
import 'package:url_launcher/url_launcher.dart';

extension LinkHandler on DocumentPageState {
  Future<bool> openLink(OrgLink link) async {
    final doc = DocumentProvider.of(context).doc;

    OrgFileLink? fileLink = _tryParseFileLink(doc, link);
    if (fileLink != null) return await _openFileLink(fileLink);

    if (isOrgIdUrl(link.location)) {
      return await _openExternalIdLink(link.location);
    }

    final handled = await _openLocalFallbackTargets(doc, link.location);
    if (handled) return true;

    // Handle as a general URL
    try {
      final url = expandAbbreviatedUrl(doc, link) ?? Uri.parse(link.location);
      debugPrint('Launching URL: $url');
      final handled =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!handled && mounted) {
        showErrorSnackBar(
            context, AppLocalizations.of(context)!.errorLinkNotHandled(url));
      }
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
    return false;
  }

  OrgFileLink? _tryParseFileLink(OrgTree doc, OrgLink link) {
    try {
      return convertLinkResolvingAttachments(doc, link);
    } on Exception {
      // Wasn't a file link
      return null;
    }
  }

  Future<bool> _openExternalIdLink(String url) async {
    assert(isOrgIdUrl(url));

    final dataSource = DocumentProvider.of(context).dataSource;
    if (dataSource is! NativeDataSource) {
      debugPrint('Unsupported data source: ${dataSource.runtimeType}');
      showErrorSnackBar(
          context, AppLocalizations.of(context)!.errorLinkNotHandled(url));
      return false;
    }

    if (dataSource.needsToResolveParent) {
      showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final targetId = parseOrgIdUrl(url);
    final requestId = Object().hashCode.toString();

    final (:succeeded, result: foundFile) = await cancelableProgressTask(
      context,
      task: time(
        'find file with ID',
        () => findFileForId(
          requestId: requestId,
          orgId: targetId,
          dirIdentifier: dataSource.rootDirIdentifier!,
        ),
      ),
      dialogTitle: AppLocalizations.of(context)!.searchingProgressDialogTitle,
    );

    if (!succeeded) {
      cancelFindFileForId(requestId: requestId);
      return false;
    }

    if (!mounted) return false;

    if (foundFile == null) {
      showErrorSnackBar(context,
          AppLocalizations.of(context)!.errorExternalIdNotFound(targetId));
      return false;
    } else {
      return await loadDocument(context, foundFile, target: url);
    }
  }

  Future<bool> _openFileLink(OrgFileLink link) async {
    if (!link.isRelative) return false;

    final source = DocumentProvider.of(context).dataSource;
    if (source.needsToResolveParent) {
      showDirectoryPermissionsSnackBar(context);
      return false;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      ),
    );

    var popped = false;

    try {
      final resolved = await source.resolveRelative(link.body);
      if (mounted) {
        Navigator.pop(context);
        popped = true;
        if (link.body.endsWith('.org')) {
          return await loadDocument(context, resolved, target: link.extra);
        } else {
          return await _openFileInExternalApp(resolved);
        }
      }
    } catch (e, s) {
      logError(e, s);
      if (mounted) {
        if (!popped) Navigator.pop(context);
        showErrorSnackBar(context, e);
      }
    }
    return false;
  }

  Future<bool> _openLocalFallbackTargets(OrgTree doc, String target) async {
    final locator = OrgLocator.of(context)!;
    if (await locator.jumpToLinkTarget(target)) return true;
    if (await locator.jumpToName(target)) return true;
    return false;
  }

  Future<bool> _openFileInExternalApp(DataSource source) async {
    final tmp = await getTemporaryAttachmentsDirectory();
    final tmpFile =
        tmp.uri.resolveUri(Uri(path: '${source.id.hashCode}/${source.name}'));
    await File.fromUri(tmpFile).parent.create(recursive: true);
    await source.copyTo(tmpFile);
    final result = await OpenFile.open(tmpFile.toFilePath());
    debugPrint('OpenFile result: ${result.message}; type: ${result.type}');
    final context = this.context;
    if (result.type != ResultType.done && context.mounted) {
      showErrorSnackBar(context, result.message);
    }
    return result.type == ResultType.done;
  }

  void showDirectoryPermissionsSnackBar(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .snackbarMessageNeedsDirectoryPermissions,
          ),
          action: canResolveRelativeLinks == true
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!
                      .snackbarActionGrantAccess
                      .toUpperCase(),
                  onPressed: doPickDirectory,
                )
              : null,
        ),
      );

  Future<void> doPickDirectory() async {
    try {
      final source = DocumentProvider.of(context).dataSource;
      if (source is! NativeDataSource) {
        return;
      }
      final dirInfo = await pickDirectory(initialDirUri: source.uri);
      if (dirInfo == null) return;
      if (!mounted) return;
      debugPrint(
          'Added accessible dir; uri: ${dirInfo.uri}; identifier: ${dirInfo.identifier}');
      await DocumentProvider.of(context).addAccessibleDir(dirInfo.identifier);
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }
}

Uri? expandAbbreviatedUrl(OrgTree doc, OrgLink link) {
  // Uri.parse can fail on a link that might otherwise succeed after expanding
  // abbreviations, so don't unconditionally try to parse the raw link.location.

  final colonIdx = link.location.indexOf(':');
  if (colonIdx == -1) return null;

  final linkword = link.location.substring(0, colonIdx);
  final tag = link.location.substring(colonIdx + 1);

  final abbreviations = extractLinkAbbreviations(doc);
  if (abbreviations.isEmpty) return null;

  final String format;
  try {
    (linkword: _, :format) =
        abbreviations.firstWhere((abbr) => abbr.linkword == linkword);
  } on StateError {
    return null;
  }

  final formatted = format.contains('%s')
      ? format.replaceFirst('%s', tag)
      : format.contains('%h')
          ? format.replaceFirst('%h', Uri.encodeComponent(tag))
          : '$format$tag';
  return Uri.tryParse(formatted);
}

final _abbreviationPattern =
    RegExp(r'^(?<linkword>"[^"]+"|\S+)\s+(?<format>\S+)$');
typedef LinkAbbreviation = ({String linkword, String format});

List<LinkAbbreviation> extractLinkAbbreviations(
  OrgTree tree,
) {
  final results = <LinkAbbreviation>[];
  tree.visit<OrgMeta>((meta) {
    if (meta.keyword.toLowerCase() == '#+link:') {
      final trailing = meta.trailing.trim();
      final match = _abbreviationPattern.firstMatch(trailing);
      if (match == null) return true;
      final linkword = match.namedGroup('linkword')!.trimPrefSuff('"', '"');
      final format = match.namedGroup('format')!;
      results.add((linkword: linkword, format: format));
    }
    return true;
  });
  return results;
}
