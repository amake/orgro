import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/main.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
const kMaxNotifications = 64;
const kMaxNotificationId = 0x7FFFFFFF;

const kAgendaUpdateTask = 'com.madlonkay.orgro.agenda-update';

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  final currentTimeZone = await FlutterTimezone.getLocalTimezone();
  debugPrint('Current time zone: $currentTimeZone');
  tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

  final plugin = FlutterLocalNotificationsPlugin();
  const initializationSettingsAndroid = AndroidInitializationSettings(
    'ic_notification',
  );
  const initializationSettingsDarwin = DarwinInitializationSettings(
    // We request later on demand
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );
  await plugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
}

void onDidReceiveNotificationResponse(NotificationResponse details) {
  if (details.payload == null) {
    debugPrint('No payload in notification; id: ${details.id}');
    return;
  }
  final payload = json.decode(details.payload!);
  switch (payload) {
    case {'dataSource': {'type': 'native', 'identifier': final String id}}:
      final context = startKey.currentContext!;
      try {
        // TODO(aaron): Don't open if we already have it open
        loadAndRememberFile(context, readFileWithIdentifier(id));
      } on Exception catch (e, s) {
        logError(e, s);
        if (context.mounted) showErrorSnackBar(context, e);
      }
    default:
      debugPrint('Unknown notification payload: ${details.payload}');
  }
}

Future<bool> checkNotificationPermissions() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final androidImpl = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (androidImpl != null) {
    var status = await androidImpl.areNotificationsEnabled();
    if (status == true) return true;
    status = await androidImpl.requestNotificationsPermission();
    return status == true;
  }
  final iosImpl = plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
  if (iosImpl != null) {
    return await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ==
        true;
  }
  throw UnimplementedError('Unsupported platform');
}

const _kNotificationsUpdateLockfile = '.notificationsUpdate.lock';

Future<File> _getLockfile() async {
  final tmpDir = await getTemporaryDirectory();
  final lockfile = File.fromUri(
    tmpDir.uri.resolve(_kNotificationsUpdateLockfile),
  );
  return lockfile;
}

Future<void> cleanNotficationsLockfile() async {
  final lockfile = await _getLockfile();
  if (!lockfile.existsSync()) return;
  if (DateTime.now().difference(lockfile.lastModifiedSync()) <
      const Duration(hours: 1)) {
    return;
  }

  lockfile.deleteSync();
}

final setNotificationsForDocument = sequentiallyWithLockfile(_getLockfile(), (
  (DataSource, OrgTree, AppLocalizations) args,
) async {
  final (dataSource, doc, localizations) = args;
  debugPrint('Setting agenda notifications for document ${dataSource.name}');

  final plugin = FlutterLocalNotificationsPlugin();
  final pendingNotifications = <(tz.TZDateTime, PendingNotificationRequest)>[];
  for (final element in await plugin.pendingNotificationRequests()) {
    final payload = json.decode(element.payload!);
    switch (payload) {
      case {'dataSource': {'id': final id}}:
        if (id == dataSource.id) {
          // This notification is for this file; we will reschedule it below
          debugPrint('Canceling notification with ID $id (${element.id})');
          await plugin.cancel(element.id);
        }
      case {
        'scheduledAt': final String scheduledAt,
        'timezone': final String timezone,
      }:
        final dateTime = DateTime.tryParse(scheduledAt)!;
        final location = tz.getLocation(timezone);
        pendingNotifications.add((
          tz.TZDateTime.from(dateTime, location),
          element,
        ));
      default:
        throw UnimplementedError('Unknown notification payload: $payload');
    }
  }

  final toSchedule = <(tz.TZDateTime, OrgSection)>[];
  doc.visitSections((section) {
    if (section.isPending()) {
      for (final dateTime in section.scheduledAt) {
        if (dateTime.isAfter(DateTime.now())) {
          var tzDateTime = tz.TZDateTime.from(dateTime, tz.local);
          if (tzDateTime.hour == 0 && tzDateTime.minute == 0) {
            // Scheduled time is midnight. Move to 9am.
            tzDateTime = tzDateTime.add(const Duration(hours: 9));
          }
          toSchedule.add((tzDateTime, section));
        }
      }
    }
    return true;
  });

  // This is all the notifications that would be scheduled if there was no
  // limit. We will take as many from the start of this list as we can, and
  // cancel the rest.
  final allNotifications = [...pendingNotifications, ...toSchedule]
    ..sort((a, b) => a.$1.compareTo(b.$1));

  final random = Random();

  for (final (dateTime, element) in allNotifications.take(kMaxNotifications)) {
    switch (element) {
      case PendingNotificationRequest():
        // Existing notification. Keep it.
        continue;
      case OrgSection():
        // New notification. Schedule it.
        final id = random.nextInt(kMaxNotificationId);
        debugPrint(
          'Scheduling notification for $dateTime: ($id) ${element.headline.rawTitle}',
        );
        await plugin.zonedSchedule(
          id,
          element.headline.title?.toPlainText() ?? element.headline.rawTitle,
          dataSource.name,
          dateTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'com.madlonkay.orgro.agenda',
              localizations.agendaNotificationsChannelName,
              channelDescription:
                  localizations.agendaNotificationsChannelDescription,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: json.encode({
            'dataSource': dataSource.toJson(),
            'section': element.toAgendaPayloadJson(),
            'scheduledAt': dateTime.toIso8601String(),
            'timezone': tz.local.name,
          }),
        );
      default:
        throw UnimplementedError('Unknown notification element: $element');
    }
  }

  for (final (_, element) in allNotifications.skip(kMaxNotifications)) {
    switch (element) {
      case PendingNotificationRequest():
        // This notification got pushed off the end. Cancel it.
        await plugin.cancel(element.id);
      case OrgSection():
        // This notification got pushed off the end. Don't schedule it.
        continue;
      default:
        throw UnimplementedError('Unknown notification element: $element');
    }
  }
});

