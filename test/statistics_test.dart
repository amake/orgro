import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/statistics.dart';

void main() {
  group('Statistics', () {
    group('Lists', () {
      test('Normalize empty', () {
        final doc = OrgDocument.parse('''
[%] and [/]
- foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/0]
- foo
''');
      });
      test('No action', () {
        final doc = OrgDocument.parse('''
[0%] and [0/1]
- [ ] foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/1]
- [ ] foo
''');
      });
      test('Complete', () {
        final doc = OrgDocument.parse('''
[0%] and [0/1]
- [X] foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[100%] and [1/1]
- [X] foo
''');
      });
      test('Incomplete', () {
        final doc = OrgDocument.parse('''
[100%] and [1/1]
- [ ] foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/1]
- [ ] foo
''');
      });
      test('Partial', () {
        final doc = OrgDocument.parse('''
[0%] and [0/1]
- [ ] foo [0%] and [0/2]
  - [X] bar
  - [ ] baz
''');
        final (path: _, node: target) =
            doc.find<OrgListItem>((item) => item.body!.toMarkup() == 'bar\n')!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/1]
- [-] foo [50%] and [1/2]
  - [X] bar
  - [ ] baz
''');
      });
      test('Deep partial', () {
        final doc = OrgDocument.parse('''
[0%] and [0/1]
- [ ] foo [0%] and [0/2]
  - [X] bar
  - [ ] baz
    - [X] bazinga
    - [ ] bazoonga
''');
        final (path: _, node: target) =
            doc.find<OrgListItem>((item) => item.body!.toMarkup() == 'bar\n')!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/1]
- [-] foo [50%] and [1/2]
  - [X] bar
  - [-] baz
    - [X] bazinga
    - [ ] bazoonga
''');
      });
      test('Cascade to complete', () {
        final doc = OrgDocument.parse('''
[0%] and [0/1]
- [-] foo [0%] and [0/2]
  - [X] bar
  - [-] baz
    - [X] bazinga
    - [X] bazoonga
''');
        final (path: _, node: target) =
            doc.find<OrgListItem>(
              (item) => item.body!.toMarkup() == 'bazoonga\n',
            )!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[100%] and [1/1]
- [X] foo [100%] and [2/2]
  - [X] bar
  - [X] baz
    - [X] bazinga
    - [X] bazoonga
''');
      });
      test('Cascade to incomplete', () {
        final doc = OrgDocument.parse('''
[100%] and [1/1]
- [X] foo [100%] and [2/2]
  - [X] bar
  - [X] baz
    - [X] bazinga
    - [ ] bazoonga
''');
        final (path: _, node: target) =
            doc.find<OrgListItem>(
              (item) => item.body!.toMarkup() == 'bazoonga\n',
            )!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
[0%] and [0/1]
- [-] foo [50%] and [1/2]
  - [X] bar
  - [-] baz
    - [X] bazinga
    - [ ] bazoonga
''');
      });
      test('In headline', () {
        final doc = OrgDocument.parse('''
* headline [%] and [/]
- [X] foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
* headline [100%] and [1/1]
- [X] foo
''');
      });
      test('In headline but ignored', () {
        final doc = OrgDocument.parse('''
* headline [%] and [/]
  :PROPERTIES:
  :COOKIE_DATA: todo
  :END:
- [X] foo
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
* headline [%] and [/]
  :PROPERTIES:
  :COOKIE_DATA: todo
  :END:
- [X] foo
''');
      });
      test('Root scope', () {
        final doc = OrgDocument.parse('''
Root [%] and [/]
- [X] foo
* headline [%] and [/]
** subheadline [%] and [/]
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
Root [100%] and [1/1]
- [X] foo
* headline [%] and [/]
** subheadline [%] and [/]
''');
      });
      test('Section scope', () {
        final doc = OrgDocument.parse('''
Root [%] and [/]
* headline [%] and [/]
- [X] foo
** subheadline [%] and [/]
''');
        final (path: _, node: target) = doc.find<OrgListItem>((_) => true)!;
        final result = recalculateListStats(doc, target);
        expect(result.toMarkup(), '''
Root [%] and [/]
* headline [100%] and [1/1]
- [X] foo
** subheadline [%] and [/]
''');
      });
    });
    group('Headlines', () {
      test('Normalize empty', () {
        final doc = OrgDocument.parse('''
* top [%] and [/]
** foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [0%] and [0/0]
** foo
''');
      });
      test('No action', () {
        final doc = OrgDocument.parse('''
* top [0%] and [0/1]
** TODO foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [0%] and [0/1]
** TODO foo
''');
      });
      test('Complete', () {
        final doc = OrgDocument.parse('''
* top [0%] and [0/1]
** DONE foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [100%] and [1/1]
** DONE foo
''');
      });
      test('Incomplete', () {
        final doc = OrgDocument.parse('''
* top [100%] and [1/1]
** TODO foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [0%] and [0/1]
** TODO foo
''');
      });
      test('Remove keyword', () {
        final doc = OrgDocument.parse('''
* top [100%] and [1/1]
** foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [0%] and [0/0]
** foo
''');
      });
      test('Ignored', () {
        final doc = OrgDocument.parse('''
* top [%] and [/]
  :PROPERTIES:
  :COOKIE_DATA: checkbox
  :END:
** TODO foo
''');
        final (path: _, node: target) =
            doc.find<OrgHeadline>((headline) => headline.rawTitle == 'foo')!;
        final result = recalculateHeadlineStats(doc, target);
        expect(result.toMarkup(), '''
* top [%] and [/]
  :PROPERTIES:
  :COOKIE_DATA: checkbox
  :END:
** TODO foo
''');
      });
    });
  });
}
