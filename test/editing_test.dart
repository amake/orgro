import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/checkbox.dart';
import 'package:orgro/src/pages/editor/util.dart';

void main() {
  group('Offset', () {
    test('Find node', () {
      final doc = OrgDocument.parse('''

* foo
- bar
1. baz ~bazinga~
''');
      expect(doc.nodesAtOffset(0), [
        isA<OrgPlainText>(),
        isA<OrgContent>(),
        isA<OrgParagraph>(),
        isA<OrgContent>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(1), [
        isA<OrgHeadline>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(2), [
        isA<OrgHeadline>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(3), [
        isA<OrgPlainText>(),
        isA<OrgContent>(),
        isA<OrgHeadline>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(7), [
        isA<OrgListUnorderedItem>(),
        isA<OrgList>(),
        isA<OrgContent>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(9), [
        isA<OrgPlainText>(),
        isA<OrgContent>(),
        isA<OrgListUnorderedItem>(),
        isA<OrgList>(),
        isA<OrgContent>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(13), [
        isA<OrgListOrderedItem>(),
        isA<OrgList>(),
        isA<OrgContent>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(16), [
        isA<OrgPlainText>(),
        isA<OrgContent>(),
        isA<OrgListOrderedItem>(),
        isA<OrgList>(),
        isA<OrgContent>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(20), [
        isA<OrgMarkup>(),
        isA<OrgContent>(),
        isA<OrgListOrderedItem>(),
        isA<OrgList>(),
        isA<OrgContent>(),
        isA<OrgSection>(),
        isA<OrgDocument>(),
      ]);
      expect(doc.nodesAtOffset(10000), isEmpty);
    });
  });
  group('checkbox', () {
    group('insert at point', () {
      test('add to list item', () {
        expect(insertCheckboxAtPoint('- foo', 0), ('- [ ] foo', 4));
        expect(insertCheckboxAtPoint('1. foo', 3), ('1. [ ] foo', 7));
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
  });
}
