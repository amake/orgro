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
    group('Unordered', () {
      test('Toggle empty', () {
        final result = toggleUnorderedListItem(testValue('|'));
        expect(result, testValue('- |'));
      });
      test('Toggle before line break', () {
        final result = toggleUnorderedListItem(
          testValue('''|
'''),
        );
        expect(
          result,
          testValue('''- |
'''),
        );
      });
      test('Toggle list item', () {
        final result = toggleUnorderedListItem(testValue('foo |bar'));
        expect(result, testValue('- foo |bar'));
      });
      test('Toggle list item on existing item', () {
        final result = toggleUnorderedListItem(testValue('- foo |bar'));
        expect(result, testValue('foo |bar'));
      });
      test('Toggle ordered list to unordered list', () {
        final result = toggleUnorderedListItem(testValue('1. foo |bar'));
        expect(result, testValue('- foo |bar'));
      });
      test('Toggle list item with previous list item', () {
        final result = toggleUnorderedListItem(
          testValue('''
- item 1
item 2|'''),
        );
        expect(
          result,
          testValue('''
- item 1
- item 2|'''),
        );
      });
      test('Toggle list item with previous ordered list item', () {
        final result = toggleUnorderedListItem(
          testValue('''
1. item 1
item 2|'''),
        );
        expect(
          result,
          testValue('''
1. item 1
2. item 2|'''),
        );
      });
      test('Toggle middle list item with previous list item', () {
        final result = toggleUnorderedListItem(
          testValue('''
- item 1|
- item 2'''),
        );
        expect(
          result,
          testValue('''
item 1|
- item 2'''),
        );
      });
      test('Toggle list item with previous list item', () {
        final result = toggleUnorderedListItem(
          testValue('''
- item 1
item 2|'''),
        );
        expect(
          result,
          testValue('''
- item 1
- item 2|'''),
        );
      });
    });
    group('Ordered', () {
      test('Toggle ordered empty', () {
        final result = toggleOrderedListItem(testValue('|'));
        expect(result, testValue('1. |'));
      });
      test('Toggle ordered before line break', () {
        final result = toggleOrderedListItem(
          testValue('''|
'''),
        );
        expect(
          result,
          testValue('''1. |
'''),
        );
      });
      test('Toggle list item', () {
        final result = toggleOrderedListItem(testValue('foo |bar'));
        expect(result, testValue('1. foo |bar'));
      });
      test('Toggle list item on existing item', () {
        final result = toggleOrderedListItem(testValue('1. foo |bar'));
        expect(result, testValue('foo |bar'));
      });
      test('Toggle unordered list to ordered list', () {
        final result = toggleOrderedListItem(testValue('- foo |bar'));
        expect(result, testValue('1. foo |bar'));
      });

      test('Toggle list item with previous list item', () {
        final result = toggleOrderedListItem(
          testValue('''
1. item 1
item 2|'''),
        );
        expect(
          result,
          testValue('''
1. item 1
2. item 2|'''),
        );
      });
    });
  });
}
