import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
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

  Future<void> enableNotifications() async {
    if (!await checkNotificationPermissions()) {
      final granted = await requestNotificationPermissions();
      if (!granted) {
        if (mounted) _complainAboutDenied(context);
        debugPrint('User denied notification permissions');
        return;
      }
    }
    setAgendaFile();
  }

  void setAgendaFile() => Preferences.of(
    context,
    PrefsAspect.agenda,
  ).addAgendaFileJson(_dataSource.toJson());

  void setNotifications() => _setNotifications(context);
}

void _complainAboutDenied(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(
          context,
        )!.snackbarMessageNeedsNotificationsPermissions,
      ),
      action: SnackBarAction(
        label: AppLocalizations.of(
          context,
        )!.snackbarActionGrantNotificationsPermissions.toUpperCase(),
        onPressed: () async {
          if (!await requestNotificationPermissions()) {
            AppSettings.openAppSettings(type: AppSettingsType.notification);
          }
        },
      ),
    ),
  );
}

final _setNotifications = debounce1((BuildContext context) async {
  if (!await checkNotificationPermissions()) {
    debugPrint('No permission for notifications');
    if (context.mounted) _complainAboutDenied(context);
    return;
  }

  if (!context.mounted) return;

  final dataSource = DocumentProvider.of(context).dataSource;
  final doc = DocumentProvider.of(context).doc;
  final localizations = AppLocalizations.of(context)!;

  try {
    await setNotificationsForDocument((dataSource, doc, localizations));
  } catch (e, s) {
    logError(e, s);
    if (context.mounted) {
      showErrorSnackBar(context, localizations.errorSchedulingNotifications(e));
    }
  }

  // TODO(aaron): Show a confirmation snackbar with a summary? That would be
  // nice on the first run for a file, but annoying on updates (which may be
  // frequent)
}, Duration(milliseconds: 300));
