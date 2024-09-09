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
import 'package:orgro/src/preferences.dart';
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
      // TODO(aaron): report unsupported data source type to user
      return false;
    }

    if (dataSource.needsToResolveParent) {
      _showDirectoryPermissionsSnackBar(context);
      return false;
    }

    final targetId = parseOrgIdUrl(url);

    final accessibleDirs = Preferences.of(context).accessibleDirs;

    // TODO(aaron): Find a way to make this operation cancelable
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressIndicatorDialog(
        title: AppLocalizations.of(context)!.searchingProgressDialogTitle,
      ),
    );

    try {
      // TODO(aaron): Search accessible dir that contains this document first
      for (final dir in accessibleDirs) {
        final foundFile = await findFileForId(id: targetId, dirIdentifier: dir);
        if (foundFile != null && mounted) {
          Navigator.pop(context);
          return await loadDocument(context, foundFile, target: url);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        showErrorSnackBar(context,
            AppLocalizations.of(context)!.errorExternalIdNotFound(targetId));
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
