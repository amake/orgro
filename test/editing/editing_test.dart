import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/pages/editor/edits.dart';

import '../utils/editing.dart';

void main() {
  group('Editing', () {
    group('Bold', () {
      test('Bold selection', () {
        final result = makeBold(testValue('foo |bar|'));
        expect(result, testValue('foo *bar|*'));
      });
      test('Bold empty selection', () {
        final result = makeBold(testValue('foo bar|'));
        expect(result, testValue('foo bar*|*'));
      });
      test('Bold empty', () {
        final result = makeBold(testValue('|'));
        expect(result, testValue('*|*'));
      });
    });
    group('Italic', () {
      test('Italic selection', () {
        final result = makeItalic(testValue('foo |bar|'));
        expect(result, testValue('foo /bar|/'));
      });
      test('Italic empty selection', () {
        final result = makeItalic(testValue('foo bar|'));
        expect(result, testValue('foo bar/|/'));
      });
      test('Italic empty', () {
        final result = makeItalic(testValue('|'));
        expect(result, testValue('/|/'));
      });
    });
    group('Underline', () {
      test('Underline selection', () {
        final result = makeUnderline(testValue('foo |bar|'));
        expect(result, testValue('foo _bar|_'));
      });
      test('Underline empty selection', () {
        final result = makeUnderline(testValue('foo bar|'));
        expect(result, testValue('foo bar_|_'));
      });
      test('Underline empty', () {
        final result = makeUnderline(testValue('|'));
        expect(result, testValue('_|_'));
      });
    });
    group('Strikethrough', () {
      test('Strikethrough selection', () {
        final result = makeStrikethrough(testValue('foo |bar|'));
        expect(result, testValue('foo +bar|+'));
      });
      test('Strikethrough empty selection', () {
        final result = makeStrikethrough(testValue('foo bar|'));
        expect(result, testValue('foo bar+|+'));
      });
      test('Strikethrough empty', () {
        final result = makeStrikethrough(testValue('|'));
        expect(result, testValue('+|+'));
      });
    });
    group('Code', () {
      test('Code selection', () {
        final result = makeCode(testValue('foo |bar|'));
        expect(result, testValue('foo ~bar|~'));
      });
      test('Code empty selection', () {
        final result = makeCode(testValue('foo bar|'));
        expect(result, testValue('foo bar~|~'));
      });
      test('Code empty', () {
        final result = makeCode(testValue('|'));
        expect(result, testValue('~|~'));
      });
    });
    group('Subscript', () {
      test('Subscript selection', () {
        final result = makeSubscript(testValue('foo |bar|'));
        expect(result, testValue('foo _{bar|}'));
      });
      test('Subscript empty selection', () {
        final result = makeSubscript(testValue('foo bar|'));
        expect(result, testValue('foo bar_{|}'));
      });
      test('Subscript empty', () {
        final result = makeSubscript(testValue('|'));
        expect(result, testValue('_{|}'));
      });
    });
    group('Superscript', () {
      test('Superscript selection', () {
        final result = makeSuperscript(testValue('foo |bar|'));
        expect(result, testValue('foo ^{bar|}'));
      });
      test('Superscript empty selection', () {
        final result = makeSuperscript(testValue('foo bar|'));
        expect(result, testValue('foo bar^{|}'));
      });
      test('Superscript empty', () {
        final result = makeSuperscript(testValue('|'));
        expect(result, testValue('^{|}'));
      });
    });
    group('Link', () {
      test('Link with URL selection', () async {
        final result = await insertLink(
          testValue('foo |https://example.com/|'),
          null,
        );
        expect(result, testValue('foo [[https://example.com/][description|]]'));
      });
      test('Link with URL selection and clipboard URL', () async {
        final result = await insertLink(
          testValue('foo |https://example.com/|'),
          'https://other.com/',
        );
        expect(result, testValue('foo [[https://example.com/][description|]]'));
      });
      test('Link with non-URL selection', () async {
        final result = await insertLink(testValue('foo |bar|'), null);
        expect(result, testValue('foo [[URL][bar|]]'));
      });
      test('Link with non-URL selection and clipboard URL', () async {
        final result = await insertLink(
          testValue('foo |bar|'),
          'https://example.com/',
        );
        expect(result, testValue('foo [[https://example.com/][bar|]]'));
      });
      test('Link with empty selection with clipboard URL', () async {
        final result = await insertLink(
          testValue('foo bar|'),
          'https://example.com/',
        );
        expect(
          result,
          testValue('foo bar[[https://example.com/][description|]]'),
        );
      });
      test('Link with empty selection without clipboard URL', () async {
        final result = await insertLink(testValue('foo bar|'), null);
        expect(result, testValue('foo bar[[URL][description|]]'));
      });
    });
    group('Date', () {
      test('Date with selection', () async {
        final result = await insertDate(
          testValue('foo |bar|'),
          false,
          DateTime(2024, 6, 15),
          null,
        );
        expect(result, testValue('foo [2024-06-15 Sat|]'));
      });
      test('Date with empty selection', () async {
        final result = await insertDate(
          testValue('foo bar|'),
          false,
          DateTime(2024, 6, 20),
          null,
        );
        expect(result, testValue('foo bar[2024-06-20 Thu|]'));
      });
      test('Date empty', () async {
        final result = await insertDate(
          testValue('|'),
          false,
          DateTime(2024, 6, 20),
          null,
        );
        expect(result, testValue('[2024-06-20 Thu|]'));
      });
      test('Date with time', () async {
        final result = await insertDate(
          testValue('foo |bar|'),
          false,
          DateTime(2024, 6, 15),
          TimeOfDay(hour: 14, minute: 30),
        );
        expect(result, testValue('foo [2024-06-15 Sat 14:30|]'));
      });
      test('Active date with time', () async {
        final result = await insertDate(
          testValue('foo |bar|'),
          true,
          DateTime(2024, 6, 15),
          TimeOfDay(hour: 14, minute: 30),
        );
        expect(result, testValue('foo <2024-06-15 Sat 14:30|>'));
      });
    });
  });
}
