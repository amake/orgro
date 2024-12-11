import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/encryption.dart';
import 'package:orgro/src/serialization.dart';

Iterable<File> get testFiles => Directory('assets/test')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) =>
        file.path.endsWith('.org') && !file.path.endsWith('encoding-sjis.org'));

void main() {
  group('Serialization', () {
    test('OrgroSerializer', () {
      for (final file in testFiles) {
        final serializer = OrgroSerializer();
        final content = file.readAsStringSync();
        final doc = OrgDocument.parse(content);
        expect(
          content,
          doc.toMarkup(serializer: serializer),
          reason: '${file.path} should round-trip',
        );
      }
    });
    group('Decrypted content', () {
      const content = '''
* foo

-----BEGIN PGP MESSAGE-----

jA0ECQMI05i+dd7lsRry0joBcGZQ4m+N9M/Z3I2Xw7SSn2uPMRpWbH9UIRkzPTXU
28y0FO/Aug4JaE/n+wqbmgY0b37dZzWI2BWi
=uuok
-----END PGP MESSAGE-----
''';
      const password = 'foobar';
      final doc = OrgDocument.parse(content);
      final found = doc.find<OrgPgpBlock>((_) => true);
      final (path: _, node: block) = found!;
      // We don't need to actually decrypt here because it's slow
      final serializer = OrgroDecryptedContentSerializer(block,
          cleartext: 'bar\n', password: password);
      final replacement =
          OrgDecryptedContent.fromDecryptedResult('bar\n', serializer);
      final newDoc = doc.editNode(block)!.replace(replacement).commit();

      test('Default serializer returns cyphertext', () {
        expect(newDoc.toMarkup(), content);
      });
      test('OrgroPlaintextSerializer returns plain text', () {
        expect(
          newDoc.toMarkup(serializer: OrgroPlaintextSerializer()),
          '* foo\n\nbar\n',
        );
      });
      test('OrgroCyphertextSerializer returns cyphertext', () {
        expect(
          newDoc.toMarkup(serializer: OrgroCyphertextSerializer([])),
          content,
        );
      });
    });
    group('Encryption', () {
      const content = '''
* foo :crypt:

bar
''';
      final doc = OrgDocument.parse(content);
      test('Missing password', () {
        expect(
          () => doc.toMarkup(serializer: OrgroCyphertextSerializer([])),
          throwsStateError,
        );
      });
      test('No matching password', () {
        final password = (password: 'foobar', predicate: (_) => false);
        final serializer = OrgroCyphertextSerializer([password]);
        expect(
          () => doc.toMarkup(serializer: serializer),
          throwsStateError,
        );
      });
      test('Password provided', () {
        final password = (password: 'foobar', predicate: (_) => true);
        final serializer = OrgroCyphertextSerializer([password]);
        final output = doc.toMarkup(serializer: serializer);
        // dart-pg cyphertext is apparently not stable, so we can't compare exactly
        expect(output.startsWith('''* foo :crypt:

-----BEGIN PGP MESSAGE-----
'''), isTrue);
      });
      test('Round-trip', () {
        final password = (password: 'foobar', predicate: (_) => true);
        final serializer = OrgroCyphertextSerializer([password]);
        final output = doc.toMarkup(serializer: serializer);
        expect(output.contains('-----BEGIN PGP MESSAGE-----'), isTrue);
        expect(output.contains('bar'), isFalse);
        final newDoc = OrgDocument.parse(output);
        final (path: _, node: block) = newDoc.find<OrgPgpBlock>((_) => true)!;
        final [plaintext] = decrypt(([block], password.password));
        expect(plaintext, 'bar\n');
      });
    });
  });
}
