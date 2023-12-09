import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SavePermissionDialog extends StatelessWidget {
  const SavePermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.save),
      title: Text(AppLocalizations.of(context)!.saveChangesDialogTitle),
      // SizedBox with any finite height needed because AlertDialog uses
      // IntrinsicWidth and this needs something to work with, apparently;
      // see https://stackoverflow.com/a/60896702/448068
      //
      // TODO(aaron): Should this be inside OrgText instead?
      content: SizedBox(
          width: double.maxFinite,
          child: OrgText(
            AppLocalizations.of(context)!.bannerBodySaveDocumentOrg,
            onLinkTap: (link) => launchUrl(
              Uri.parse(link),
              mode: LaunchMode.externalApplication,
            ),
          )),
      actions: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.bannerBodyActionSaveOnce),
          onTap: () => Navigator.pop(context, (SaveChangesPolicy.allow, false)),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.bannerBodyActionSaveAlways),
          onTap: () => Navigator.pop(context, (SaveChangesPolicy.allow, true)),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.bannerBodyActionSaveNever),
          onTap: () => Navigator.pop(context, (SaveChangesPolicy.deny, true)),
        ),
      ],
    );
  }
}

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
