import 'package:flutter/widgets.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

extension AgendaHandler on DocumentPageState {
  DataSource get _dataSource => DocumentProvider.of(context).dataSource;

  bool get canBeAgendaFile => switch (_dataSource) {
    NativeDataSource(persistable: true) => true,
    _ => false,
  };

  bool get isAgendaFile => switch (_dataSource) {
    NativeDataSource(persistable: true, uri: final uri) => Preferences.of(
      context,
      PrefsAspect.agenda,
    ).agendaFileJsons.any((e) => e['uri'] == uri),
    _ => false,
  };

  void setAgendaFile() => Preferences.of(
    context,
    PrefsAspect.agenda,
  ).addAgendaFileJson(_dataSource.toJson());

  Future<void> setNotifications() => _setNotifications(context);
}

final _setNotifications = sequentially((BuildContext context) async {
  if (!await checkNotificationPermissions()) {
    debugPrint('No permission for notifications');
    if (context.mounted) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(
          context,
        )!.snackbarMessageNotificationPermissionsDenied,
      );
    }
    return;
  }

  if (!context.mounted) return;

  final dataSource = DocumentProvider.of(context).dataSource;
  final doc = DocumentProvider.of(context).doc;
  final localizations = AppLocalizations.of(context)!;

  await setNotificationsForDocument(dataSource, doc, localizations);
  // TODO(aaron): Show a confirmation snackbar with a summary? That would be
  // nice on the first run for a file, but annoying on updates (which may be
  // frequent)
});