Future<void> setNotificationsForAllAgendaDocuments(
  List<Map<String, dynamic>> agendaFileJsons,
  AppLocalizations localizations,
) async {
  for (final elem in agendaFileJsons) {
    switch (elem) {
      case {'type': 'native', 'identifier': final String id}:
        try {
          final dataSource = await readFileWithIdentifier(id);
          final parsed = await ParsedOrgFileInfo.from(dataSource);
          await setNotificationsForDocument((
            dataSource,
            parsed.doc,
            localizations,
          ));
        } catch (e, s) {
          logError(e, s);
        }
      default:
        throw UnimplementedError('Unknown agenda file JSON: $elem');
    }
  }
}

Future<void> clearNotificationsForFiles(
  bool Function(Map<String, dynamic>) predicate,
) async {
  final plugin = FlutterLocalNotificationsPlugin();
  for (final element in await plugin.pendingNotificationRequests()) {
    final payload = json.decode(element.payload!);
    switch (payload) {
      case {'dataSource': final Map<String, dynamic> dataSource}:
        if (predicate(dataSource)) {
          debugPrint('Canceling notification with ID ${element.id}');
          await plugin.cancel(element.id);
        }
    }
  }
}

Future<void> clearAllNotifications() async =>
    await FlutterLocalNotificationsPlugin().cancelAll();

extension OrgSectionUtil on OrgSection {
  bool get isTodo => headline.keyword?.done == false;
  bool get isDone => headline.keyword?.done == true;

  List<DateTime> get scheduledAt => planning
      .where((entry) => entry.keyword.content == 'SCHEDULED:')
      .map((entry) {
        final value = entry.value;
        return switch (value) {
          OrgSimpleTimestamp() => value.dateTime,
          // TODO(aaron): Handle other kinds of timestamps, if they are valid for
          // agenda scheduling
          _ => null,
        };
      })
      .whereType<DateTime>()
      .toList(growable: false);

  bool isPending({DateTime? now}) {
    final planning = this.planning;
    if (planning.any((entry) => entry.keyword.content == 'CLOSED:')) {
      return false;
    }
    now ??= DateTime.now();
    return planning.any((entry) {
      // TODO(aaron): Is the keyword needed, or can any active timestamp do?
      if (entry.keyword.content != 'SCHEDULED:') return false;
      final value = entry.value;
      return switch (value) {
        OrgSimpleTimestamp() => value.isActive && value.dateTime.isAfter(now!),
        // TODO(aaron): Handle other kinds of timestamps, if they are valid for
        // agenda scheduling
        _ => false,
      };
    });
  }

  List<OrgPlanningEntry> get planning {
    final entries = <OrgPlanningEntry>[];
    // TODO(aaron): Are planning entries valid anywhere in the content?
    // What about mere active timestamps?
    content?.visit<OrgPlanningEntry>((entry) {
      entries.add(entry);
      return true;
    });
    return entries;
  }

  Map<String, Object?> toAgendaPayloadJson() => {
    'id': ids.firstOrNull,
    'customId': customIds.firstOrNull,
    'rawTitle': headline.rawTitle,
  };
}

class NotificationsListItems extends StatefulWidget {
  const NotificationsListItems({super.key});

  @override
  State<NotificationsListItems> createState() => _NotificationsListItemsState();
}

class _NotificationsListItemsState extends State<NotificationsListItems> {
  List<PendingNotificationRequest>? _pendingNotifications;
  late final Timer _reloadTimer;

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
    setState(() => _pendingNotifications = pending);
  }

  bool get _hasNotifications =>
      _pendingNotifications != null && _pendingNotifications!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            _pendingNotifications == null
                ? AppLocalizations.of(context)!.settingsItemLoading
                : AppLocalizations.of(
                    context,
                  )!.settingsItemInspectNotifications(
                    _pendingNotifications!.length,
                  ),
          ),
          onTap: _hasNotifications
              ? () => showDialog<void>(
                  context: context,
                  builder: (context) =>
                      _PendingNotificationsDialog(_pendingNotifications!),
                )
              : null,
        ),
        if (_hasNotifications)
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.settingsItemClearNotifications,
            ),
            onTap: () async {
              await Preferences.of(
                context,
                PrefsAspect.agenda,
              ).clearAgendaFileJsons();
              await clearAllNotifications();
              await _load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.snackbarMessageNotificationsCleared,
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

  final List<PendingNotificationRequest> notifications;

  @override
  Widget build(BuildContext context) {
    final iconSize = 16.0;
    final iconColor = Theme.of(context).hintColor;
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
            final payload = json.decode(notification.payload!);
            final dateTime = switch (payload) {
              {
                'scheduledAt': final String scheduledAt,
                'timezone': final String timezone,
              } =>
                _formatNotificationDateTime(
                  tz.TZDateTime.from(
                    DateTime.parse(scheduledAt),
                    tz.getLocation(timezone),
                  ).toLocal(),
                  AppLocalizations.of(context)!.localeName,
                ),
              _ => throw UnimplementedError(
                'Unknown notification payload: $payload',
              ),
            };
            return ListTile(
              title: Text(notification.title!),
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
                      Text(notification.body!),
                    ],
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      Icon(Icons.access_time, size: iconSize, color: iconColor),
                      Text(dateTime),
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

// Do not make format object a constant because it will break dynamic UI
// language switching
String _formatNotificationDateTime(DateTime date, String locale) =>
    DateFormat.yMd(locale).add_jm().format(date);
