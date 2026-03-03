import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/document/transclusion.dart';

void main() {
  group(':lines', () {
    final content = '''a
b
c''';
    test('simple', () {
      expect(extractLines(content, null), content);
      expect(extractLines(content, '1-'), content);
      expect(extractLines(content, '-3'), content);
      expect(extractLines(content, '2-'), 'b\nc');
      expect(extractLines(content, '-2'), 'a\nb\n');
      expect(extractLines(content, '2-2'), 'b\n');
      expect(extractLines(content, '3-3'), 'c');
      expect(extractLines(content, '4-'), '\n');
      expect(extractLines(content, '-4'), content);
      expect(extractLines(content, '1-1'), 'a\n');
    });
    test('invalid', () {
      expect(extractLines(content, ''), content);
      expect(extractLines(content, 'foo'), content);
      expect(extractLines(content, '1'), content);
      expect(extractLines(content, '-'), content);
      expect(extractLines(content, '1-2-3'), content);
    });
  });
  group(':level', () {
    final markup = '''* a
** b
*** c''';
    final doc = OrgDocument.parse(markup);
    test('simple', () {
      expect(applyLevel(doc, 1).toMarkup(), markup);
      expect(applyLevel(doc, 2).toMarkup(), '''** a
*** b
**** c''');
      expect(applyLevel(doc, 3).toMarkup(), '''*** a
**** b
***** c''');
    });
    test('section', () {
      final section = doc.sections[0].sections[0];
      expect(applyLevel(section, 1).toMarkup(), '* b\n** c');
      expect(applyLevel(section, 2).toMarkup(), '** b\n*** c');
      expect(applyLevel(section, 3).toMarkup(), '*** b\n**** c');
      expect(applyLevel(section, 4).toMarkup(), '**** b\n***** c');
    });
    test('invalid', () {
      expect(applyLevel(doc, -1).toMarkup(), markup);
      expect(applyLevel(doc, 0).toMarkup(), markup);
      expect(applyLevel(doc, 10).toMarkup(), markup);
    });
    test('decrease', () {
      final markup = '''*** a
***** b
******* c''';
      final doc = OrgDocument.parse(markup);
      expect(applyLevel(doc, 2).toMarkup(), '''** a
**** b
****** c''');
      expect(applyLevel(doc, 1).toMarkup(), '''* a
*** b
***** c''');
    });
  });
}
