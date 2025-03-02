import 'package:flutter/foundation.dart';
import 'package:openpgp/openpgp_sync.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/util.dart';

@visibleForTesting
String Function(String text, String password) opgpEncrypt =
    OpenPGPSync.encryptSymmetric;
@visibleForTesting
String Function(String text, String password) opgpDecrypt =
    OpenPGPSync.decryptSymmetric;

typedef OrgroPassword = ({String password, SectionPredicate predicate});
typedef SectionPredicate = bool Function(OrgSection);

extension OrgTreeEncryption on OrgTree {
  bool missingEncryptionKey(List<OrgroPassword> passwords) {
    final missing = find<OrgSection>(
      (section) =>
          section.needsEncryption() &&
          !passwords.any((p) => p.predicate(section)),
    );
    return missing != null;
  }
}

extension OrgSectionEncryption on OrgSection {
  bool needsEncryption() {
    if (!tags.contains('crypt')) return false;

    // An encrypted section should have no subsections
    if (sections.isNotEmpty) return true;

    final content = this.content?.children ?? [];
    // An encrypted section should have only leading whitespace and a PGP block
    if (content.length != 2) return true;

    final [first, second] = content;
    if (first is OrgParagraph &&
        !first.contains(RegExp(r'\S')) &&
        second is OrgPgpBlock) {
      // Already encrypted
      return false;
    }
    return true;
  }

  SectionPredicate buildMatcher() {
    final id = this.id;
    final rawTitle = headline.rawTitle;
    return (s) {
      if (s.id == id) return true;
      if (rawTitle != null && s.headline.rawTitle == rawTitle) return true;
      return false;
    };
  }

  String encrypt(String password) {
    final [headline, ...remaining] = children;
    assert(headline is OrgHeadline);
    final buf = OrgSerializer();
    for (final child in remaining) {
      buf.visit(child);
    }
    final (leading, text) = buf.toString().splitLeadingWhitespace();
    final message = opgpEncrypt(text, password);
    // Result does not have trailing newline so we add it ourselves. Otherwise
    // an encrypted section abutting another section will result in malformed
    // markup.
    return '${headline.toMarkup()}$leading$message\n';
  }
}

List<String?> decrypt((List<OrgPgpBlock> blocks, String password) args) {
  final (blocks, password) = args;
  final result = <String?>[];

  for (final block in blocks) {
    try {
      final decrypted = opgpDecrypt(block.toRfc4880(), password);
      result.add(decrypted);
    } catch (e, s) {
      result.add(null);
      logError(e, s);
    }
  }
  return result;
}

class OrgroDecryptedContentSerializer extends DecryptedContentSerializer {
  OrgroDecryptedContentSerializer(
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
    return opgpEncrypt(content.toCleartextMarkup(), password);
  }
}
