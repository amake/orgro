import 'package:flutter/foundation.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/preferences.dart';

extension AgendaHandler on DocumentPageState {
  String get _docId => DocumentProvider.of(context).dataSource.id;

  bool get isAgendaFile => Preferences.of(
    context,
    PrefsAspect.agenda,
  ).agendaFileIds.contains(_docId);

  void setAgendaFile() =>
      Preferences.of(context, PrefsAspect.agenda).addAgendaFileId(_docId);

  Future<void> setNotifications() async {
    if (!await checkNotificationPermissions()) {
      debugPrint('No permission for notifications');
      if (mounted) {
        showErrorSnackBar(
          context,
          AppLocalizations.of(
            context,
          )!.snackbarMessageNotificationPermissionsDenied,
        );
      }
      return;
    }

    if (!mounted) return;

    final dataSource = DocumentProvider.of(context).dataSource;
    final doc = DocumentProvider.of(context).doc;

    await setNotificationsForDocument(dataSource, doc);
    // TODO(aaron): Show a confirmation snackbar with a summary? That would be
    // nice on the first run for a file, but annoying on updates (which may be
    // frequent)

    // TODO(aaron): Also periodically update notifications in the background;
    // https://pub.dev/packages/flutter_background_service
    // https://pub.dev/packages/background_fetch
    // https://pub.dev/packages/workmanager
    //
    // and also on launch because background tasks are rarely run?

    // TODO(aaron): Add a control to the Settings screen to clear all
    // notifications (and agenda files?)
  }
}
