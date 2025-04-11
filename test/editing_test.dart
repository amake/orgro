import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/checkbox.dart';
import 'package:orgro/src/pages/editor/util.dart';

Matcher nodeAt(Type type, {required int start, required int end}) =>
    predicate<({OrgNode node, NodeSpan span})>(
      (node) =>
          node.node.runtimeType == type &&
          node.span.start == start &&
          node.span.end == end,
      'is $type from $start to $end',
    );

void main() {
  group('Find nodes', () {
    test('Offset', () {
      final doc = OrgDocument.parse('''

* foo
- bar
1. baz ~bazinga~
''');
      expect(doc.nodesAtOffset(0), [
        nodeAt(OrgPlainText, start: 0, end: 1),
        nodeAt(OrgContent, start: 0, end: 1),
        nodeAt(OrgParagraph, start: 0, end: 1),
        nodeAt(OrgContent, start: 0, end: 1),
        nodeAt(OrgDocument, start: 0, end: 1),
      ]);
      expect(doc.nodesAtOffset(1), [
        nodeAt(OrgHeadline, start: 1, end: 4),
        nodeAt(OrgSection, start: 1, end: 4),
        nodeAt(OrgDocument, start: 0, end: 4),
      ]);
      expect(doc.nodesAtOffset(2), [
        nodeAt(OrgHeadline, start: 1, end: 4),
        nodeAt(OrgSection, start: 1, end: 4),
        nodeAt(OrgDocument, start: 0, end: 4),
      ]);
      expect(doc.nodesAtOffset(3), [
        nodeAt(OrgPlainText, start: 3, end: 6),
        nodeAt(OrgContent, start: 3, end: 6),
        nodeAt(OrgHeadline, start: 1, end: 7),
        nodeAt(OrgSection, start: 1, end: 7),
        nodeAt(OrgDocument, start: 0, end: 7),
      ]);
      expect(doc.nodesAtOffset(7), [
        nodeAt(OrgListUnorderedItem, start: 7, end: 9),
        nodeAt(OrgList, start: 7, end: 9),
        nodeAt(OrgContent, start: 7, end: 9),
        nodeAt(OrgSection, start: 1, end: 9),
        nodeAt(OrgDocument, start: 0, end: 9),
      ]);
      expect(doc.nodesAtOffset(9), [
        nodeAt(OrgPlainText, start: 9, end: 13),
        nodeAt(OrgContent, start: 9, end: 13),
        nodeAt(OrgListUnorderedItem, start: 7, end: 13),
        nodeAt(OrgList, start: 7, end: 13),
        nodeAt(OrgContent, start: 7, end: 13),
        nodeAt(OrgSection, start: 1, end: 13),
        nodeAt(OrgDocument, start: 0, end: 13),
      ]);
      expect(doc.nodesAtOffset(13), [
        nodeAt(OrgListOrderedItem, start: 13, end: 16),
        nodeAt(OrgList, start: 7, end: 16),
        nodeAt(OrgContent, start: 7, end: 16),
        nodeAt(OrgSection, start: 1, end: 16),
        nodeAt(OrgDocument, start: 0, end: 16),
      ]);
      expect(doc.nodesAtOffset(16), [
        nodeAt(OrgPlainText, start: 16, end: 20),
        nodeAt(OrgContent, start: 16, end: 20),
        nodeAt(OrgListOrderedItem, start: 13, end: 20),
        nodeAt(OrgList, start: 7, end: 20),
        nodeAt(OrgContent, start: 7, end: 20),
        nodeAt(OrgSection, start: 1, end: 20),
        nodeAt(OrgDocument, start: 0, end: 20),
      ]);
      expect(doc.nodesAtOffset(20), [
        nodeAt(OrgMarkup, start: 20, end: 22),
        nodeAt(OrgContent, start: 16, end: 22),
        nodeAt(OrgListOrderedItem, start: 13, end: 22),
        nodeAt(OrgList, start: 7, end: 22),
        nodeAt(OrgContent, start: 7, end: 22),
        nodeAt(OrgSection, start: 1, end: 22),
        nodeAt(OrgDocument, start: 0, end: 22),
      ]);
      expect(doc.nodesAtOffset(10000), isEmpty);
    });
    test('Range', () {
      final doc = OrgDocument.parse('''

* foo
- bar
1. baz ~bazinga~
''');
      expect(doc.nodesInRange(0, 0), [
        nodeAt(OrgPlainText, start: 0, end: 1),
        nodeAt(OrgContent, start: 0, end: 1),
        nodeAt(OrgParagraph, start: 0, end: 1),
        nodeAt(OrgContent, start: 0, end: 1),
        nodeAt(OrgDocument, start: 0, end: 1),
      ]);
      expect(doc.nodesInRange(1, 7), [
        nodeAt(OrgPlainText, start: 3, end: 6),
        nodeAt(OrgContent, start: 3, end: 6),
        nodeAt(OrgHeadline, start: 1, end: 7),
        nodeAt(OrgListUnorderedItem, start: 7, end: 9),
        nodeAt(OrgList, start: 7, end: 9),
        nodeAt(OrgContent, start: 7, end: 9),
        nodeAt(OrgSection, start: 1, end: 9),
        nodeAt(OrgDocument, start: 0, end: 9),
      ]);
      expect(doc.nodesInRange(17, 22), [
        nodeAt(OrgPlainText, start: 16, end: 20),
        nodeAt(OrgPlainText, start: 21, end: 28),
        nodeAt(OrgContent, start: 21, end: 28),
        nodeAt(OrgMarkup, start: 20, end: 29),
        nodeAt(OrgContent, start: 16, end: 29),
        nodeAt(OrgListOrderedItem, start: 13, end: 29),
        nodeAt(OrgList, start: 7, end: 29),
        nodeAt(OrgContent, start: 7, end: 29),
        nodeAt(OrgSection, start: 1, end: 29),
        nodeAt(OrgDocument, start: 0, end: 29),
      ]);
      expect(doc.nodesInRange(10000, 10001), isEmpty);
    });
  });
  group('checkbox', () {
    group('insert at point', () {
      test('add to list item', () {
        expect(insertCheckboxAtPoint('- foo', 0), ('- [ ] foo', 9));
        expect(insertCheckboxAtPoint('1. foo', 3), ('1. [ ] foo', 10));
        expect(insertCheckboxAtPoint('''
1. foo

   bar''', 12), ('1. [ ] foo\n\n   bar', 18));
      });
      test('insert below list item', () {
        // TODO: Make it work even without the trailing new line?
        expect(insertCheckboxAtPoint('- [ ] foo\n', 4), (
          '''
- [ ] foo
- [ ]${' '}
''',
          16,
        ));
        expect(insertCheckboxAtPoint('1. [ ] foo\n', 7), (
          '''
1. [ ] foo
2. [ ]${' '}
''',
          18,
        ));
      });
      test('insert at end of list', () {
        expect(insertCheckboxAtPoint('- foo\n\n', 6), (
          '''
- foo
- [ ]${' '}

''',
          12,
        ));
        expect(insertCheckboxAtPoint('1. foo\n\n', 7), (
          '''
1. foo
2. [ ]${' '}

''',
          14,
        ));
      });
      test('convert paragraph to list item', () {
        expect(insertCheckboxAtPoint('foo', 0), ('- [ ] foo', 9));
      });
    });
    group('insert over range', () {
      test('add to list item', () {
        expect(insertCheckboxOverRange('- foo', 0, 0), ('- [ ] foo', 9));
        expect(insertCheckboxOverRange('1. foo', 3, 3), ('1. [ ] foo', 10));
        expect(
          insertCheckboxOverRange(
            '''
1. foo
2. bar
3. baz
''',
            2,
            12,
          ),
          (
            '''
1. [ ] foo
2. [ ] bar
3. baz
''',
            22,
          ),
        );
      });
      test('convert paragraph to list item', () {
        expect(insertCheckboxOverRange('foo', 0, 3), ('- [ ] foo', 9));
        expect(
          insertCheckboxOverRange(
            '''
foo

bar

baz
''',
            1,
            8,
          ),
          (
            '''
- [ ] foo

- [ ] bar

baz
''',
            22,
          ),
        );
      });
      test('mixed content', () {
        expect(insertCheckboxOverRange('foo', 0, 3), ('- [ ] foo', 9));
        expect(
          insertCheckboxOverRange(
            '''
- foo

1. bar

baz
''',
            1,
            8,
          ),
          (
            '''
- [ ] foo

1. [ ] bar

baz
''',
            22,
          ),
        );
        expect(
          insertCheckboxOverRange(
            '''
- foo
  - bar

baz
''',
            1,
            16,
          ),
          (
            '''
- [ ] foo
  - [ ] bar

- [ ] baz
''',
            33,
          ),
        );
        expect(
          insertCheckboxOverRange(
            '''
- foo
  - bar

baz
''',
            10,
            12,
          ),
          (
            '''
- foo
  - [ ] bar

baz
''',
            18,
          ),
        );
      });
    });
  });
}
