import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/image.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/native_search.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/pages/document/narrow.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';
import 'package:url_launcher/url_launcher.dart';

extension LinkHandler on DocumentPageState {
  Future<bool> openLink(OrgLink link) async {
    final doc = DocumentProvider.of(context).doc;

    OrgFileLink? fileLink = _tryParseFileLink(doc, link);
    if (fileLink != null) return await _openFileLink(link, fileLink);

    if (looksLikeImagePath(link.location)) {
      final data = Uri.tryParse(link.location)?.data;
      final widget = data != null ? DataImage(link, data) : RemoteImage(link);
      await showInteractive(context, link.location, widget);
      return true;
    }

    try {
      final url = expandAbbreviatedUrl(doc, link) ?? Uri.parse(link.location);

      {
        final handled = await _openOrgDocLink(url);
        if (handled) return true;
      }

      // Handle as a general URL
      debugPrint('Launching URL: $url');
      final handled = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (handled) return true;
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(context)!.errorLinkNotHandled(url),
        );
      }
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
    return false;
  }

  OrgFileLink? _tryParseFileLink(OrgTree doc, OrgLink link) {
    try {
      return convertLinkResolvingAttachments(context, doc, link);
    } on Exception {
      // Wasn't a file link
      return null;
    }
  }

  Future<bool> _openExternalIdLink(OrgFileLink fileLink) async {
    assert(fileLink.scheme == 'id:');

    final dataSource = DocumentProvider.of(context).dataSource;
    if (dataSource is! NativeDataSource) {
      debugPrint('Unsupported data source: ${dataSource.runtimeType}');
      showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.errorLinkNotHandled(fileLink.toString()),
      );
      return false;
    }

    if (dataSource.needsToResolveParent) {
      showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final targetId = fileLink.body;
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
      await cancelFindFileForId(requestId: requestId);
      return false;
    }

    if (!mounted) return false;

    if (foundFile == null) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.errorExternalIdNotFound(targetId),
      );
      return false;
    } else {
      await loadDocument(context, foundFile, target: fileLink.toString());
      return true;
    }
  }

  Future<bool> _openFileLink(OrgLink link, OrgFileLink fileLink) async {
    if (fileLink.scheme == 'id:') {
      // An internal ID link within the current document would have been handled
      // within org_flutter, so it must be external.
      return await _openExternalIdLink(fileLink);
    }

    if (!fileLink.isRelative) return false;

    final source = DocumentProvider.of(context).dataSource;
    if (source.needsToResolveParent) {
      showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final (:succeeded, result: resolved!) = await progressTask(
      context,
      dialogTitle: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      task: source.resolveRelative(fileLink.body),
    );

    if (!succeeded) return false;

    try {
      if (mounted) {
        if (fileLink.body.endsWith('.org')) {
          await loadDocument(context, resolved, target: fileLink.extra);
          return true;
        } else if (looksLikeImagePath(fileLink.body)) {
          await showInteractive(
            context,
            fileLink.body,
            LocalImage(
              link: link,
              dataSource: source,
              relativePath: fileLink.body,
            ),
          );
          return true;
        } else {
          return await _openFileInExternalApp(resolved);
        }
      }
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
    return false;
  }

  Future<bool> _openFileInExternalApp(DataSource source) async {
    final tmp = await getTemporaryAttachmentsDirectory();
    final tmpFile = tmp.uri.resolveUri(
      Uri(path: '${source.id.hashCode}/${source.name}'),
    );
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
            AppLocalizations.of(
              context,
            )!.snackbarMessageNeedsDirectoryPermissions,
          ),
          action: canResolveRelativeLinks == true
              ? SnackBarAction(
                  label: AppLocalizations.of(
                    context,
                  )!.snackbarActionGrantAccess.toUpperCase(),
                  onPressed: () => doPickDirectory(context),
                )
              : null,
        ),
      );

  // Try to figure out if the URL is to an Org document
  Future<bool> _openOrgDocLink(Uri url) async {
    // Org Social "mentions" are URLs with `org-social` scheme
    // https://github.com/tanrax/org-social#mentions
    final cleanUrl = url.scheme.toLowerCase() == 'org-social'
        ? Uri.parse(url.toString().substring('org-social:'.length))
        : url;

    final docProvider = DocumentProvider.of(context);
    final dataSource = docProvider.dataSource;
    if (dataSource is WebDataSource && cleanUrl.sameDocument(dataSource.uri)) {
      // If the URL has a fragment, it is probably an Org Social link to a post.
      if (cleanUrl.hasFragment) {
        // ID takes precedence over headline
        // https://github.com/tanrax/org-social#post-metadata
        final section =
            docProvider.doc.sectionForTarget('id:${cleanUrl.fragment}') ??
            docProvider.doc.sectionForTarget('*${cleanUrl.fragment}');
        if (section != null) {
          await doNarrow(section);
          return true;
        }
      }
      // We are in the same document, so don't re-open it
      debugPrint('Suppressing opening link to same document');
      return true;
    }

    // Check original URL so we can recognize org-social scheme to avoid
    // unnecessary HTTP request
    if (!await looksLikeOrgLink(url)) return false;
    if (!mounted) return false;

    await loadHttpUrl(context, cleanUrl);
    return true;
  }
}

Future<void> doPickDirectory(BuildContext context) async {
  try {
    final source = DocumentProvider.of(context).dataSource;
    if (source is! NativeDataSource) {
      return;
    }
    final dirInfo = await pickDirectory(initialDirUri: source.uri);
    if (dirInfo == null) return;
    if (!context.mounted) return;
    debugPrint(
      'Added accessible dir; uri: ${dirInfo.uri}; identifier: ${dirInfo.identifier}',
    );
    await Preferences.of(
      context,
      PrefsAspect.nil,
    ).addAccessibleDir(dirInfo.identifier);
  } catch (e, s) {
    logError(e, s);
    if (context.mounted) showErrorSnackBar(context, e);
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
    (linkword: _, :format) = abbreviations.firstWhere(
      (abbr) => abbr.linkword == linkword,
    );
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

final _abbreviationPattern = RegExp(
  r'^(?<linkword>"[^"]+"|\S+)\s+(?<format>\S+)$',
);
typedef LinkAbbreviation = ({String linkword, String format});

List<LinkAbbreviation> extractLinkAbbreviations(OrgTree tree) {
  final results = <LinkAbbreviation>[];
  tree.visit<OrgMeta>((meta) {
    if (meta.key.toLowerCase() == '#+link:' && meta.value != null) {
      final trailing = meta.value!.toMarkup().trim();
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

Future<bool> looksLikeOrgLink(Uri url) async {
  if (url.scheme.toLowerCase() == 'org-social') return true;
  if (url.path.toLowerCase().endsWith('.org')) return true;

  final client = http.Client();
  try {
    final res = await client.head(url);
    if (res.statusCode != 200) return false;
    final contentType = res.headers['content-type']?.toLowerCase();
    if (contentType == null) return false;
    // Very few servers seem to serve Org files with the correct MIME type, so
    // be lenient
    if (contentType.startsWith('text/org')) return true;
    if (contentType.startsWith('text/plain')) return true;
    // Many servers serve Org files with this MIME type. If the URL path ended
    // with .org then we would have already returned true, so check that the
    // path doesn't look like it has a file extension for a different type of
    // file.
    if (contentType.startsWith('application/octet-stream') &&
        url.pathSegments.lastOrNull?.contains('.') != true) {
      return true;
    }
  } catch (e) {
    debugPrint('Error checking URL headers: $e');
  } finally {
    client.close();
  }
  return false;
}
