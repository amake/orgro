import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda/agenda.dart~';
import 'package:orgro/src/preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsListItems extends StatefulWidget {
  const NotificationsListItems({super.key});

  @override
  State<NotificationsListItems> createState() => _NotificationsListItemsState();
}

class _NotificationsListItemsState extends State<NotificationsListItems> {
  List<PendingNotificationRequest>? _pendingNotifications;
  bool? _permissionsGranted;
  late final Timer _reloadTimer;

  InheritedPreferences _prefs([PrefsAspect aspect = .agenda]) =>
      Preferences.of(context, aspect);

  @override
  void initState() {
    super.initState();
    _load();
    _reloadTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _reloadTimer.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final pending = await FlutterLocalNotificationsPlugin()
        .pendingNotificationRequests();
    final permissionsGranted = await checkNotificationPermissions();
    setState(() {
      _pendingNotifications = pending;
      _permissionsGranted = permissionsGranted;
    });
  }

  bool get _hasNotifications =>
      _pendingNotifications != null && _pendingNotifications!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final agendaPromptEnabled = _prefs().agendaPromptPolicy != .deny;
    final developerMode = _prefs(.customization).developerMode;
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            AppLocalizations.of(context)!.settingsItemEnableAgendaPrompts,
          ),
          value: agendaPromptEnabled,
          onChanged: (value) async {
            if (value == null) return;
            await _prefs().setAgendaPromptPolicy(switch (value) {
              true => .ask,
              false => .deny,
            });
            await _load();
          },
        ),
        if (_permissionsGranted == false)
          ListTile(
            title: Text(
              AppLocalizations.of(context)!
                  .settingsItemGrantNotificationPermissions,
            ),
            onTap: () async {
              await _prefs().setAgendaOSNotificationsEnabled(true);
              final granted = await requestNotificationPermissions();
              if (!granted) {
                AppSettings.openAppSettings(type: .notification);
              }
              await _load();
            },
          ),
        CheckboxListTile(
          title: Text(
            AppLocalizations.of(context)!.settingsItemEnableAgendaNotifications,
          ),
          enabled: _permissionsGranted == true,
          value: _prefs().agendaOSNotificationsEnabled,
          onChanged: (value) async {
            switch (value) {
              case true:
                final localizations = AppLocalizations.of(context)!;
                final accessibleDirs = _prefs(.accessibleDirs)
                    .data
                    .accessibleDirs;
                await _prefs().setAgendaOSNotificationsEnabled(true);
                await setNotificationsForAllAgendaDocuments(
                  _prefs().agendaFileJsons,
                  localizations,
                  accessibleDirs,
                );
              case false:
                await _prefs().setAgendaOSNotificationsEnabled(false);
                await clearAllNotifications();
              case null:
            }
          },
        ),
        if (_permissionsGranted == true && developerMode)
          ListTile(
            title: Text(
              _pendingNotifications == null
                  ? AppLocalizations.of(context)!.settingsItemLoading
                  : AppLocalizations.of(context)!
                        .settingsItemInspectNotifications(
                          _pendingNotifications!.length,
                        ),
            ),
            onTap: _hasNotifications
                ? () {
                    final notifications =
                        _pendingNotifications!.map((e) => e.toInfo()).toList()
                          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
                    showDialog<void>(
                      context: context,
                      builder: (context) =>
                          _PendingNotificationsDialog(notifications),
                    );
                  }
                : null,
          ),
        if (_hasNotifications && developerMode)
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsItemClearNotifications,
            ),
            onTap: () async {
              await clearAllNotifications();
              await _load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!
                          .snackbarMessageNotificationsCleared,
                    ),
                  ),
                );
              }
            },
          ),
        if (_prefs().agendaFileJsons.isNotEmpty)
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsItemClearAgenda),
            onTap: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => _ClearAgendaFilesDialog(),
              );
              if (result != true) return;
              await _prefs().clearAgendaFileJsons();
              await clearAllNotifications();
              await _load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!
                          .snackbarMessageAgendaCleared,
                    ),
                  ),
                );
              }
            },
          ),
      ],
    );
  }
}

class _PendingNotificationsDialog extends StatelessWidget {
  const _PendingNotificationsDialog(this.notifications);

  final List<_PendingNotificationInfo> notifications;

  @override
  Widget build(BuildContext context) {
    final iconSize = 16.0;
    final iconColor = Theme.of(context).hintColor;
    final locale = AppLocalizations.of(context)!.localeName;
    final dateTimeFormat = DateFormat.yMd(locale).add_jm();
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.settingsDialogNotificationsTitle,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(notification.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        size: iconSize,
                        color: iconColor,
                      ),
                      Text(notification.body),
                    ],
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      Icon(Icons.access_time, size: iconSize, color: iconColor),
                      Text(dateTimeFormat.format(notification.dateTime)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

typedef _PendingNotificationInfo = ({
  tz.TZDateTime dateTime,
  String title,
  String body,
});

extension _PendingNotificationRequestUtil on PendingNotificationRequest {
  _PendingNotificationInfo toInfo() {
    final decoded = json.decode(payload!);
    final dateTime = switch (decoded) {
      {
        'scheduledAt': final String scheduledAt,
        'timezone': final String timezone,
      } =>
        tz.TZDateTime.from(
          DateTime.parse(scheduledAt),
          tz.getLocation(timezone),
        ),
      _ => throw UnimplementedError('Unknown notification payload: $decoded'),
    };
    return (dateTime: dateTime, title: title!, body: body!);
  }
}

class _ClearAgendaFilesDialog extends StatelessWidget {
  const _ClearAgendaFilesDialog();

  @override
  Widget build(BuildContext context) {
    final agendaFileJsons = Preferences.of(
      context,
      .agenda,
    ).data.agendaFileJsons;
    return AlertDialog(
      icon: const Icon(Icons.warning, applyTextScaling: true),
      title: Text(AppLocalizations.of(context)!.confirmClearAgendaDialogTitle),
      content: SizedBox(
        width: .maxFinite,
        child: Column(
          spacing: 16,
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              AppLocalizations.of(context)!
                  .confirmClearAgendaDialogMessage(agendaFileJsons.length),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final elem in agendaFileJsons) Text('• ${elem['name']}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.confirmClearAgendaActionClear
                .toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () => Navigator.of(context).pop(true),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.confirmClearAgendaActionCancel
                .toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
