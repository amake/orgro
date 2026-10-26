import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/agenda/agenda.dart';
import 'package:orgro/src/util.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Makefile runs this file with TZ=America/Sao_Paulo, Pacific/Apia, and
// America/New_York. These flags detect the relevant transitions, so unrelated
// local runs skip only the cases their process timezone cannot exercise.
final _hasSaoPauloMissingMidnight = DateTime(2018, 11, 4).hour == 1;
final _hasApiaSkippedDate = DateTime(2011, 12, 30).day == 31;
final _hasNewYorkSpringForward =
    DateTime(2024, 3, 9, 12).timeZoneOffset !=
    DateTime(2024, 3, 10, 12).timeZoneOffset;
final _hasNewYorkFallBack =
    DateTime(2024, 11, 2, 12).timeZoneOffset !=
    DateTime(2024, 11, 3, 12).timeZoneOffset;

ChunkedAgendaSpan _agendaSpan(
  DateTime start,
  DateTime end, {
  int chunkIdx = 0,
  bool last = true,
  String? keyword,
  bool overdue = false,
}) => (
  start: start,
  end: end,
  chunkIdx: chunkIdx,
  last: last,
  keyword: keyword,
  overdue: overdue,
);

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  test('Chunks spans across a day with a missing midnight', () {
    final start = DateTime(2018, 11, 3, 23);
    final missingMidnight = DateTime(2018, 11, 4);
    final end = DateTime(2018, 11, 4, 2);

    expect(missingMidnight.hour, 1);
    expect(chunkMultidaySpan((start, end, null, false)), [
      _agendaSpan(start, missingMidnight, last: false),
      _agendaSpan(missingMidnight, end, chunkIdx: 1),
    ]);
  }, skip: !_hasSaoPauloMissingMidnight);

  test('Overdue spans use the next day boundary after a missing midnight', () {
    final doc = OrgDocument.parse('''
* TODO Old task
  SCHEDULED: <2018-11-03 Sat>
''');
    final section = doc.children.firstOrNull as OrgSection;
    final now = DateTime(2018, 11, 4, 12);

    expect(now.startOfDay().hour, 1);
    expect(section.isPending(now: now), isTrue);
    expect(section.occursAt(now: now), [
      _agendaSpan(
        DateTime(2018, 11, 4, 1),
        DateTime(2018, 11, 5),
        keyword: 'SCHEDULED:',
        overdue: true,
      ),
    ]);
  }, skip: !_hasSaoPauloMissingMidnight);

  test('Chunks spans across a skipped calendar date', () {
    final start = DateTime(2011, 12, 29, 12);
    final skippedDate = DateTime(2011, 12, 30);
    final end = DateTime(2012, 1, 1, 12);

    expect(
      (skippedDate.year, skippedDate.month, skippedDate.day),
      (2011, 12, 31),
    );
    expect(chunkMultidaySpan((start, end, null, false)), [
      _agendaSpan(start, DateTime(2011, 12, 31), last: false),
      _agendaSpan(
        DateTime(2011, 12, 31),
        DateTime(2012, 1, 1),
        chunkIdx: 1,
        last: false,
      ),
      _agendaSpan(DateTime(2012, 1, 1), end, chunkIdx: 2),
    ]);
  }, skip: !_hasApiaSkippedDate);

  test('Chunks spans across the spring-forward day', () {
    final start = DateTime(2024, 3, 9);
    final end = DateTime(2024, 3, 11);
    final spans = chunkMultidaySpan((start, end, null, false)).toList();

    expect(spans.map((span) => span.start), [
      DateTime(2024, 3, 9),
      DateTime(2024, 3, 10),
    ]);
    expect(spans.map((span) => span.end.difference(span.start).inHours), [
      24,
      23,
    ]);
  }, skip: !_hasNewYorkSpringForward);

  test('Chunks spans across the fall-back day', () {
    final start = DateTime(2024, 11, 2);
    final end = DateTime(2024, 11, 4);
    final spans = chunkMultidaySpan((start, end, null, false)).toList();

    expect(spans.map((span) => span.start), [
      DateTime(2024, 11, 2),
      DateTime(2024, 11, 3),
    ]);
    expect(spans.map((span) => span.end.difference(span.start).inHours), [
      24,
      25,
    ]);
  }, skip: !_hasNewYorkFallBack);

  test('Daily repeats retain their local time across spring-forward', () {
    final doc = OrgDocument.parse('''
* TODO Daily task
  SCHEDULED: <2024-03-09 Sat 09:00 +1d>
''');
    final section = doc.children.firstOrNull as OrgSection;

    expect(
      section
          .occursAt(now: DateTime(2024, 3, 9, 8))
          .take(3)
          .map((span) => span.start),
      [
        DateTime(2024, 3, 9, 9),
        DateTime(2024, 3, 10, 9),
        DateTime(2024, 3, 11, 9),
      ],
    );
  }, skip: !_hasNewYorkSpringForward);

  test('Native local DateTime resolves skipped and repeated hours', () {
    // OrgTimestamp constructs native local DateTimes. We rely on the
    // platform's resolution of skipped and repeated local times.
    final skippedDoc = OrgDocument.parse('''
* TODO Skipped hour
  SCHEDULED: <2024-03-10 Sun 02:30>
''');
    final skippedSection = skippedDoc.children.firstOrNull as OrgSection;
    final (skippedTimestamp, _) = skippedSection.activeTimestamps.single;
    final skipped = skippedTimestamp.startDateTime;
    expect(
      (skipped.year, skipped.month, skipped.day, skipped.hour, skipped.minute),
      (2024, 3, 10, 3, 30),
    );

    final repeatedDoc = OrgDocument.parse('''
* TODO Repeated hour
  SCHEDULED: <2024-11-03 Sun 01:30>
''');
    final repeatedSection = repeatedDoc.children.firstOrNull as OrgSection;
    final (repeatedTimestamp, _) = repeatedSection.activeTimestamps.single;
    final repeated = repeatedTimestamp.startDateTime;
    final validInstants = {
      DateTime.utc(2024, 11, 3, 5, 30),
      DateTime.utc(2024, 11, 3, 6, 30),
    };
    expect(
      (
        repeated.year,
        repeated.month,
        repeated.day,
        repeated.hour,
        repeated.minute,
      ),
      (2024, 11, 3, 1, 30),
    );
    // Dart/platform behavior chooses one occurrence; either offset is valid.
    expect(validInstants.contains(repeated.toUtc()), isTrue);
  }, skip: !_hasNewYorkSpringForward || !_hasNewYorkFallBack);

  test('Agenda day changes when the local date changes after travel', () {
    final instant = DateTime.utc(2025, 1, 1, 1);
    final losAngeles = tz.TZDateTime.from(
      instant,
      tz.getLocation('America/Los_Angeles'),
    );
    final tokyo = tz.TZDateTime.from(instant, tz.getLocation('Asia/Tokyo'));

    expect(
      shouldRefreshAgenda(
        today: losAngeles,
        now: tokyo,
        timezone: 'America/Los_Angeles',
        currentTimezone: 'Asia/Tokyo',
      ),
      isTrue,
    );
  });

  test('Agenda refreshes after a timezone change on the same local date', () {
    expect(
      shouldRefreshAgenda(
        today: DateTime(2025, 1, 1),
        now: DateTime(2025, 1, 1, 12),
        timezone: 'America/Los_Angeles',
        currentTimezone: 'America/Denver',
      ),
      isTrue,
    );
  });

  test('Pending notification time survives a timezone change', () {
    final newYork = tz.getLocation('America/New_York');
    final scheduled = tz.TZDateTime(newYork, 2024, 11, 3, 9);
    final serialized = scheduled.toIso8601String();
    addTearDown(() => tz.setLocalLocation(tz.UTC));
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    final restored = parseScheduledNotificationDateTime(
      scheduledAt: serialized,
      timezone: newYork.name,
    );

    expect(restored.isAtSameMomentAs(scheduled), isTrue);
    expect(
      (restored.year, restored.month, restored.day, restored.hour),
      (2024, 11, 3, 9),
    );
  });
}
