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
}
