import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/data_source.dart';

void main() {
  group('Data Source', () {
    group('Resolve relative', () {
      test('AssetDataSource', () {
        final dataSource = AssetDataSource('foo/bar/baz');
        final relative = dataSource.resolveRelative('buzz');
        expect(relative.key, 'foo/bar/buzz');
      });
      test('AssetDataSource with weird path', () {
        final dataSource = AssetDataSource('foo/bar/baz');
        final relative = dataSource.resolveRelative('buzz: bazinga');
        expect(relative.key, 'foo/bar/buzz: bazinga');
      });
      test('WebDataSource', () {
        final dataSource = WebDataSource(Uri.parse('http://example.com/foo'));
        final relative = dataSource.resolveRelative('bar');
        expect(relative.uri, Uri.parse('http://example.com/bar'));
      });
      test('WebDataSource with weird path', () {
        final dataSource = WebDataSource(Uri.parse('http://example.com/foo'));
        final relative = dataSource.resolveRelative('bar: baz');
        expect(relative.uri, Uri.parse('http://example.com/bar%3A%20baz'));
      });
    });
  });
}
