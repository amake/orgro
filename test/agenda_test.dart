import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/data_source.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 5), DateTime(2025, 10, 6), 0, true),
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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 5, 10, 1), DateTime(2025, 10, 5, 10, 1), 0, true),
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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 5, 10, 0), DateTime(2025, 10, 5, 10, 0), 0, true),
      ]);
    });
    test('Past', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-09-05 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [
        (DateTime(2025, 9, 5), DateTime(2025, 9, 6), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [
        (DateTime(2025, 9, 5), DateTime(2025, 9, 6), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 9, 5), DateTime(2025, 9, 6), 0, true),
        (DateTime(2025, 10, 10), DateTime(2025, 10, 11), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [
        (DateTime(2025, 9, 5), DateTime(2025, 9, 6), 0, true),
        (DateTime(2025, 9, 5), DateTime(2025, 9, 6), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 1, 10, 30), DateTime(2025, 10, 1, 12, 30), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 1, 9, 30), DateTime(2025, 10, 1, 12, 30), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 10), DateTime(2025, 10, 11), 0, true),
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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 10), DateTime(2025, 10, 11), 0, true),
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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, isEmpty);
    });

    test('Not scheduled', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, isEmpty);
    });
    test('Completed via CLOSED', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun> CLOSED: [2025-10-06 Tue]
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isTrue);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 5), DateTime(2025, 10, 6), 0, true),
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
      expect(section.isScheduled, isTrue);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [
        (DateTime(2025, 10, 5), DateTime(2025, 10, 6), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, isEmpty);
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, isEmpty);
    });
    test('Time range', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
<2026-09-21 Mon 17:00-22:00>
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isDone, isFalse);
      expect(section.isTodo, isTrue);
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.activeTimestamps, [isA<OrgTimeRangeTimestamp>()]);
      expect(section.scheduledAt, [
        (DateTime(2026, 9, 21, 17, 0), DateTime(2026, 9, 21, 22, 0), 0, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.activeTimestamps, [isA<OrgDateRangeTimestamp>()]);
      expect(section.scheduledAt, [
        (DateTime(2026, 9, 25, 8, 0), DateTime(2026, 9, 26, 0, 0), 0, false),
        (DateTime(2026, 9, 26, 0, 0), DateTime(2026, 9, 26, 14, 0), 1, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.activeTimestamps, [isA<OrgDateRangeTimestamp>()]);
      expect(section.scheduledAt, [
        (DateTime(2026, 9, 25, 8, 0), DateTime(2026, 9, 26, 0, 0), 0, false),
        (DateTime(2026, 9, 26, 0, 0), DateTime(2026, 9, 26, 7, 0), 1, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.activeTimestamps, [isA<OrgDateRangeTimestamp>()]);
      expect(section.scheduledAt, [
        (DateTime(2026, 9, 25, 8, 0), DateTime(2026, 9, 26, 0, 0), 0, false),
        (DateTime(2026, 9, 26, 0, 0), DateTime(2026, 9, 27, 0, 0), 1, false),
        (DateTime(2026, 9, 27, 0, 0), DateTime(2026, 9, 27, 14, 0), 2, true),
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
      expect(section.isScheduled, isFalse);
      expect(section.isClosed, isFalse);
      expect(section.isPending(now: now), isTrue);
      expect(section.activeTimestamps, [isA<OrgDateRangeTimestamp>()]);
      expect(section.scheduledAt, [
        (DateTime(2026, 9, 25, 0, 0), DateTime(2026, 9, 26, 0, 0), 0, false),
        (DateTime(2026, 9, 26, 0, 0), DateTime(2026, 9, 27, 0, 0), 1, false),
        (DateTime(2026, 9, 27, 0, 0), DateTime(2026, 9, 28, 0, 0), 2, true),
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

      expect(section.scheduledAt, [
        (DateTime(2026, 9, 25, 8, 0), DateTime(2026, 9, 26, 0, 0), 0, false),
        (DateTime(2026, 9, 26, 0, 0), DateTime(2026, 9, 27, 0, 0), 1, false),
        (DateTime(2026, 9, 26, 10, 0), DateTime(2026, 9, 26, 10, 0), 0, true),
        (DateTime(2026, 9, 27, 9, 0), DateTime(2026, 9, 27, 9, 0), 0, true),
        (DateTime(2026, 9, 27, 0, 0), DateTime(2026, 9, 27, 14, 0), 2, true),
      ]);

      final agendaItems = agendaItemsFromSources([
        (section: section, dataSource: AssetDataSource('test.org')),
      ], now: now);
      expect(agendaItems.map((item) => item.scheduledAt.$1), [
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
      expect(agendaItems.map((item) => item.scheduledAt.$1), [
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
        agendaItems.single.scheduledAt.$1,
        tz.TZDateTime.from(DateTime(2026, 9, 25, 8, 0), tz.local),
      );
    });
    group('Modifiers', () {
      test('Simple with repeater', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun +1w>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2025, 10, 5), DateTime(2025, 10, 6), 0, true),
          (DateTime(2025, 10, 12), DateTime(2025, 10, 13), 0, true),
          (DateTime(2025, 10, 19), DateTime(2025, 10, 20), 0, true),
          (DateTime(2025, 10, 26), DateTime(2025, 10, 27), 0, true),
          (DateTime(2025, 11, 2), DateTime(2025, 11, 3), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2027, 9, 5), DateTime(2027, 9, 6), 0, true),
        ]);
      });
      test('Simple with delay', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun -1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt, [
          (DateTime(2025, 10, 6), DateTime(2025, 10, 7), 0, true),
        ]);
      });
      test('Simple with repeater and delay', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun +1w -1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2025, 10, 6), DateTime(2025, 10, 7), 0, true),
          (DateTime(2025, 10, 13), DateTime(2025, 10, 14), 0, true),
          (DateTime(2025, 10, 20), DateTime(2025, 10, 21), 0, true),
          (DateTime(2025, 10, 27), DateTime(2025, 10, 28), 0, true),
          (DateTime(2025, 11, 3), DateTime(2025, 11, 4), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2027, 9, 6), DateTime(2027, 9, 7), 0, true),
        ]);
      });
      test('Simple with repeater and one-time delay', () {
        final doc = OrgDocument.parse('* TODO foo <2025-10-05 Sun +1w --1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2025, 10, 6), DateTime(2025, 10, 7), 0, true),
          (DateTime(2025, 10, 12), DateTime(2025, 10, 13), 0, true),
          (DateTime(2025, 10, 19), DateTime(2025, 10, 20), 0, true),
          (DateTime(2025, 10, 26), DateTime(2025, 10, 27), 0, true),
          (DateTime(2025, 11, 2), DateTime(2025, 11, 3), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2027, 9, 5), DateTime(2027, 9, 6), 0, true),
        ]);
      });
      test('With repeater from many repeats ago', () {
        final doc = OrgDocument.parse('* TODO foo <2020-10-05 Sun +1d>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2020, 10, 5), DateTime(2020, 10, 6), 0, true),
          (DateTime(2020, 10, 6), DateTime(2020, 10, 7), 0, true),
          (DateTime(2020, 10, 7), DateTime(2020, 10, 8), 0, true),
          (DateTime(2020, 10, 8), DateTime(2020, 10, 9), 0, true),
          (DateTime(2020, 10, 9), DateTime(2020, 10, 10), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2021, 1, 13), DateTime(2021, 1, 14), 0, true),
        ]);
      });
      test('With delay that makes it pending', () {
        final doc = OrgDocument.parse('* TODO foo <2025-09-30 Sun -1w>');
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt, [
          (DateTime(2025, 10, 7), DateTime(2025, 10, 8), 0, true),
        ]);
      });
      test('Time range', () {
        final doc = OrgDocument.parse(
          '* TODO foo <2025-10-05 Sun 10:00-11:00 +1d>',
        );
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2025, 10, 5, 10, 0), DateTime(2025, 10, 5, 11, 0), 0, true),
          (DateTime(2025, 10, 6, 10, 0), DateTime(2025, 10, 6, 11, 0), 0, true),
          (DateTime(2025, 10, 7, 10, 0), DateTime(2025, 10, 7, 11, 0), 0, true),
          (DateTime(2025, 10, 8, 10, 0), DateTime(2025, 10, 8, 11, 0), 0, true),
          (DateTime(2025, 10, 9, 10, 0), DateTime(2025, 10, 9, 11, 0), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2026, 1, 13, 10, 0), DateTime(2026, 1, 13, 11, 0), 0, true),
        ]);
      });
      test('Multiple', () {
        final doc = OrgDocument.parse(
          '* TODO foo <2025-10-05 Sun 10:00 +1d> <2026-10-05 Sun 10:00 +1d>',
        );
        final section = doc.children.firstOrNull as OrgSection;
        expect(section.isDone, isFalse);
        expect(section.isTodo, isTrue);
        expect(section.isScheduled, isFalse);
        expect(section.isClosed, isFalse);
        expect(section.isPending(now: now), isTrue);
        expect(section.scheduledAt.take(5), [
          (DateTime(2025, 10, 5, 10, 0), DateTime(2025, 10, 5, 10, 0), 0, true),
          (DateTime(2025, 10, 6, 10, 0), DateTime(2025, 10, 6, 10, 0), 0, true),
          (DateTime(2025, 10, 7, 10, 0), DateTime(2025, 10, 7, 10, 0), 0, true),
          (DateTime(2025, 10, 8, 10, 0), DateTime(2025, 10, 8, 10, 0), 0, true),
          (DateTime(2025, 10, 9, 10, 0), DateTime(2025, 10, 9, 10, 0), 0, true),
        ]);
        expect(section.scheduledAt.skip(100).take(1), [
          (DateTime(2026, 1, 13, 10, 0), DateTime(2026, 1, 13, 10, 0), 0, true),
        ]);
      });
    });
  });
}
