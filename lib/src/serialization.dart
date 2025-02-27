import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/encryption.dart';

class OrgroSerializer extends OrgSerializer {
  static OrgroSerializer get(
    DocumentAnalysis analysis,
    List<OrgroPassword> passwords,
  ) {
    return analysis.needsEncryption == true
        ? OrgroCyphertextSerializer(passwords)
        : OrgroSerializer();
  }

  bool get willEncrypt => false;
  bool _canceled = false;

  void cancel() => _canceled = true;

  @override
  void visit(OrgNode node) {
    if (_canceled) return;
    super.visit(node);
  }

  @override
  void write(String str) {
    if (_canceled) return;
    super.write(str);
  }
}

class OrgroPlaintextSerializer extends OrgroSerializer {
  @override
  void visit(OrgNode node) {
    if (_canceled) return;
    if (node is OrgDecryptedContent) {
      node.toCleartextMarkup(serializer: this);
    } else {
      super.visit(node);
    }
  }
}

class OrgroCyphertextSerializer extends OrgroSerializer {
  OrgroCyphertextSerializer(this.passwords);

  @override
  bool get willEncrypt => true;
  final List<OrgroPassword> passwords;

  @override
  void visit(OrgNode node) {
    if (_canceled) return;
    if (node is OrgSection && node.needsEncryption()) {
      // Re-encrypt. We want to blow up here if we can't find a password, hence
      // firstWhere.
      final (:password, :predicate) = passwords.firstWhere(
        (p) => p.predicate(node),
      );
      final cyphertext = node.encrypt(password);
      write(cyphertext);
    } else {
      super.visit(node);
    }
  }
}

Future<String> serialize(OrgNode node, OrgSerializer serializer) =>
    time('serialize', () => compute(_doc2markup, (node, serializer)));

String _doc2markup((OrgNode node, OrgSerializer serializer) args) =>
    args.$1.toMarkup(serializer: args.$2);

Future<String?> serializeWithProgressUI(
  BuildContext context,
  OrgTree doc,
  OrgroSerializer serializer,
) async {
  final dialogFuture = showDialog<String>(
    context: context,
    builder:
        (context) => ProgressIndicatorDialog(
          title:
              serializer.willEncrypt
                  ? AppLocalizations.of(context)!.encryptingProgressDialogTitle
                  : AppLocalizations.of(
                    context,
                  )!.serializingProgressDialogTitle,
          dismissable: true,
        ),
  );
  var canceled = false;
  serialize(doc, serializer)
      .then((value) {
        if (!canceled && context.mounted) Navigator.pop(context, value);
      })
      .onError((error, stackTrace) {
        if (context.mounted) showErrorSnackBar(context, error);
        logError(error, stackTrace);
        if (!canceled && context.mounted) Navigator.pop(context);
      });
  final result = await dialogFuture;
  if (result == null) {
    canceled = true;
    serializer.cancel();
  }
  return result;
}
