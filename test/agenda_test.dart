import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/agenda.dart';

void main() {
  group('Section pending', () {
    final now = DateTime(2025, 10, 1, 10, 0);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 5)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 5, 10, 1)]);
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
      expect(section.scheduledAt, [DateTime(2025, 9, 5)]);
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
      expect(section.scheduledAt, [DateTime(2025, 9, 5)]);
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
        DateTime(2025, 9, 5),
        DateTime(2025, 10, 10),
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
      expect(section.scheduledAt, [DateTime(2025, 9, 5), DateTime(2025, 9, 5)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 1, 10, 30)]);
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
      expect(section.isPending(now: now), isFalse);
      expect(section.scheduledAt, [DateTime(2025, 10, 1, 9, 30)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 10)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 10)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 5)]);
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
      expect(section.scheduledAt, [DateTime(2025, 10, 5)]);
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
  });
}
