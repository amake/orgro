import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/pages/editor/edits.dart';

import '../utils/editing.dart';

void main() {
  group('Headline editing', () {
    test('Insert at empty', () {
      final result = insertHeadline(testValue('|'));
      expect(result, testValue('* |'));
    });
    test('Insert before line break', () {
      final result = insertHeadline(
        testValue('''|
'''),
      );
      expect(
        result,
        testValue('''* |
'''),
      );
    });
    test('Insert', () {
      final result = insertHeadline(testValue('foo |bar'));
      expect(result, testValue('* foo |bar'));
    });
    test('Insert on existing headline', () {
      final result = insertHeadline(testValue('* foo |bar'));
      expect(result, testValue('** foo |bar'));
    });
    test('Insert headline with previous headline', () {
      final result = insertHeadline(
        testValue('''
** item 1
item 2|'''),
      );
      expect(
        result,
        testValue('''
** item 1
** item 2|'''),
      );
    });
    test('Insert middle headline with previous headline', () {
      final result = insertHeadline(
        testValue('''
* item 1|
* item 2'''),
      );
      expect(
        result,
        testValue('''
** item 1|
* item 2'''),
      );
    });
  });
  group('Indentation', () {
    test('Indent section', () {
      final result = changeIndent(testValue('* foo |bar'), true);
      expect(result, testValue('** foo |bar'));
    });
    test('Deindent section', () {
      final result = changeIndent(testValue('*** foo |bar'), false);
      expect(result, testValue('** foo |bar'));
    });
    test('Deindent base section', () {
      final result = changeIndent(testValue('* foo |bar'), false);
      expect(result, isNull);
    });
  });
}
