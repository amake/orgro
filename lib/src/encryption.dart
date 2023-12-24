import 'package:dart_pg/dart_pg.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';

Future<List<String?>> decrypt(
    (List<OrgPgpBlock> blocks, String password) args) async {
  final (blocks, password) = args;
  final result = <String?>[];

  for (final block in blocks) {
    try {
      final message = await OpenPGP.readMessage(block.toRfc4880());
      final decrypted = await OpenPGP.decrypt(
        message,
        passwords: [password],
      );
      result.add(decrypted.literalData?.text);
    } catch (e, s) {
      result.add(null);
      logError(e, s);
    }
  }
  return result;
}
