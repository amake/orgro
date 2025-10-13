import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class BackgroundTasks extends StatefulWidget {
  const BackgroundTasks({required this.child, super.key});

  final Widget child;

  @override
  State<BackgroundTasks> createState() => _BackgroundTasksState();
}

class _BackgroundTasksState extends State<BackgroundTasks> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _doInit();
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _handleBackgroundFetch('periodic timer'),
    );
  }

  void _doInit() async {
    try {
      final workmanager = Workmanager();
      await workmanager.initialize(backgroundTaskDispatcher);
      await initNotifications();
      // Background refresh is automatically scheduled on iOS
      if (Platform.isAndroid) {
        await workmanager.registerPeriodicTask(
          kAgendaUpdateTask,
          kAgendaUpdateTask,
          frequency: const Duration(minutes: 15),
          initialDelay: const Duration(minutes: 7),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        );
      }
      // Run once at startup
      _handleBackgroundFetch('startup');
    } catch (e, s) {
      logError(e, s);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

@pragma('vm:entry-point')
void backgroundTaskDispatcher() {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  Workmanager().executeTask((task, inputData) async {
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    debugPrint('Background task triggered: $task; timezone: $currentTimeZone');

    try {
      switch (task) {
        case kAgendaUpdateTask:
          // Custom task to update agenda notifications
          await _handleBackgroundFetch(task);
          break;
        case Workmanager.iOSBackgroundTask:
          // iOS Background Fetch task
          await _handleBackgroundFetch(task);
          break;
        default:
          debugPrint('Unknown background task: $task');
      }
    } catch (e, s) {
      debugPrint('ExecuteTask error: $e\n$s');
    }

    return Future.value(true);
  });
}

Future<void> _handleBackgroundFetch(String debugLabel) async {
  debugPrint('Background fetch triggered ($debugLabel)');

  final prefs = await PreferencesData.fromSharedPreferences(
    SharedPreferencesAsync(),
  );

  final localizationsResolver = LocalizationsResolver(
    supportedLocales: AppLocalizations.supportedLocales,
  );
  final locale = localizationsResolver.locale;
  final localizations = lookupAppLocalizations(locale);

  debugPrint('Going to set notifications for all agenda docs; locale: $locale');

  await setNotificationsForAllAgendaDocuments(
    prefs.agendaFileJsons,
    localizations,
  );
}
