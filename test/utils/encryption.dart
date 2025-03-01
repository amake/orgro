import 'dart:convert';

import 'package:orgro/src/encryption.dart';

const _header = '-----BEGIN PGP MESSAGE-----\n\n';
const _footer = '\n-----END PGP MESSAGE-----';

var _originalEncrypt = opgpEncrypt;
var _originalDecrypt = opgpDecrypt;

String _mockEncrypt(String text, String _) =>
    '$_header${base64Encode(utf8.encode(text))}$_footer';

String _mockDecrypt(String text, String _) => utf8.decode(
  base64Decode(text.substring(_header.length, text.length - _footer.length)),
);

void mockOpenPGP() {
  opgpEncrypt = _mockEncrypt;
  opgpDecrypt = _mockDecrypt;
}

void restoreOpenPGP() {
  opgpEncrypt = _originalEncrypt;
  opgpDecrypt = _originalDecrypt;
}
