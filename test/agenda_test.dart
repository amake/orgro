import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/agenda.dart';

void main() {
  group('Section pending', () {
    final now = DateTime(2025, 10, 1);
    test('Pending', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-10-05 Sun>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isPending(now: now), isTrue);
    });
    test('Past', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  SCHEDULED: <2025-09-05 Fri>
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isPending(now: now), isFalse);
    });
    test('Not scheduled', () {
      final doc = OrgDocument.parse('''
* TODO Do the thing
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isPending(now: now), isFalse);
    });
    test('Not TODO', () {
      final doc = OrgDocument.parse('''
* Do the thing
  foo
''');
      final section = doc.children.firstOrNull as OrgSection;
      expect(section.isPending(now: now), isFalse);
    });
  });
}
