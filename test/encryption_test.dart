import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/encryption.dart';

import 'utils/encryption.dart';

void main() {
  setUp(() {
    mockOpenPGP();
  });
  tearDown(() {
    restoreOpenPGP();
  });
  group('Encryption', () {
    group('needsEncryption', () {
      test('Correctly encrypted section', () {
        const content = '''
* foo :crypt:

-----BEGIN PGP MESSAGE-----

jA0ECQMI05i+dd7lsRry0joBcGZQ4m+N9M/Z3I2Xw7SSn2uPMRpWbH9UIRkzPTXU
28y0FO/Aug4JaE/n+wqbmgY0b37dZzWI2BWi
=uuok
-----END PGP MESSAGE-----
''';
        final doc = OrgDocument.parse(content);
        final section = doc.sections.first;
        expect(section.needsEncryption(), isFalse);
      });
      test('Non-Org Crypt section', () {
        const content = '''
* foo

bar
''';
        final doc = OrgDocument.parse(content);
        final section = doc.sections.first;
        expect(section.needsEncryption(), isFalse);
      });
      test('Unencrypted Org Crypt section', () {
        const content = '''
* foo :crypt:

bar
''';
        final doc = OrgDocument.parse(content);
        final section = doc.sections.first;
        expect(section.needsEncryption(), isTrue);
      });
      test('Unencrypted leading content', () {
        const content = '''
* foo :crypt:

bar

-----BEGIN PGP MESSAGE-----

jA0ECQMI05i+dd7lsRry0joBcGZQ4m+N9M/Z3I2Xw7SSn2uPMRpWbH9UIRkzPTXU
28y0FO/Aug4JaE/n+wqbmgY0b37dZzWI2BWi
=uuok
-----END PGP MESSAGE-----
''';
        final doc = OrgDocument.parse(content);
        final section = doc.sections.first;
        expect(section.needsEncryption(), isTrue);
      });
    });
    test('encrypt', () {
      const content = '''
* foo :crypt:

bar
''';
      final doc = OrgDocument.parse(content);
      final section = doc.sections.first;
      expect(section.encrypt('foobar'), '''* foo :crypt:

-----BEGIN PGP MESSAGE-----

YmFyCg==
-----END PGP MESSAGE-----
''');
    });
  });
}
