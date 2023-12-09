import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ShareUnsaveableChangesDialog extends StatelessWidget {
  const ShareUnsaveableChangesDialog({required this.doc, super.key});

  final OrgDocument doc;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.save),
      title: Text(AppLocalizations.of(context)!.saveChangesDialogTitle),
      content: Text(AppLocalizations.of(context)!.saveChangesDialogMessage),
      actions: [
        Builder(builder: (context) {
          return ListTile(
            title: Text(SaveAction.share.toDisplayString(context)),
            onTap: () async {
              final navigator = Navigator.of(context);

              // Compute origin of share sheet for tablets
              final box = context.findRenderObject() as RenderBox?;
              final origin = box!.localToGlobal(Offset.zero) & box.size;

              final result = await Share.shareWithResult(
                doc.toMarkup(),
                sharePositionOrigin: origin,
              );

              // Don't close popup unless user successfully shared
              if (result.status == ShareResultStatus.success) {
                navigator.pop(true);
              }
            },
          );
        }),
        ListTile(
          title: Text(SaveAction.discard.toDisplayString(context)),
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

enum SaveAction { share, discard }

extension SaveActionDisplayString on SaveAction {
  String toDisplayString(BuildContext context) => switch (this) {
        SaveAction.share => AppLocalizations.of(context)!.saveActionShare,
        SaveAction.discard => AppLocalizations.of(context)!.saveActionDiscard,
      };
}
