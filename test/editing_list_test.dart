import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/pages/editor/edits.dart';

TextEditingValue testValue(String text) {
  final cleaned = text.replaceAll('|', '');
  final baseOffset = text.indexOf('|');
  final cursorCount = text.length - cleaned.length;
  assert(cursorCount == 1 || cursorCount == 2);
  final extentOffset = cursorCount == 2
      ? text.lastIndexOf('|') - 1
      : baseOffset;
  return TextEditingValue(
    text: cleaned,
    selection: TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
    ),
  );
}

void main() {
  group('List editing', () {
    test('Toggle unordered empty', () {
      final result = toggleListItem(testValue('|'), false);
      expect(result, testValue('- |'));
    });
    test('Toggle ordered empty', () {
      final result = toggleListItem(testValue('|'), true);
      expect(result, testValue('1. |'));
    });
    test('Toggle unordered before line break', () {
      final result = toggleListItem(
        testValue('''|
'''),
        false,
      );
      expect(
        result,
        testValue('''- |
'''),
      );
    });
    test('Toggle ordered before line break', () {
      final result = toggleListItem(
        testValue('''|
'''),
        true,
      );
      expect(
        result,
        testValue('''1. |
'''),
      );
    });
    test('Toggle unordered list item', () {
      final result = toggleListItem(testValue('foo |bar'), false);
      expect(result, testValue('- foo |bar'));
    });
    test('Toggle ordered list item', () {
      final result = toggleListItem(testValue('foo |bar'), true);
      expect(result, testValue('1. foo |bar'));
    });
    test('Toggle unordered list item on existing item', () {
      final result = toggleListItem(testValue('- foo |bar'), false);
      expect(result, testValue('foo |bar'));
    });
    test('Toggle ordered list item on existing item', () {
      final result = toggleListItem(testValue('1. foo |bar'), true);
      expect(result, testValue('foo |bar'));
    });
    test('Toggle unordered list to ordered list', () {
      final result = toggleListItem(testValue('- foo |bar'), true);
      expect(result, testValue('1. foo |bar'));
    });
    test('Toggle ordered list to unordered list', () {
      final result = toggleListItem(testValue('1. foo |bar'), false);
      expect(result, testValue('- foo |bar'));
    });
    test('Toggle unordered list item with previous list item', () {
      final result = toggleListItem(
        testValue('''
- item 1
item 2|'''),
        false,
      );
      expect(
        result,
        testValue('''
- item 1
- item 2|'''),
      );
    });
    test('Toggle ordered list item with previous list item', () {
      final result = toggleListItem(
        testValue('''
1. item 1
item 2|'''),
        true,
      );
      expect(
        result,
        testValue('''
1. item 1
2. item 2|'''),
      );
    });
    // TODO(aaron): Are these what we want?
    test('Toggle unordered list item with previous ordered list item', () {
      final result = toggleListItem(
        testValue('''
1. item 1
item 2|'''),
        false,
      );
      expect(
        result,
        testValue('''
1. item 1
2. item 2|'''),
      );
    });
    test('Toggle ordered list item with previous unordered list item', () {
      final result = toggleListItem(
        testValue('''
- item 1
item 2|'''),
        true,
      );
      expect(
        result,
        testValue('''
- item 1
- item 2|'''),
      );
    });
    test(
      'Toggle middle unordered list item with previous unordered list item',
      () {
        final result = toggleListItem(
          testValue('''
- item 1|
- item 2'''),
          false,
        );
        expect(
          result,
          testValue('''
item 1|
- item 2'''),
        );
      },
    );
  });
}
