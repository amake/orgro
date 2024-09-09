import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/document_provider.dart';

void main() {
  group('Analysis', () {
    test('Boring document', () {
      final doc = OrgDocument.parse('* foo');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.hasRemoteImages, isFalse);
      expect(analysis.hasRelativeLinks, isFalse);
      expect(analysis.hasEncryptedContent, isFalse);
      expect(analysis.needsEncryption, isFalse);
    });
    test('Remote images', () {
      final doc = OrgDocument.parse('https://example.com/image.png');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.hasRemoteImages, isTrue);
      expect(analysis.hasRelativeLinks, isFalse);
      expect(analysis.hasEncryptedContent, isFalse);
      expect(analysis.needsEncryption, isFalse);
    });
    test('Relative links', () {
      final doc = OrgDocument.parse('[[./foo.org][foo]]');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.hasRemoteImages, isFalse);
      expect(analysis.hasRelativeLinks, isTrue);
      expect(analysis.hasEncryptedContent, isFalse);
      expect(analysis.needsEncryption, isFalse);
    });
    test('Encrypted content', () {
      final doc = OrgDocument.parse('''
* foo :crypt:

-----BEGIN PGP MESSAGE-----

jA0ECQMI05i+dd7lsRry0joBcGZQ4m+N9M/Z3I2Xw7SSn2uPMRpWbH9UIRkzPTXU
28y0FO/Aug4JaE/n+wqbmgY0b37dZzWI2BWi
=uuok
-----END PGP MESSAGE-----
''');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.hasRemoteImages, isFalse);
      expect(analysis.hasRelativeLinks, isFalse);
      expect(analysis.hasEncryptedContent, isTrue);
      expect(analysis.needsEncryption, isFalse);
    });
    test('Needs encryption', () {
      final doc = OrgDocument.parse('''
* foo :crypt:

bar

-----BEGIN PGP MESSAGE-----

jA0ECQMI05i+dd7lsRry0joBcGZQ4m+N9M/Z3I2Xw7SSn2uPMRpWbH9UIRkzPTXU
28y0FO/Aug4JaE/n+wqbmgY0b37dZzWI2BWi
=uuok
-----END PGP MESSAGE-----
''');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.hasRemoteImages, isFalse);
      expect(analysis.hasRelativeLinks, isFalse);
      expect(analysis.hasEncryptedContent, isTrue);
      expect(analysis.needsEncryption, isTrue);
    });
    // TODO(aaron): test keywords, tags, priorities
    test('Keywords', () {
      final doc = OrgDocument.parse('''
* TODO foo
* DONE bar
''');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.keywords, ['TODO', 'DONE']);
      expect(analysis.tags, isEmpty);
      expect(analysis.priorities, isEmpty);
    });
    test('Tags', () {
      final doc = OrgDocument.parse('''
* foo :tag1:tag2:
* bar :tag3:
''');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.keywords, isEmpty);
      expect(analysis.tags, ['tag1', 'tag2', 'tag3']);
      expect(analysis.priorities, isEmpty);
    });
    test('Priorities', () {
      final doc = OrgDocument.parse('''
* [#A] foo
* [#B] bar
''');
      final analysis = DocumentAnalysis.of(doc, canResolveRelativeLinks: true);
      expect(analysis.keywords, isEmpty);
      expect(analysis.tags, isEmpty);
      expect(analysis.priorities, ['A', 'B']);
    });
  });
}
