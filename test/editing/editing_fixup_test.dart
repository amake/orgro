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
        expect(
          result,
          testValue('''foo
|'''),
        );
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
    });
  });
}
