import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/data_source.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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

  group('Section pending', () {
    final now = DateTime(2025, 10, 1, 10);
    test('Pending', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgSimpleTimestamp>());
      expect(keyword!.content, 'SCHEDULED:');
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 5),
          DateTime(2025, 10, 6),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Exact time', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun 10:01>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 5, 10, 1),
          DateTime(2025, 10, 5, 10, 1),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Right now', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun 10:00>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 5, 10, 0),
          DateTime(2025, 10, 5, 10, 0),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Past scheduled', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-09-05 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasDeadline, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 1),
          DateTime(2025, 10, 2),
          keyword: 'SCHEDULED:',
          overdue: true,
        ),
      ]);
    });
    test('Past deadline', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  DEADLINE: <2025-09-05 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasDeadline, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 1),
          DateTime(2025, 10, 2),
          keyword: 'DEADLINE:',
          overdue: true,
        ),
      ]);
    });
    test('Past complete', () {
      final doc = OrgDocument.parse('''
* DONE Do the thing
  SCHEDULED: <2025-09-05 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isTrue);
      expect(section.isTodo, isFalse);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 9, 5),
          DateTime(2025, 9, 6),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Naked timestamp', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo <2025-09-05 Fri>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2025, 9, 5), DateTime(2025, 9, 6)),
      ]);
    });
    test('Multiple timestamps', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo <2025-09-05 Fri>
  bar <2025-10-10 Fri>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2025, 9, 5), DateTime(2025, 9, 6)),
        _agendaSpan(DateTime(2025, 10, 10), DateTime(2025, 10, 11)),
      ]);
    });
    test('Duplicate timestamps', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo <2025-09-05 Fri>
  bar <2025-09-05 Fri>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2025, 9, 5), DateTime(2025, 9, 6)),
        _agendaSpan(DateTime(2025, 9, 5), DateTime(2025, 9, 6)),
      ]);
    });
    test('Time range', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo <2025-10-01 Wed 10:30-12:30>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 1, 10, 30),
          DateTime(2025, 10, 1, 12, 30),
        ),
      ]);
    });
    test('Time range (already started)', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo <2025-10-01 Wed 09:30-12:30>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 1, 9, 30),
          DateTime(2025, 10, 1, 12, 30),
        ),
      ]);
    });
    test('Timestamp in header', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing <2025-10-10 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2025, 10, 10), DateTime(2025, 10, 11)),
      ]);
    });
    test('Planning entry in header', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing SCHEDULED: <2025-10-10 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2025, 10, 10), DateTime(2025, 10, 11)),
      ]);
    });
    test('Inacive timestamp', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: [2025-10-05 Sun 10:01]
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.activeTimestamps, isEmpty);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), isEmpty);
    });
    test('Not scheduled', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), isEmpty);
    });
    test('Not completed via CLOSED', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun> CLOSED: [2025-10-06 Tue]
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isTrue);
      expect(section.isPending(now: now), isTrue);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 5),
          DateTime(2025, 10, 6),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Completed via DONE', () {
      final doc = OrgDocument.parse('''
* DONE Do the thing
  SCHEDULED: <2025-10-05 Sun>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isTrue);
      expect(section.isTodo, isFalse);
      expect(section.hasScheduled, isTrue);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2025, 10, 5),
          DateTime(2025, 10, 6),
          keyword: 'SCHEDULED:',
        ),
      ]);
    });
    test('Not TODO', () {
      final doc = OrgDocument.parse('''
* Do the thing
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isFalse);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), isEmpty);
    });
    test('Subsection', () {
      final doc = OrgDocument.parse('''
* Things to do
** TODO Do the thing
   SCHEDULED: <2025-10-05 Sun> CLOSED: [2025-10-06 Tue]
   foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isFalse);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.occursAt(now: now), isEmpty);
    });
    test('Time range', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-21 Mon 17:00-22:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgTimeRangeTimestamp>());
      expect(keyword, isNull);
      expect(section.occursAt(now: now), [
        _agendaSpan(DateTime(2026, 9, 21, 17, 0), DateTime(2026, 9, 21, 22, 0)),
      ]);
    });
    test('Datetime range with specific times (next day, >1 day)', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri 08:00>--<2026-09-26 Sat 14:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgDateRangeTimestamp>());
      expect(keyword, isNull);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 8, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 26, 14, 0),
          chunkIdx: 1,
        ),
      ]);
    });
    test('Datetime range with specific times (next day, <1 day)', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri 08:00>--<2026-09-26 Sat 07:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgDateRangeTimestamp>());
      expect(keyword, isNull);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 8, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 26, 7, 0),
          chunkIdx: 1,
        ),
      ]);
    });
    test('Datetime range with specific times (multiple days away)', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri 08:00>--<2026-09-27 Sun 14:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgDateRangeTimestamp>());
      expect(keyword, isNull);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 8, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 27, 0, 0),
          chunkIdx: 1,
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 27, 0, 0),
          DateTime(2026, 9, 27, 14, 0),
          chunkIdx: 2,
        ),
      ]);
    });
    test('Datetime range no specific times', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri>--<2026-09-27 Sat>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.hasScheduled, isFalse);
      expect(section.hasClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      final (timestamp, keyword) = section.activeTimestamps.single;
      expect(timestamp, isA<OrgDateRangeTimestamp>());
      expect(keyword, isNull);
      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 0, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 27, 0, 0),
          chunkIdx: 1,
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 27, 0, 0),
          DateTime(2026, 9, 28, 0, 0),
          chunkIdx: 2,
        ),
      ]);
    });
    test('Orders overlapping spans by comparison point', () {
      final now = DateTime(2026, 9, 1);
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri 08:00>--<2026-09-27 Sun 14:00>
<2026-09-26 Sat 10:00>
<2026-09-27 Sun 09:00>
''');
      final section = doc.children.firstOrNull as OrgSection;

      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 8, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 27, 0, 0),
          chunkIdx: 1,
          last: false,
        ),
        _agendaSpan(DateTime(2026, 9, 26, 10, 0), DateTime(2026, 9, 26, 10, 0)),
        _agendaSpan(DateTime(2026, 9, 27, 9, 0), DateTime(2026, 9, 27, 9, 0)),
        _agendaSpan(
          DateTime(2026, 9, 27, 0, 0),
          DateTime(2026, 9, 27, 14, 0),
          chunkIdx: 2,
        ),
      ]);

      final agendaItems = agendaItemsFromSources([
        (section: section, dataSource: AssetDataSource('test.org')),
      ], now: now);
      expect(agendaItems.map((item) => item.scheduledAt.start), [
        tz.TZDateTime.from(DateTime(2026, 9, 25, 8, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 26, 0, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 26, 10, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 27, 9, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 27, 0, 0), tz.local),
      ]);
    });
    test('Emits every source at the same comparison point', () {
      final firstDoc = OrgDocument.parse('''
* TODO First
<2026-09-25 Fri 08:00>
''');
      final secondDoc = OrgDocument.parse('''
* TODO Second
<2026-09-25 Fri 08:00>
''');
      final firstSection = firstDoc.children.firstOrNull as OrgSection;
      final secondSection = secondDoc.children.firstOrNull as OrgSection;

      final agendaItems = agendaItemsFromSources([
        (section: firstSection, dataSource: AssetDataSource('first.org')),
        (section: secondSection, dataSource: AssetDataSource('second.org')),
      ], now: DateTime(2026, 9, 1, 0, 0));

      expect(agendaItems.map((item) => item.section), [
        firstSection,
        secondSection,
      ]);
      expect(agendaItems.map((item) => item.scheduledAt.start), [
        tz.TZDateTime.from(DateTime(2026, 9, 25, 8, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 25, 8, 0), tz.local),
      ]);
    });
    test('Includes entries at the current comparison point', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri 08:00>
''');
      final section = doc.children.firstOrNull as OrgSection;

      final agendaItems = agendaItemsFromSources([
        (section: section, dataSource: AssetDataSource('test.org')),
      ], now: DateTime(2026, 9, 25, 8, 0));

      expect(agendaItems, hasLength(1));
      expect(
        agendaItems.single.scheduledAt.start,
        tz.TZDateTime.from(DateTime(2026, 9, 25, 8, 0), tz.local),
      );
    });
    test('Includes overdue planned items throughout the current day', () {
      final scheduledDoc = OrgDocument.parse('''
* TODO Scheduled
SCHEDULED: <2026-09-24 Thu>
''');
      final deadlineDoc = OrgDocument.parse('''
* TODO Deadline
DEADLINE: <2026-09-24 Thu>
''');
      final scheduledSection = scheduledDoc.children.firstOrNull as OrgSection;
      final deadlineSection = deadlineDoc.children.firstOrNull as OrgSection;
      final now = DateTime(2026, 9, 25, 10);

      final agendaItems = agendaItemsFromSources([
        (
          section: scheduledSection,
          dataSource: AssetDataSource('scheduled.org'),
        ),
        (section: deadlineSection, dataSource: AssetDataSource('deadline.org')),
      ], now: now);

      expect(agendaItems.map((item) => item.scheduledAt.start), [
        tz.TZDateTime.from(DateTime(2026, 9, 25), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 25), tz.local),
      ]);
      expect(agendaItems.map((item) => item.scheduledAt.keyword), [
        'SCHEDULED:',
        'DEADLINE:',
      ]);
      expect(
        agendaItems.map((item) => item.scheduledAt.overdue),
        everyElement(true),
      );
    });
    test('Includes an overdue planned item with future occurrences', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
SCHEDULED: <2026-09-24 Thu>
<2026-09-26 Sat 08:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      final now = DateTime(2026, 9, 25, 10);

      final agendaItems = agendaItemsFromSources([
        (section: section, dataSource: AssetDataSource('test.org')),
      ], now: now);

      expect(agendaItems.map((item) => item.scheduledAt.start), [
        tz.TZDateTime.from(DateTime(2026, 9, 25), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 26, 8), tz.local),
      ]);
      expect(agendaItems.map((item) => item.scheduledAt.overdue), [
        true,
        false,
      ]);
    });
    test('All-day entries always sorted ahead of partial-day ones', () {
      final now = DateTime(2026, 9, 1);
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-25 Fri>--<2026-09-27 Sun>
<2026-09-26 Sat 10:00>
<2026-09-27 Sun 09:00>
''');
      final section = doc.children.firstOrNull as OrgSection;

      expect(section.occursAt(now: now), [
        _agendaSpan(
          DateTime(2026, 9, 25, 0, 0),
          DateTime(2026, 9, 26, 0, 0),
          last: false,
        ),
        _agendaSpan(
          DateTime(2026, 9, 26, 0, 0),
          DateTime(2026, 9, 27, 0, 0),
          chunkIdx: 1,
          last: false,
        ),
        _agendaSpan(DateTime(2026, 9, 26, 10, 0), DateTime(2026, 9, 26, 10, 0)),
        _agendaSpan(
          DateTime(2026, 9, 27, 0, 0),
          DateTime(2026, 9, 28, 0, 0),
          chunkIdx: 2,
        ),
        _agendaSpan(DateTime(2026, 9, 27, 9, 0), DateTime(2026, 9, 27, 9, 0)),
      ]);

      final agendaItems = agendaItemsFromSources([
        (section: section, dataSource: AssetDataSource('test.org')),
      ], now: now);
      expect(agendaItems.map((item) => item.scheduledAt.start), [
        tz.TZDateTime.from(DateTime(2026, 9, 25, 0, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 26, 0, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 26, 10, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 27, 0, 0), tz.local),
        tz.TZDateTime.from(DateTime(2026, 9, 27, 9, 0), tz.local),
      ]);
    });
    group('Modifiers', () {
      test('Simple with repeater', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun +1w>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(DateTime(2025, 10, 5), DateTime(2025, 10, 6)),
          _agendaSpan(DateTime(2025, 10, 12), DateTime(2025, 10, 13)),
          _agendaSpan(DateTime(2025, 10, 19), DateTime(2025, 10, 20)),
          _agendaSpan(DateTime(2025, 10, 26), DateTime(2025, 10, 27)),
          _agendaSpan(DateTime(2025, 11, 2), DateTime(2025, 11, 3)),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(DateTime(2027, 9, 5), DateTime(2027, 9, 6)),
        ]);
      });
      test('Simple with delay', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun -1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        final (timestamp, keyword) = section.activeTimestamps.single;
        expect(timestamp, isA<OrgSimpleTimestamp>());
        expect(keyword, isNull);
        expect(section.occursAt(now: now), [
          _agendaSpan(DateTime(2025, 10, 5), DateTime(2025, 10, 6)),
        ]);
      });
      test('Scheduled with delay', () {
        final doc = OrgDocument.parse('''* TODO foo
SCHEDULED: <2025-10-05 Sun -1d>''');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isTrue);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        final (timestamp, keyword) = section.activeTimestamps.single;
        expect(timestamp, isA<OrgSimpleTimestamp>());
        expect(keyword!.content, 'SCHEDULED:');
        expect(section.occursAt(now: now), [
          _agendaSpan(
            DateTime(2025, 10, 6),
            DateTime(2025, 10, 7),
            keyword: 'SCHEDULED:',
          ),
        ]);
      });
      test('Deadline with delay', () {
        final doc = OrgDocument.parse('''* TODO foo
DEADLINE: <2025-10-05 Sun -1d>''');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        final (timestamp, keyword) = section.activeTimestamps.single;
        expect(timestamp, isA<OrgSimpleTimestamp>());
        expect(keyword!.content, 'DEADLINE:');
        expect(section.occursAt(now: now), [
          _agendaSpan(
            DateTime(2025, 10, 4),
            DateTime(2025, 10, 5),
            keyword: 'DEADLINE:',
          ),
        ]);
      });
      test('Simple with repeater and delay', () {
        final doc = OrgDocument.parse('''* TODO foo
SCHEDULED: <2025-10-05 Sun +1w -1d>''');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isTrue);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(
            DateTime(2025, 10, 6),
            DateTime(2025, 10, 7),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 13),
            DateTime(2025, 10, 14),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 20),
            DateTime(2025, 10, 21),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 27),
            DateTime(2025, 10, 28),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 11, 3),
            DateTime(2025, 11, 4),
            keyword: 'SCHEDULED:',
          ),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(
            DateTime(2027, 9, 6),
            DateTime(2027, 9, 7),
            keyword: 'SCHEDULED:',
          ),
        ]);
      });
      test('Simple with repeater and one-time delay', () {
        final doc = OrgDocument.parse('''* TODO foo
SCHEDULED: <2025-10-05 Sun +1w --1d>''');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isTrue);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        final (timestamp, keyword) = section.activeTimestamps.single;
        expect(timestamp, isA<OrgSimpleTimestamp>());
        expect(keyword!.content, 'SCHEDULED:');
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(
            DateTime(2025, 10, 6),
            DateTime(2025, 10, 7),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 12),
            DateTime(2025, 10, 13),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 19),
            DateTime(2025, 10, 20),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 10, 26),
            DateTime(2025, 10, 27),
            keyword: 'SCHEDULED:',
          ),
          _agendaSpan(
            DateTime(2025, 11, 2),
            DateTime(2025, 11, 3),
            keyword: 'SCHEDULED:',
          ),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(
            DateTime(2027, 9, 5),
            DateTime(2027, 9, 6),
            keyword: 'SCHEDULED:',
          ),
        ]);
      });
      test('With repeater from many repeats ago', () {
        final doc = OrgDocument.parse('* TODO foo <2020-10-05 Sun +1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(DateTime(2020, 10, 5), DateTime(2020, 10, 6)),
          _agendaSpan(DateTime(2020, 10, 6), DateTime(2020, 10, 7)),
          _agendaSpan(DateTime(2020, 10, 7), DateTime(2020, 10, 8)),
          _agendaSpan(DateTime(2020, 10, 8), DateTime(2020, 10, 9)),
          _agendaSpan(DateTime(2020, 10, 9), DateTime(2020, 10, 10)),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(DateTime(2021, 1, 13), DateTime(2021, 1, 14)),
        ]);
      });
      test('With delay that makes it pending', () {
        final doc = OrgDocument.parse('''* TODO foo
SCHEDULED: <2025-09-30 Sun -1w>''');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isTrue);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now), [
          _agendaSpan(
            DateTime(2025, 10, 7),
            DateTime(2025, 10, 8),
            keyword: 'SCHEDULED:',
          ),
        ]);
      });
      test('Time range', () {
        final doc = OrgDocument.parse(
          '* TODO foo <2025-10-05 Sun 10:00-11:00 +1d>',
        );
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(
            DateTime(2025, 10, 5, 10, 0),
            DateTime(2025, 10, 5, 11, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 6, 10, 0),
            DateTime(2025, 10, 6, 11, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 7, 10, 0),
            DateTime(2025, 10, 7, 11, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 8, 10, 0),
            DateTime(2025, 10, 8, 11, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 9, 10, 0),
            DateTime(2025, 10, 9, 11, 0),
          ),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(
            DateTime(2026, 1, 13, 10, 0),
            DateTime(2026, 1, 13, 11, 0),
          ),
        ]);
      });
      test('Multiple', () {
        final doc = OrgDocument.parse(
          '* TODO foo <2025-10-05 Sun 10:00 +1d> <2026-10-05 Sun 10:00 +1d>',
        );
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.hasScheduled, isFalse);
        expect(section.hasClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.occursAt(now: now).take(5), [
          _agendaSpan(
            DateTime(2025, 10, 5, 10, 0),
            DateTime(2025, 10, 5, 10, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 6, 10, 0),
            DateTime(2025, 10, 6, 10, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 7, 10, 0),
            DateTime(2025, 10, 7, 10, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 8, 10, 0),
            DateTime(2025, 10, 8, 10, 0),
          ),
          _agendaSpan(
            DateTime(2025, 10, 9, 10, 0),
            DateTime(2025, 10, 9, 10, 0),
          ),
        ]);
        expect(section.occursAt(now: now).skip(100).take(1), [
          _agendaSpan(
            DateTime(2026, 1, 13, 10, 0),
            DateTime(2026, 1, 13, 10, 0),
          ),
        ]);
      });
    });
  });
}
