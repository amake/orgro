import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/main.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/routes/document.dart';
import 'package:orgro/src/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
const kMaxNotifications = 64;
const kMaxNotificationId = 0x7FFFFFFF;

const kAgendaUpdateTask = 'com.madlonkay.orgro.agenda-update';
const kAgendaNotificationsCategory = 'com.madlonkay.orgro.agenda';
const kAgendaNotificationsChannel = 'com.madlonkay.orgro.agenda';
const kAgendaNotificationsActionView = 'com.madlonkay.orgro.agenda.view';
const kAgendaNotificationsAndroidIcon = 'ic_notification';

Future<void> initNotifications(AppLocalizations localizations) async {
  tz.initializeTimeZones();
  final currentTimeZone = await FlutterTimezone.getLocalTimezone();
  debugPrint('Current time zone: $currentTimeZone');
  tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

  final plugin = FlutterLocalNotificationsPlugin();
  const initializationSettingsAndroid = AndroidInitializationSettings(
    kAgendaNotificationsAndroidIcon,
  );
  final initializationSettingsDarwin = DarwinInitializationSettings(
    // We request later on demand
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
    notificationCategories: [
      DarwinNotificationCategory(
        kAgendaNotificationsCategory,
        actions: [
          DarwinNotificationAction.plain(
            kAgendaNotificationsActionView,
            localizations.agendaNotificationsActionView,
            options: {DarwinNotificationActionOption.foreground},
          ),
        ],
      ),
    ],
  );
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );
  await plugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
  final launchDetails = await plugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    onDidReceiveNotificationResponse(launchDetails!.notificationResponse!);
  }
}

