import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/pages/editor/checkbox.dart';

void main() {
  group('checkbox', () {
    group('insert at point', () {
      test('add to list item', () {
        expect(insertCheckboxAtPoint('- foo', 0), ('- [ ] foo', 9));
        expect(insertCheckboxAtPoint('1. foo', 3), ('1. [ ] foo', 10));
        expect(
          insertCheckboxAtPoint('''
1. foo

   bar''', 12),
          ('1. foo\n\n   - [ ] bar', 20),
        );
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
        expect(insertCheckboxOverRange('- foo', 0, 0), ('- [ ] - foo', 6));
        expect(insertCheckboxOverRange('1. foo', 3, 3), ('1. - [ ] foo', 9));
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
1. - [ ] foo
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
f- [ ] oo
- [ ]${' '}
- [ ] bar

baz
''',
            26,
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
- - [ ] foo
- [ ]${' '}
- [ ] 1. bar

baz
''',
            26,
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
- - [ ] foo
  - [ ] bar
- [ ]${' '}
- [ ] baz
''',
            38,
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
  - - [ ] bar

baz
''',
            18,
          ),
        );
      });
    });
  });
}
