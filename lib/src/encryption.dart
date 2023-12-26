import 'package:dart_pg/dart_pg.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';

List<String?> decrypt((List<OrgPgpBlock> blocks, String password) args) {
  final (blocks, password) = args;
  final result = <String?>[];

  for (final block in blocks) {
    try {
      final message = OpenPGPSync.readMessage(block.toRfc4880());
      final decrypted = OpenPGPSync.decrypt(
        message,
        passwords: [password],
      );
      result.add(decrypted.literalData!.text);
    } catch (e, s) {
      result.add(null);
      logError(e, s);
    }
  }
  return result;
}

String _encrypt(OrgDecryptedContent content, String password) {
  final message = OpenPGPSync.encrypt(
    OpenPGPSync.createTextMessage(content.toCleartextMarkup()),
    passwords: [password],
  );
  return message.armor();
}

class OrgroSerializer extends DecryptedContentSerializer {
  OrgroSerializer(
    this.block, {
    required this.cleartext,
    required this.password,
  });

  final OrgPgpBlock block;
  final String cleartext;
  final String password;

  @override
  String toMarkup(OrgDecryptedContent content) {
    if (cleartext == content.toCleartextMarkup()) {
      // Cleartext hasn't changed; write back the old cyphertext
      return block.toMarkup();
    }
    // Reencrypt with the same password
    return _encrypt(content, password);
  }
}