void onDidReceiveNotificationResponse(NotificationResponse details) async {
  if (details.payload == null) {
    debugPrint('No payload in notification; id: ${details.id}');
    return;
  }
  final payload = json.decode(details.payload!);
  switch (payload) {
    case {
      'dataSource': {
        'type': 'native',
        'identifier': final String id,
        'name': final String name,
      },
    }:
      final context = startKey.currentContext;
      try {
        final accessibleDirs = Preferences.of(
          context!,
          .accessibleDirs,
        ).data.accessibleDirs;
        // TODO(aaron): Don't open if we already have it open
        final (
          :dataSource,
          :recovered,
        ) = await readFileWithIdentifierWithRecoveryStrategy(
          identifier: id,
          fileName: name,
          accessibleDirs: accessibleDirs,
        );
        final target = _targetFromPayloadJson(payload['section']);
        final AfterOpenCallback? afterOpen = target == null
            ? null
            : (state) async {
                OrgLocator.of(state.context)?.jumpToSection(target);
              };
        if (recovered) {
          await Preferences.of(context, .agenda).replaceAgendaFileJson(
            payload['dataSource'] as Map<String, dynamic>,
            dataSource.toJson(),
          );
          if (context.mounted) {
            await loadAndReplaceRememberedFile(
              context,
              id,
              dataSource,
              afterOpen: afterOpen,
            );
          }
        } else {
          await loadAndRememberFile(context, dataSource, afterOpen: afterOpen);
        }
      } catch (e, s) {
        logError(e, s);
        if (context?.mounted == true) showErrorSnackBar(context!, e);
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
    if (await androidImpl.areNotificationsEnabled() != true) return false;
    if (await androidImpl.canScheduleExactNotifications() != true) return false;
    return true;
  }
  final iosImpl = plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
  if (iosImpl != null) {
    final permissions = await iosImpl.checkPermissions();
    return permissions?.isEnabled == true;
  }
  throw UnimplementedError('Unsupported platform');
}

Future<bool> requestNotificationPermissions() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final androidImpl = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (androidImpl != null) {
    if (await androidImpl.requestNotificationsPermission() != true) {
      return false;
    }
    if (await androidImpl.requestExactAlarmsPermission() != true) return false;
    return true;
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

const kAllDayEventNotificationHour = 9;

final setNotificationsForDocument = sequentiallyWithLockfile(_getLockfile(), (
  (
    DataSource,
    OrgTree,
    AppLocalizations,
    EventNotificationTime,
    AllDayEventNotificationTime,
  )
  args,
) async {
  final (dataSource, doc, localizations, notifyTime, allDayNotifyTime) = args;
  if (!(await checkNotificationPermissions())) {
    debugPrint(
      'Skipping setting notifications because permissions not granted.',
    );
    return;
  }

  debugPrint('Setting agenda notifications for document ${dataSource.name}');

  final plugin = FlutterLocalNotificationsPlugin();
  final pendingNotifications = <(tz.TZDateTime, PendingNotificationRequest)>[];
  for (final element in await plugin.pendingNotificationRequests()) {
    final payload = json.decode(element.payload!);
    if (payload case {'dataSource': {'id': final id}}) {
      if (id == dataSource.id) {
        // This notification is for this file; we will reschedule it below
        debugPrint('Canceling notification with ID ${element.id} ($id)');
        await plugin.cancel(id: element.id);
        continue;
      }
    }

    switch (payload) {
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
  final now = DateTime.now();
  doc.visitSections((section) {
    if (section.isPending()) {
      for (final e
          in section
              .occursAt(now: now)
              .where((e) => !e.overdue)
              .unique()
              .take(kMaxNotifications)) {
        final notificationDateTime = e.isAllDay
            ? allDayNotifyTime.applyTo(e.start)
            : notifyTime.applyTo(e.start);
        if (notificationDateTime.isAfter(now)) {
          final tzDateTime = tz.TZDateTime.from(notificationDateTime, tz.local);
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
          id: id,
          title:
              element.headline.title?.toPlainText() ??
              element.headline.rawTitle,
          body: dataSource.name,
          scheduledDate: dateTime,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              kAgendaNotificationsChannel,
              localizations.agendaNotificationsChannelName,
              icon: kAgendaNotificationsAndroidIcon,
              channelDescription:
                  localizations.agendaNotificationsChannelDescription,
              // Priority.max is apparently deprecated, but we set it in the
              // hopes it makes a difference on older Android versions.
              priority: .max,
              // Importance.max is required to make "Pop on screen" on by
              // default. Presumably users would want this for agenda items.
              importance: .max,
              actions: [
                AndroidNotificationAction(
                  kAgendaNotificationsActionView,
                  localizations.agendaNotificationsActionView,
                  showsUserInterface: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: kAgendaNotificationsCategory,
            ),
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
        await plugin.cancel(id: element.id);
      case OrgSection():
        // This notification got pushed off the end. Don't schedule it.
        continue;
      default:
        throw UnimplementedError('Unknown notification element: $element');
    }
  }
});

extension _EventNotificationTimeUtil on EventNotificationTime {
  DateTime applyTo(DateTime dateTime) => switch (this) {
    .atEventTime => dateTime,
    .fiveMinutesBefore => dateTime.copyWith(minute: dateTime.minute - 5),
    .tenMinutesBefore => dateTime.copyWith(minute: dateTime.minute - 10),
    .fifteenMinutesBefore => dateTime.copyWith(minute: dateTime.minute - 15),
    .thirtyMinutesBefore => dateTime.copyWith(minute: dateTime.minute - 30),
    .oneHourBefore => dateTime.copyWith(hour: dateTime.hour - 1),
    .twoHoursBefore => dateTime.copyWith(hour: dateTime.hour - 2),
    .oneDayBefore => dateTime.copyWith(day: dateTime.day - 1),
    .twoDaysBefore => dateTime.copyWith(day: dateTime.day - 2),
    .oneWeekBefore => dateTime.copyWith(day: dateTime.day - 7),
  };
}

extension _AllDayEventNotificationTimeUtil on AllDayEventNotificationTime {
  DateTime applyTo(DateTime dateTime) => switch (this) {
    .onDayOfEvent => dateTime.copyWith(hour: kAllDayEventNotificationHour),
    .oneDayBefore => dateTime.copyWith(
      day: dateTime.day - 1,
      hour: kAllDayEventNotificationHour,
    ),
    .twoDaysBefore => dateTime.copyWith(
      day: dateTime.day - 2,
      hour: kAllDayEventNotificationHour,
    ),
    .oneWeekBefore => dateTime.copyWith(
      day: dateTime.day - 7,
      hour: kAllDayEventNotificationHour,
    ),
  };
}

Future<ParsedOrgFileInfo?> parseAgendaFileJson(
  Map<String, dynamic> agendaFileJson,
  Iterable<String> accessibleDirs,
) async {
  switch (agendaFileJson) {
    case {
      'type': 'native',
      'identifier': final String id,
      'name': final String name,
    }:
      try {
        final (
          :dataSource,
          :recovered,
        ) = await readFileWithIdentifierWithRecoveryStrategy(
          identifier: id,
          fileName: name,
          accessibleDirs: accessibleDirs,
        );
        // TODO(aaron): Ideally we would update the agendaFileJsons if we used
        // the recovery strategy, but we don't have access to the Preferences
        // here, and since this function is called in a background thread we
        // would need to coordinate with the main app.
        return await ParsedOrgFileInfo.from(dataSource);
      } catch (e, s) {
        logError(e, s);
        return null;
      }
    default:
      throw UnimplementedError('Unknown agenda file JSON: $agendaFileJson');
  }
}

Future<void> setNotificationsForAllAgendaDocuments(
  List<Map<String, dynamic>> agendaFileJsons,
  AppLocalizations localizations,
  Iterable<String> accessibleDirs,
  EventNotificationTime notifyTime,
  AllDayEventNotificationTime allDayNotifyTime,
) async {
  for (final elem in agendaFileJsons) {
    switch (await parseAgendaFileJson(elem, accessibleDirs)) {
      case ParsedOrgFileInfo(:final dataSource, :final doc):
        await setNotificationsForDocument((
          dataSource,
          doc,
          localizations,
          notifyTime,
          allDayNotifyTime,
        ));
      case null:
    }
  }
}

typedef AgendaItemSource = ({OrgSection section, DataSource dataSource});

List<AgendaItemSource> getAgendaSections(
  ParsedOrgFileInfo parsedFile, {
  DateTime? now,
}) => parsedFile.doc
    .agendaSections(now: now)
    .map((s) => (section: s, dataSource: parsedFile.dataSource))
    .toList();

typedef AgendaItem = ({
  OrgSection section,
  DataSource dataSource,
  ({
    tz.TZDateTime start,
    tz.TZDateTime end,
    int chunkIdx,
    bool last,
    String? keyword,
    bool overdue,
  })
  scheduledAt,
});

Iterable<AgendaItem> agendaItemsFromSources(
  List<AgendaItemSource> sources, {
  DateTime? now,
}) sync* {
  now ??= DateTime.now();

  final items = sources.map(
    (source) => source.section
        .occursAt(now: now)
        .where((span) => span.overdue || !span.comparisonPoint.isBefore(now!))
        .map((span) => (source: source, span: span)),
  );

  for (final (:source, :span) in items.mergeSorted(
    (a, b) => a.span.comparisonPoint.compareTo(b.span.comparisonPoint),
  )) {
    yield (
      section: source.section,
      dataSource: source.dataSource,
      scheduledAt: (
        start: tz.TZDateTime.from(span.start, tz.local),
        end: tz.TZDateTime.from(span.end, tz.local),
        chunkIdx: span.chunkIdx,
        last: span.last,
        keyword: span.keyword,
        overdue: span.overdue,
      ),
    );
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
          await plugin.cancel(id: element.id);
        }
    }
  }
}

Future<void> clearAllNotifications() async =>
    await FlutterLocalNotificationsPlugin().cancelAll();

typedef PlannedTimestamp = (OrgTimestamp, OrgPlanningKeyword?);

extension OrgSectionUtil on OrgSection {
  bool get isTodo => headline.keyword?.done == false;
  bool get isDone => headline.keyword?.done == true;
  bool get hasScheduled =>
      planning.any((entry) => entry.keyword.content == 'SCHEDULED:');
  bool get hasClosed =>
      planning.any((entry) => entry.keyword.content == 'CLOSED:');
  bool get hasDeadline =>
      planning.any((entry) => entry.keyword.content == 'DEADLINE:');

  Iterable<ChunkedAgendaSpan> occursAt({DateTime? now}) sync* {
    now ??= DateTime.now();
    final timestamps = activeTimestamps.toList(growable: false)
      ..sort((a, b) => a.$1.compareTo(b.$1));
    yield* timestamps
        .map2(
          (t, kw) => _expandTimestampWithPlanning(
            t,
            kw,
            now: now,
          ).expand(chunkMultidaySpan),
        )
        .mergeSorted((a, b) => a.comparisonPoint.compareTo(b.comparisonPoint));
  }

  Iterable<AgendaSpan> _expandTimestampWithPlanning(
    OrgTimestamp timestamp,
    OrgPlanningKeyword? keyword, {
    DateTime? now,
  }) sync* {
    now ??= DateTime.now();
    if (!isDone && timestamp.isOverdue(keyword, now: now)) {
      final startOfDay = now.startOfDay();
      yield (startOfDay, startOfDay.nextDay(), keyword?.content, true);
      return;
    }
    yield* expandTimestamp(timestamp, keyword);
  }

  bool isPending({DateTime? now}) {
    if (isDone) return false;

    now ??= DateTime.now();
    return activeTimestamps.any2((t, kw) {
      if (t.endsAfter(now!, kw)) return true;
      if (t.isOverdue(kw, now: now)) return true;
      if (t.repeats) return true;
      return false;
    });
  }

  List<OrgPlanningEntry> get planning {
    final entries = <OrgPlanningEntry>[];
    bool visitor(OrgPlanningEntry entry) {
      entries.add(entry);
      return true;
    }

    // Don't just call this.visit because we don't want to visit subsections
    headline.visit(visitor);
    content?.visit(visitor);
    return entries;
  }

  List<PlannedTimestamp> get activeTimestamps {
    final timestamps = <PlannedTimestamp>[];
    bool timestampVisitor(OrgTimestamp node) {
      if (node.isActive &&
          !timestamps.any2((t, _) {
            return t == node ||
                t is OrgDateRangeTimestamp &&
                    (t.start == node || t.end == node);
          })) {
        timestamps.add((node, null));
      }
      return true;
    }

    bool allVisitor(OrgNode node) {
      switch (node) {
        // TODO(aaron): Technically we should only honor planning entries that
        // are on the line immediately following the headline
        case OrgPlanningEntry(keyword: final k, value: final OrgTimestamp v)
            when v.isActive:
          timestamps.add((v, k));
        case OrgTimestamp():
          timestampVisitor(node);
      }
      return true;
    }

    // Don't just call this.visit because we don't want to visit subsections

    // Planning entries are not honored when in the headline, but the timestamps
    // are
    headline.visit(timestampVisitor);
    content?.visit(allVisitor);
    return timestamps;
  }

  Map<String, Object?> toAgendaPayloadJson() => {
    'id': ids.firstOrNull,
    'customId': customIds.firstOrNull,
    'rawTitle': headline.rawTitle,
  };
}

extension _OrgTimestampUtil on OrgTimestamp {
  bool isOverdue(OrgPlanningKeyword? kw, {DateTime? now}) {
    // TODO(aaron): Not sure how to handle a repeating SCHEDULED/DEADLINE. For now
    // we let them get picked up by [isPending].
    if (repeats) return false;

    if (kw?.content != 'SCHEDULED:' && kw?.content != 'DEADLINE:') return false;

    final startOfDay = (now ??= DateTime.now()).startOfDay();
    return endsBeforeOrOn(startOfDay, kw);
  }

  bool endsBeforeOrOn(DateTime dt, OrgPlanningKeyword? keyword) => hasDelay
      ? !_delayedEndTime(keyword).isAfter(dt)
      : !endDateTime.isAfter(dt);

  bool endsAfter(DateTime dt, OrgPlanningKeyword? keyword) =>
      hasDelay ? _delayedEndTime(keyword).isAfter(dt) : endDateTime.isAfter(dt);

  DateTime _delayedEndTime(OrgPlanningKeyword? keyword) => switch (this) {
    final OrgSimpleTimestamp t =>
      t.modifiers
          .firstWhere((m) => m.isDelay)
          .apply(t.endDateTime, keyword: keyword),
    final OrgTimeRangeTimestamp t =>
      t.modifiers
          .firstWhere((m) => m.isDelay)
          .apply(t.endDateTime, keyword: keyword),
    final OrgDateRangeTimestamp t => t.end._delayedEndTime(keyword),
  };
}

String? _targetFromPayloadJson(dynamic payload) => switch (payload) {
  {'id': final String id} => 'id:$id',
  {'customId': final String customId} => '#$customId',
  {'rawTitle': final String rawTitle} => '*$rawTitle',
  _ => null,
};

extension OrgTreeUtil on OrgTree {
  Iterable<OrgSection> agendaSections({DateTime? now}) sync* {
    final toSchedule = <OrgSection>[];
    visitSections((section) {
      if (section.isPending(now: now)) {
        toSchedule.add(section);
      }
      return true;
    });

    yield* toSchedule;
  }
}

// - `+`: Add the specified offset to the original datetime
//   https://orgmode.org/manual/Repeated-tasks.html
// - `++`: Add the specified offset enough times to get past *now*
//   https://orgmode.org/manual/Repeated-tasks.html
// - `-`: Subtract the specified offset from the original datetime if this is a
//   DEADLINE. Add if this is a SCHEDULED. If neither, it is a noop.
//   https://orgmode.org/manual/Deadlines-and-Scheduling.html
// - `--`: When a SCHEDULED and has a repeater, add the specified offset to the
//   original datetime only for the first occurrence.
//   https://orgmode.org/manual/Deadlines-and-Scheduling.html
// - `.+`: Add the specified offset to the time the task was completed
//   https://orgmode.org/manual/Repeated-tasks.html
// - Min-max style: can ignore max for now
//   https://orgmode.org/manual/Tracking-your-habits.html

typedef AgendaSpan = (
  DateTime start,
  DateTime end,
  String? keyword,
  bool overdue,
);
typedef ChunkedAgendaSpan = ({
  DateTime start,
  DateTime end,
  int chunkIdx,
  // True if this is the last chunk of a span, false otherwise. Single-day spans
  // have chunkIdx == 0 and last == true.
  bool last,
  String? keyword,
  bool overdue,
});

extension ChunkUtil on ChunkedAgendaSpan {
  bool get isInstant => start.isAtSameMomentAs(end);
  bool get isAllDay => start.isStartOfDay() && end.isStartOfDay();
  bool get isStartOfMultidaySpan => chunkIdx == 0 && !last;
  bool get isEndOfMultidaySpan => chunkIdx > 0 && last;

  // Sort the last chunk of a multi-day span by the end of the chunk
  DateTime get comparisonPoint =>
      isEndOfMultidaySpan && !end.isStartOfDay() ? end : start;
}

Iterable<AgendaSpan> expandTimestamp(
  OrgTimestamp timestamp,
  OrgPlanningKeyword? keyword, [
  OrgTimestamp? end,
]) => switch (timestamp) {
  OrgSimpleTimestamp() => expandDate(
    timestamp.startDateTime,
    (end ?? timestamp).endDateTime,
    timestamp.modifiers,
    keyword,
  ),
  OrgTimeRangeTimestamp() => expandDate(
    timestamp.startDateTime,
    (end ?? timestamp).endDateTime,
    timestamp.modifiers,
    keyword,
  ),
  OrgDateRangeTimestamp() => expandTimestamp(
    timestamp.start,
    keyword,
    timestamp.end,
  ),
};

Iterable<AgendaSpan> expandDate(
  DateTime start,
  DateTime end,
  List<OrgTimestampModifier> modifiers,
  OrgPlanningKeyword? keyword,
) sync* {
  if (modifiers.isEmpty) {
    yield (start, end, keyword?.content, false);
    return;
  }
  final repeater = modifiers.where((m) => m.isRepeater).firstOrNull;
  final delay = modifiers.where((m) => m.isDelay).firstOrNull;

  int? delayValue;
  DateTime applyDelay(DateTime dt) {
    if (delay == null) return dt;
    delayValue ??=
        int.parse(delay.value) *
        switch ((delay.prefix, keyword?.content)) {
          ('-', 'DEADLINE:') => -1,
          ('-', 'SCHEDULED:') || ('--', 'SCHEDULED:') => 1,
          _ => 0,
        };
    return dt.addModifier(delayValue!, delay.unit);
  }

  yield (applyDelay(start), applyDelay(end), keyword?.content, false);
  if (repeater == null) return;

  final repeaterValue = int.parse(repeater.value);
  DateTime applyRepeater(DateTime dt) =>
      dt.addModifier(repeaterValue, repeater.unit);

  while (true) {
    start = applyRepeater(start);
    end = applyRepeater(end);
    yield delay?.prefix == '-'
        ? (applyDelay(start), applyDelay(end), keyword?.content, false)
        : (start, end, keyword?.content, false);
  }
}

// A multi-day span is accurately modeled by a (start, end) pair, but for
// day-based notifications and agenda view we want to present it as a series of
// single-day spans.
Iterable<ChunkedAgendaSpan> chunkMultidaySpan(AgendaSpan span) sync* {
  final (start, end, keyword, overdue) = span;
  var chunkIdx = 0;
  var currentStart = start;
  var currentEnd = currentStart.nextDay().startOfDay();
  while (currentEnd.isBefore(end)) {
    yield (
      start: currentStart,
      end: currentEnd,
      chunkIdx: chunkIdx++,
      last: false,
      keyword: keyword,
      overdue: overdue,
    );
    currentStart = currentStart.nextDay().startOfDay();
    currentEnd = currentEnd.nextDay().startOfDay();
  }
  yield (
    start: currentStart,
    end: end,
    chunkIdx: chunkIdx,
    last: true,
    keyword: keyword,
    overdue: overdue,
  );
}
