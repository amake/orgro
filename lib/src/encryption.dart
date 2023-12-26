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
