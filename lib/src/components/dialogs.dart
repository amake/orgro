import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/serialization.dart';
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
              Uri.parse(link.location),
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

              final markup = await serializeWithProgressUI(context, doc);
              if (markup == null) return;

              final result = await Share.share(
                markup,
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

class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning),
      title: Text(AppLocalizations.of(context)!.discardChangesDialogTitle),
      actions: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.discardActionDiscard),
          onTap: () => Navigator.pop(context, true),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.discardActionCancel),
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

class InputPasswordDialog extends StatelessWidget {
  const InputPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock),
      title: Text(AppLocalizations.of(context)!.inputPasswordDialogTitle),
      content: TextField(
        autofocus: true,
        obscureText: true,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
    );
  }
}

class ProgressIndicatorDialog extends StatelessWidget {
  const ProgressIndicatorDialog({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: const LinearProgressIndicator(),
    );
  }
}

class InputFilterQueryDialog extends StatefulWidget {
  const InputFilterQueryDialog({super.key});

  @override
  State<InputFilterQueryDialog> createState() => _InputFilterQueryDialogState();
}

class _InputFilterQueryDialogState extends State<InputFilterQueryDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = Preferences.of(context).customFilterQueries;
    return AlertDialog(
      icon: const Icon(Icons.filter_alt),
      title: Text(AppLocalizations.of(context)!.inputCustomFilterDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: _confirm,
      ),
      actions: [
        _DialogButton(
          text: AppLocalizations.of(context)!.dialogActionHelp,
          onPressed: () => launchUrl(
            Uri.parse(
                'https://orgmode.org/manual/Matching-tags-and-properties.html'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        if (history.isNotEmpty)
          _DialogButton(
            text: AppLocalizations.of(context)!
                .inputCustomFilterDialogHistoryButton,
            onPressed: () async {
              final entry = await _pickFromHistory(context, history);
              if (entry != null) _controller.text = entry;
            },
          ),
        _DialogButton(
          text: AppLocalizations.of(context)!.dialogActionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => _DialogButton(
            text: AppLocalizations.of(context)!.dialogActionConfirm,
            onPressed:
                _validate(value.text) ? () => _confirm(value.text) : null,
          ),
        ),
      ],
    );
  }

  bool _validate(String value) {
    if (value.isEmpty) return false;

    try {
      OrgQueryMatcher.fromMarkup(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirm(String value) async {
    if (!_validate(value)) return;
    _updateHistory(value);
    Navigator.pop(context, value);
  }

  void _updateHistory(String value) {
    final prefs = Preferences.of(context);
    if (!prefs.customFilterQueries.contains(value)) {
      prefs.setCustomFilterQueries(
          [value, ...prefs.customFilterQueries.take(9)]);
    }
  }

  Future<String?> _pickFromHistory(
          BuildContext context, List<String> history) =>
      showDialog<String>(
        context: context,
        builder: (context) => const CustomFilterHistoryDialog(),
      );
}

class CustomFilterHistoryDialog extends StatelessWidget {
  const CustomFilterHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Preferences.of(context).customFilterQueries;
    return SimpleDialog(
      children: [
        for (final entry in history)
          ListTile(
            title: Text(entry),
            onTap: () => Navigator.pop(context, entry),
          )
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.text, required this.onPressed});

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.end,
      ),
    );
  }
}
