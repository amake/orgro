import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/pages/editor/edits.dart';

import '../utils/editing.dart';

void main() {
  group('Fixups', () {
    group('List', () {
      test('Empty', () {
        final result = afterNewLineFixup(testValue('|'));
        expect(result, isNull);
      });
      test('Not a list', () {
        final result = afterNewLineFixup(
          testValue('''
foo
|'''),
        );
        expect(result, result);
      });
      test('Unordered list', () {
        final result = afterNewLineFixup(
          testValue('''
- foo
|'''),
        );
        expect(
          result,
          testValue('''
- foo
- |'''),
        );
      });
      test('Unordered list with checkbox', () {
        final result = afterNewLineFixup(
          testValue('''
- [ ] foo
|'''),
        );
        expect(
          result,
          testValue('''
- [ ] foo
- [ ] |'''),
        );
      });
      test('Ordered list', () {
        final result = afterNewLineFixup(
          testValue('''
1. foo
|'''),
        );
        expect(
          result,
          testValue('''
1. foo
2. |'''),
        );
      });
      test('Remove empty list item', () {
        final result = afterNewLineFixup(
          testValue('''
- foo
-${' '}
|'''),
        );
        expect(
          result,
          testValue('''
- foo
|'''),
        );
      });
      test('Remove empty middle list item', () {
        final result = afterNewLineFixup(
          testValue('''
- foo
-${' '}
|
- bar'''),
        );
        expect(
          result,
          testValue('''
- foo
|
- bar'''),
        );
      });
      test('Remove solitary empty list item', () {
        final result = afterNewLineFixup(
          testValue('''
-${' '}
|'''),
        );
        expect(result, testValue('|'));
      });
      test('Remove solitary empty checkbox list item', () {
        final result = afterNewLineFixup(
          testValue('''
- [ ]${' '}
|'''),
        );
        expect(result, testValue('|'));
      });
      test('Remove solitary empty checked checkbox list item', () {
        final result = afterNewLineFixup(
          testValue('''
- [X]${' '}
|'''),
        );
        expect(
          result,
          testValue('''
- [X]${' '}
- [ ] |'''),
        );
      });
      test('Remove solitary empty ordered list item', () {
        final result = afterNewLineFixup(
          testValue('''
1. ${' '}
|'''),
        );
        expect(result, testValue('|'));
      });
      test('Do not remove list item with empty body but present tag', () {
        final result = afterNewLineFixup(
          testValue('''
- foo ::
|'''),
        );
        expect(
          result,
          testValue('''
- foo ::
- |'''),
        );
      });
      test(
        'Do not remove ordered list item with empty body but present counter set',
        () {
          final result = afterNewLineFixup(
            testValue('''
20. [@20]
|'''),
          );
          expect(
            result,
            testValue('''
20. [@20]
21. |'''),
          );
        },
      );
    });
  });
}
