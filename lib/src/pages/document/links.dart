import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/native_search.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:url_launcher/url_launcher.dart';

extension LinkHandler on DocumentPageState {
  Future<bool> openLink(OrgLink link) async {
    final doc = DocumentProvider.of(context).doc;
    try {
      final fileLink = convertLinkResolvingAttachments(doc, link);
      return _openFileLink(fileLink);
    } on Exception {
      // Wasn't a file link
    }

    if (isOrgIdUrl(link.location)) {
      return await _openExternalIdLink(link.location);
    }

    // Handle as a general URL
    try {
      debugPrint('Launching URL: ${link.location}');
      final handled = await launchUrl(Uri.parse(link.location),
          mode: LaunchMode.externalApplication);
      if (!handled && mounted) {
        showErrorSnackBar(context,
            AppLocalizations.of(context)!.errorLinkNotHandled(link.location));
      }
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
    return false;
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
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final targetId = parseOrgIdUrl(url);
    final requestId = Object().hashCode.toString();

    var canceled = false;
    time(
      'find file with ID',
      () => findFileForId(
        requestId: requestId,
        orgId: targetId,
        dirIdentifier: dataSource.rootDirIdentifier!,
      ),
    ).then((found) {
      if (!canceled && mounted) Navigator.pop(context, (found, true));
    }).onError((error, stackTrace) {
      if (mounted) showErrorSnackBar(context, error);
      logError(error, stackTrace);
      if (!canceled && mounted) Navigator.pop(context);
    });

    final result = await showDialog<(NativeDataSource?, bool)>(
      context: context,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
        dismissable: true,
      ),
    );

    if (result == null) {
      canceled = true;
      cancelFindFileForId(requestId: requestId);
      return false;
    }
    if (!mounted) return false;

    final (foundFile, searchCompleted) = result;
    assert(searchCompleted);
    if (foundFile == null) {
      showErrorSnackBar(context,
          AppLocalizations.of(context)!.errorExternalIdNotFound(targetId));
      return false;
    } else {
      return await loadDocument(context, foundFile, target: url);
    }
  }

  Future<bool> _openFileLink(OrgFileLink link) async {
    if (!link.isRelative || !link.body.endsWith('.org')) {
      return false;
    }
    final source = DocumentProvider.of(context).dataSource;
    if (source.needsToResolveParent) {
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      ),
    );

    try {
      final resolved = await source.resolveRelative(link.body);
      if (mounted) {
        Navigator.pop(context);
        return await loadDocument(context, resolved, target: link.extra);
      }
    } on Exception catch (e, s) {
      logError(e, s);
      if (mounted) {
        Navigator.pop(context);
        showErrorSnackBar(context, e);
      }
    }
    return false;
  }

  void _showDirectoryPermissionsSnackBar(BuildContext context) =>
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
