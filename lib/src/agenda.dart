import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
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

final setNotificationsForDocument = sequentiallyWithLockfile(_getLockfile(), (
  (DataSource, OrgTree, AppLocalizations) args,
) async {
  final (dataSource, doc, localizations) = args;
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
      for (final (dateTime, _, _) in section.scheduledAt.unique().take(
        kMaxNotifications,
      )) {
        if (dateTime.isAfter(now)) {
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
) async {
  for (final elem in agendaFileJsons) {
    switch (await parseAgendaFileJson(elem, accessibleDirs)) {
      case ParsedOrgFileInfo(:final dataSource, :final doc):
        await setNotificationsForDocument((dataSource, doc, localizations));
      case null:
    }
  }
}

typedef AgendaItemSource = ({OrgSection section, DataSource dataSource});

List<AgendaItemSource> getAgendaSections(
  ParsedOrgFileInfo parsedFile, {
  DateTime? now,
}) => parsedFile.doc
    .pendingSections(now: now)
    .map((s) => (section: s, dataSource: parsedFile.dataSource))
    .toList();

typedef AgendaItem = ({
  OrgSection section,
  DataSource dataSource,
  (tz.TZDateTime start, tz.TZDateTime end, int chunkIdx) scheduledAt,
});

Iterable<AgendaItem> agendaItemsFromSources(
  List<AgendaItemSource> sources, {
  DateTime? now,
}) sync* {
  final iters = sources
      .map((s) => (source: s, iter: s.section.scheduledAt.iterator))
      .where((e) => e.iter.moveNext())
      .toList();

  debugPrint(
    'Found ${iters.length} agenda items from ${sources.length} sources',
  );

  var n = 0;
  DateTime? emitted;
  now ??= DateTime.now();

  while (true) {
    debugPrint('Emitting agenda item #$n; previous: $emitted');

    final toRemove =
        <({AgendaItemSource source, Iterator<ChunkedAgendaSpan> iter})>[];
    outer:
    for (final i in iters) {
      while (i.iter.current.$1.isBefore(emitted ?? now)) {
        if (!i.iter.moveNext()) {
          toRemove.add(i);
          continue outer;
        }
      }
    }
    iters.removeWhere((e) => toRemove.contains(e));
    if (iters.isEmpty) break;

    final emitAt = iters
        .map((e) => e.iter.current)
        .reduce((a, b) => a.$1.isBefore(b.$1) ? a : b);

    final allEmitted =
        <({AgendaItemSource source, Iterator<ChunkedAgendaSpan> iter})>[];
    for (final i in iters) {
      if (i.iter.current.$1.isAtSameMomentAs(emitAt.$1)) {
        yield (
          section: i.source.section,
          dataSource: i.source.dataSource,
          scheduledAt: (
            tz.TZDateTime.from(i.iter.current.$1, tz.local),
            tz.TZDateTime.from(i.iter.current.$2, tz.local),
            i.iter.current.$3,
          ),
        );
        allEmitted.add(i);
      }
    }

    for (final i in allEmitted) {
      if (!i.iter.moveNext()) {
        iters.remove(i);
      }
    }

    emitted = emitAt.$1;
    n++;
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

extension OrgSectionUtil on OrgSection {
  bool get isTodo => headline.keyword?.done == false;
  bool get isDone => headline.keyword?.done == true;
  bool get isScheduled =>
      planning.any((entry) => entry.keyword.content == 'SCHEDULED:');
  bool get isClosed =>
      planning.any((entry) => entry.keyword.content == 'CLOSED:');

  Iterable<ChunkedAgendaSpan> get scheduledAt sync* {
    final timestamps = activeTimestamps.toList(growable: false)..sort();
    final iters = timestamps
        .map(
          (e) =>
              expandTimestamp(e).expand((e) => chunkMultidaySpan(e)).iterator,
        )
        .toList(growable: false);
    while (true) {
      var done = true;
      for (final iter in iters) {
        if (!iter.moveNext()) continue;
        done = false;
        yield iter.current;
      }
      if (done) break;
    }
  }

  bool isPending({DateTime? now}) {
    if (isDone || isClosed) return false;

    now ??= DateTime.now();
    return scheduledAt
        .take(kMaxNotifications)
        .any((span) => span.$2.isAfter(now!));
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

  List<OrgTimestamp> get activeTimestamps {
    final timestamps = <OrgTimestamp>[];
    bool visitor(OrgTimestamp timestamp) {
      if (timestamp.isActive &&
          !timestamps.whereType<OrgDateRangeTimestamp>().any(
            (t) => t.start == timestamp || t.end == timestamp,
          )) {
        timestamps.add(timestamp);
      }
      return true;
    }

    // Don't just call this.visit because we don't want to visit subsections
    headline.visit(visitor);
    content?.visit(visitor);
    return timestamps;
  }

  Map<String, Object?> toAgendaPayloadJson() => {
    'id': ids.firstOrNull,
    'customId': customIds.firstOrNull,
    'rawTitle': headline.rawTitle,
  };
}

String? _targetFromPayloadJson(dynamic payload) => switch (payload) {
  {'id': final String id} => 'id:$id',
  {'customId': final String customId} => '#$customId',
  {'rawTitle': final String rawTitle} => '*$rawTitle',
  _ => null,
};

extension OrgTreeUtil on OrgTree {
  Iterable<OrgSection> pendingSections({DateTime? now}) sync* {
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
//   DEADLINE. Add if this is a SCHEDULED.
//   https://orgmode.org/manual/Deadlines-and-Scheduling.html
// - `--`: When a SCHEDULED and has a repeater, add the specified offset to the
//   original datetime only for the first occurrence.
//   https://orgmode.org/manual/Deadlines-and-Scheduling.html
// - `.+`: Add the specified offset to the time the task was completed
//   https://orgmode.org/manual/Repeated-tasks.html
// - Min-max style: can ignore max for now
//   https://orgmode.org/manual/Tracking-your-habits.html

typedef AgendaSpan = (DateTime start, DateTime end);
// chunkIdx is -1 if the span is not chunked, otherwise it is the index of the
// chunk in the multi-day span.
typedef ChunkedAgendaSpan = (DateTime start, DateTime end, int chunkIdx);

Iterable<AgendaSpan> expandTimestamp(
  OrgTimestamp timestamp, [
  OrgTimestamp? end,
]) => switch (timestamp) {
  OrgSimpleTimestamp() => expandDate(
    timestamp.startDateTime,
    (end ?? timestamp).endDateTime,
    timestamp.modifiers,
  ),

  OrgTimeRangeTimestamp() => expandDate(
    timestamp.startDateTime,
    (end ?? timestamp).endDateTime,
    timestamp.modifiers,
  ),
  OrgDateRangeTimestamp() => expandTimestamp(timestamp.start, timestamp.end),
};

Iterable<AgendaSpan> expandDate(
  DateTime start,
  DateTime end,
  List<OrgTimestampModifier> modifiers,
) sync* {
  if (modifiers.isEmpty) {
    yield (start, end);
    return;
  }
  final repeater = modifiers.where((m) => m.isRepeater).firstOrNull;
  final delay = modifiers.where((m) => m.isDelay).firstOrNull;

  int? delayValue;
  DateTime applyDelay(DateTime dt) {
    if (delay == null) return dt;
    delayValue ??= int.parse(delay.value);
    return dt.addModifier(delayValue!, delay.unit);
  }

  yield (applyDelay(start), applyDelay(end));
  if (repeater == null) return;

  final repeaterValue = int.parse(repeater.value);
  DateTime applyRepeater(DateTime dt) =>
      dt.addModifier(repeaterValue, repeater.unit);

  while (true) {
    start = applyRepeater(start);
    end = applyRepeater(end);
    yield delay?.prefix == '-'
        ? (applyDelay(start), applyDelay(end))
        : (start, end);
  }
}

// A multi-day span is accurately modeled by a (start, end) pair, but for
// day-based notifications and agenda view we want to present it as a series of
// single-day spans.
Iterable<ChunkedAgendaSpan> chunkMultidaySpan(AgendaSpan span) sync* {
  final (start, end) = span;
  var chunkIdx = 0;
  var currentStart = start;
  var currentEnd = currentStart.add(const Duration(days: 1)).startOfDay();
  while (currentEnd.isBefore(end)) {
    yield (currentStart, currentEnd, chunkIdx++);
    currentStart = currentStart.add(const Duration(days: 1)).startOfDay();
    currentEnd = currentEnd.add(const Duration(days: 1)).startOfDay();
  }
  yield (currentStart, end, chunkIdx == 0 ? -1 : chunkIdx);
}

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
    final agendaEnabled = _prefs().agendaEnabledPolicy != .deny;
    final developerMode = _prefs(.customization).developerMode;
    return Column(
      children: [
        if (!agendaEnabled || _permissionsGranted == false)
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsItemEnableAgenda),
            onTap: () async {
              await _prefs().setAgendaEnabledPolicy(.ask);
              await _prefs().setAgendaOSNotificationsEnabled(true);
              final granted = await requestNotificationPermissions();
              if (granted) {
                await _load();
              } else {
                AppSettings.openAppSettings(type: .notification);
              }
            },
          ),
        if (agendaEnabled)
          CheckboxListTile(
            title: Text(
              AppLocalizations.of(context)!
                  .settingsItemEnableAgendaNotifications,
            ),
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
                ? () => showDialog<void>(
                    context: context,
                    builder: (context) =>
                        _PendingNotificationsDialog(_pendingNotifications!),
                  )
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
        if (agendaEnabled && _prefs().agendaFileJsons.isNotEmpty)
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
              contentPadding: EdgeInsets.zero,
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

class _ClearAgendaFilesDialog extends StatelessWidget {
  const _ClearAgendaFilesDialog();

  @override
  Widget build(BuildContext context) {
    final agendaFileJsons = Preferences.of(
      context,
      .agenda,
    ).data.agendaFileJsons;
    return AlertDialog(
      icon: const Icon(Icons.warning),
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

// Do not make format object a constant because it will break dynamic UI
// language switching
String _formatNotificationDateTime(DateTime date, String locale) =>
    DateFormat.yMd(locale).add_jm().format(date);
