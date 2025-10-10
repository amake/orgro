import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/main.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
const kMaxNotifications = 64;
const kMaxNotificationId = 0x7FFFFFFF;

void initNotifications() async {
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

Future<void> setNotificationsForDocument(
  DataSource dataSource,
  OrgTree doc,
) async {
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
          // TODO(aaron): This should probably be the plaintext title
          element.headline.rawTitle,
          dataSource.name,
          dateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'com.madlonkay.orgro.agenda',
              'Agenda Notifications',
              channelDescription: 'Notifications for Org Agenda items',
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
}

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
    'title': headline.rawTitle,
  };
}
