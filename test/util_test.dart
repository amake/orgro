import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/util.dart';

void main() {
  group('String util', () {
    test('Detect linebreak', () {
      expect(''.detectLineBreak(), isNull);
      expect('foo\n'.detectLineBreak(), '\n');
      expect('foo\r\n'.detectLineBreak(), '\r\n');
      expect('\n\r'.detectLineBreak(), '\n');
      expect('\n'.detectLineBreak(), '\n');
      expect('\r\n'.detectLineBreak(), '\r\n');
    });
    test('With trailing linebreak', () {
      expect(''.withTrailingLineBreak(), '\n');
      expect('foo'.withTrailingLineBreak(), 'foo\n');
      expect('foo\n'.withTrailingLineBreak(), 'foo\n');
      expect('foo\r\n'.withTrailingLineBreak(), 'foo\r\n');
      expect('foo\n\n'.withTrailingLineBreak(), 'foo\n\n');
      expect('foo\r\n\r\n'.withTrailingLineBreak(), 'foo\r\n\r\n');
      expect('foo\nbar'.withTrailingLineBreak(), 'foo\nbar\n');
      expect('foo\r\nbar'.withTrailingLineBreak(), 'foo\r\nbar\r\n');
    });
  });
  group('Map util', () {
    test('Unordered equals', () {
      expect({1: 2, 3: 4}.unorderedEquals({1: 2, 3: 4}), isTrue);
      expect({1: 2, 3: 4}.unorderedEquals({3: 4, 1: 2}), isTrue);
      expect({1: 2, 3: 4}.unorderedEquals({1: 2, 3: 4, 5: 6}), isFalse);
      expect({1: 2, 3: 4}.unorderedEquals({1: 2}), isFalse);
      expect({1: 2, 3: 4}.unorderedEquals({1: 2, 5: 4}), isFalse);
      expect({1: 2, 3: 4}.unorderedEquals({1: 2, 3: 5}), isFalse);
      expect(
        {
          1: {'a': 'b'},
          2: {'c': 'd'},
        }.unorderedEquals({
          1: {'a': 'b'},
          2: {'c': 'd'},
        }, valueEquals: (a, b) => mapEquals(a, b)),
        isTrue,
      );
      expect(
        {
          1: {'a': 'b'},
          2: {'c': 'd'},
        }.unorderedEquals({
          2: {'c': 'd'},
          1: {'a': 'b'},
        }, valueEquals: (a, b) => mapEquals(a, b)),
        isTrue,
      );
      expect(
        {
          1: {'a': 'b'},
          2: {'c': 'd'},
        }.unorderedEquals({
          1: {'a': 'b'},
          2: {'c': 'e'},
        }, valueEquals: (a, b) => mapEquals(a, b)),
        isFalse,
      );
      expect(
        {
          1: {'a': 'b'},
          2: {'c': 'd'},
        }.unorderedEquals({
          1: {'a': 'b'},
          2: {'c': 'd'},
          3: {'e': 'f'},
        }, valueEquals: (a, b) => mapEquals(a, b)),
        isFalse,
      );
    });
  });
  group('Sequentially', () {
    test('Execute sequentially', () async {
      final acc = <int>[];
      final fn = sequentially((int i) async {
        await Future<void>.delayed(Duration(milliseconds: i * 50));
        acc.add(i);
        return i;
      });
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(List.generate(3, (i) => fn(2 - i)));
      stopwatch.stop();
      expect(results, [2, 1, 0]);
      expect(acc, [2, 1, 0]);
      // The total time should be about 150ms (100ms + 50ms + 0ms)
      expect(stopwatch.elapsedMilliseconds, inInclusiveRange(140, 200));
    });
    test('Execute sequentially with lock file', () async {
      final acc = <int>[];
      final lockfile = File('test.lock');
      expect(lockfile.existsSync(), isFalse);
      final fn = sequentiallyWithLockfile(lockfile, (int i) async {
        await Future<void>.delayed(Duration(milliseconds: i * 50));
        acc.add(i);
        return i;
      });
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(List.generate(3, (i) => fn(2 - i)));
      stopwatch.stop();
      expect(results, [2, 1, 0]);
      expect(acc, [2, 1, 0]);
      // The total time should be about 150ms (100ms + 50ms + 0ms)
      expect(stopwatch.elapsedMilliseconds, inInclusiveRange(140, 200));
      expect(lockfile.existsSync(), isFalse);
    });
  });
  group('Debounce', () {
    test('Debounce calls', () async {
      var acc = 0;
      final debouncedFn = debounce(
        () => acc += 1,
        const Duration(milliseconds: 10),
      );
      debouncedFn();
      debouncedFn();
      debouncedFn();
      await Future<void>.delayed(Duration(milliseconds: 20));
      expect(acc, 1);
    });
    test('Debounce calls with arg', () async {
      var val = 0;
      final debouncedFn = debounce1(
        (int arg) async => val = arg,
        const Duration(milliseconds: 10),
      );
      debouncedFn(10);
      debouncedFn(20);
      debouncedFn(30);
      await Future<void>.delayed(Duration(milliseconds: 20));
      expect(val, 30);
    });
  });
}
