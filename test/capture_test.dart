import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/capture.dart';

void main() {
  group('Capture URI', () {
    final now = DateTime(2024, 6, 1, 12, 0, 0);
    test('URL, title, body', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&url=http://example.com/foo&title=Foo+Bar&body=baz+buzz',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* [[http://example.com/foo][Foo Bar]]
  Captured On: [2024-06-01 Sat 12:00]

  baz buzz
''');
    });
    test('URL, body', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&url=http://example.com/foo&body=baz+buzz',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* [[http://example.com/foo]]
  Captured On: [2024-06-01 Sat 12:00]

  baz buzz
''');
    });
    test('Title, body', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&title=Foo+Bar&body=baz+buzz',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* Foo Bar
  Captured On: [2024-06-01 Sat 12:00]

  baz buzz
''');
    });
    test('URL, title', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&url=http://example.com/foo&title=Foo+Bar',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* [[http://example.com/foo][Foo Bar]]
  Captured On: [2024-06-01 Sat 12:00]
''');
    });
    test('URL only', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&url=http://example.com/foo',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* [[http://example.com/foo]]
  Captured On: [2024-06-01 Sat 12:00]
''');
    });
    test('Title only', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&title=Foo+Bar',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* Foo Bar
  Captured On: [2024-06-01 Sat 12:00]
''');
    });
    test('Body only', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&body=baz+buzz',
      );
      final doc = OrgDocument.parse('');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* Captured On: [2024-06-01 Sat 12:00]

  baz buzz
''');
    });
    test('With existing content', () {
      final uri = Uri.parse(
        'org-protocol://capture?template=foo&url=http://example.com/foo&title=Foo+Bar&body=baz+buzz',
      );
      final doc = OrgDocument.parse('* foo bar');
      final (newDoc, newSection) = captureUriToSection(doc, uri, now);
      expect(newDoc.toMarkup(), '''
* foo bar
* [[http://example.com/foo][Foo Bar]]
  Captured On: [2024-06-01 Sat 12:00]

  baz buzz
''');
    });
  });
}
