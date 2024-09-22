import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/encryption.dart';
import 'package:orgro/src/pages/document/document.dart';

extension EncryptionHandler on DocumentPageState {
  Future<void> decryptContent() async {
    final doc = DocumentProvider.of(context).doc;
    final blocks = <OrgPgpBlock>[];
    doc.visit<OrgPgpBlock>((block) {
      blocks.add(block);
      return true;
    });
    final password = await showDialog<String>(
      context: context,
      builder: (context) => InputPasswordDialog(
        title: AppLocalizations.of(context)!.inputDecryptionPasswordDialogTitle,
      ),
    );
    if (password == null) return;
    if (!mounted) return;

    final (:succeeded, :result) = await cancelableProgressTask(
      context,
      task: time('decrypt', () => compute(decrypt, (blocks, password))),
      dialogTitle: AppLocalizations.of(context)!.decryptingProgressDialogTitle,
    );
    if (!succeeded || result == null) return;

    OrgTree newDoc = doc;
    final toRemember = <OrgroPassword>[];
    for (final (i, cleartext) in result.indexed) {
      if (cleartext == null) {
        showErrorSnackBar(
            context, AppLocalizations.of(context)!.errorDecryptionFailed);
        continue;
      }
      final block = blocks[i];
      try {
        final replacement = OrgDecryptedContent.fromDecryptedResult(
          cleartext,
          OrgroDecryptedContentSerializer(
            block,
            cleartext: cleartext,
            password: password,
          ),
        );
        final enclosingCryptSection = newDoc.findContainingTree(
              block,
              where: (tree) =>
                  tree is OrgSection && tree.tags.contains('crypt'),
            ) ??
            newDoc.findContainingTree(block)!;
        if (enclosingCryptSection is OrgSection) {
          toRemember.add((
            password: password,
            predicate: enclosingCryptSection.buildMatcher(),
          ));
        }
        newDoc =
            newDoc.editNode(block)!.replace(replacement).commit() as OrgTree;
      } catch (e, s) {
        logError(e, s);
        showErrorSnackBar(context, e);
        continue;
      }
    }
    DocumentProvider.of(context).addPasswords(toRemember);
    await updateDocument(newDoc, dirty: false);
  }
}
