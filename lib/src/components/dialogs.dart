import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/document/citations.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/serialization.dart';
import 'package:orgro/src/util.dart';
import 'package:petit_bibtex/bibtex.dart';
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
          onLinkTap:
              (link) => launchUrl(
                Uri.parse(link.location),
                mode: LaunchMode.externalApplication,
              ),
        ),
      ),
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
  const ShareUnsaveableChangesDialog({
    required this.doc,
    required this.serializer,
    super.key,
  });

  final OrgDocument doc;
  final OrgroSerializer serializer;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.save),
      title: Text(AppLocalizations.of(context)!.saveChangesDialogTitle),
      content: Text(AppLocalizations.of(context)!.saveChangesDialogMessage),
      actions: [
        Builder(
          builder: (context) {
            return ListTile(
              title: Text(SaveAction.share.toDisplayString(context)),
              onTap: () async {
                final navigator = Navigator.of(context);

                // Compute origin of share sheet for tablets
                final box = context.findRenderObject() as RenderBox?;
                final origin = box!.localToGlobal(Offset.zero) & box.size;

                final markup = await serializeWithProgressUI(
                  context,
                  doc,
                  serializer,
                );
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
          },
        ),
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

class ConfirmResetDialog extends StatelessWidget {
  const ConfirmResetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning),
      title: Text(
        AppLocalizations.of(context)!.confirmResetPreferencesDialogTitle,
      ),
      content: Text(
        AppLocalizations.of(context)!.confirmResetPreferencesDialogMessage,
      ),
      actions: [
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.confirmResetPreferencesActionReset,
          ),
          onTap: () => Navigator.pop(context, true),
        ),
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.confirmResetPreferencesActionCancel,
          ),
          onTap: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}

class InputPasswordDialog extends StatelessWidget {
  const InputPasswordDialog({required this.title, this.bodyText, super.key});

  final String title;
  final String? bodyText;

  @override
  Widget build(BuildContext context) {
    Widget content = TextField(
      autofocus: true,
      obscureText: true,
      onSubmitted: (value) => Navigator.pop(context, value),
      contextMenuBuilder: nativeWhenPossibleContextMenuBuilder,
    );
    if (bodyText != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(bodyText!), const SizedBox(height: 8), content],
      );
    }
    return AlertDialog(
      icon: const Icon(Icons.lock),
      title: Text(title),
      content: content,
    );
  }
}

class InputFileNameDialog extends StatefulWidget {
  const InputFileNameDialog({super.key});

  @override
  State<InputFileNameDialog> createState() => _InputFileNameDialogState();
}

class _InputFileNameDialogState extends State<InputFileNameDialog> {
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

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _controller.text = AppLocalizations.of(context)!.createFileDefaultName;
      _inited = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.create),
      title: Text(AppLocalizations.of(context)!.createFileDialogTitle),
      content: TextField(
        autofocus: true,
        controller: _controller,
        onSubmitted: (value) => Navigator.pop(context, value),
        contextMenuBuilder: nativeWhenPossibleContextMenuBuilder,
      ),
    );
  }
}

Future<({bool succeeded, T? result})> cancelableProgressTask<T>(
  BuildContext context, {
  required Future<T> task,
  required String dialogTitle,
}) async {
  var canceled = false;

  final dialogFuture = showDialog<(T, Object?)>(
    context: context,
    builder:
        (context) =>
            ProgressIndicatorDialog(title: dialogTitle, dismissable: true),
  );

  task
      .then((result) {
        if (!canceled && context.mounted) {
          Navigator.pop(context, (result, null));
        }
      })
      .onError((error, stackTrace) {
        if (context.mounted) showErrorSnackBar(context, error);
        logError(error, stackTrace);
        if (!canceled && context.mounted) Navigator.pop(context, (null, error));
      });

  // Popped will be one of:
  // - null if the user closed the dialog by tapping outside or using the back
  //   button/gesture
  // - (task result, null) if completed normally
  // - (null, error) if completed with error
  final popped = await dialogFuture;

  if (popped == null) {
    canceled = true;
    return (succeeded: false, result: null);
  }

  final (result, error) = popped;
  return error == null
      ? (succeeded: true, result: result)
      : (succeeded: false, result: null);
}

class ProgressIndicatorDialog extends StatelessWidget {
  const ProgressIndicatorDialog({
    required this.title,
    this.dismissable = false,
    super.key,
  });

  final String title;
  final bool dismissable;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissable,
      child: AlertDialog(
        title: Text(title),
        content: const LinearProgressIndicator(),
      ),
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
        contextMenuBuilder: nativeWhenPossibleContextMenuBuilder,
      ),
      actions: [
        _DialogButton(
          text: AppLocalizations.of(context)!.dialogActionHelp,
          onPressed:
              () => launchUrl(
                Uri.parse(
                  'https://orgmode.org/manual/Matching-tags-and-properties.html',
                ),
                mode: LaunchMode.externalApplication,
              ),
        ),
        if (history.isNotEmpty)
          _DialogButton(
            text:
                AppLocalizations.of(
                  context,
                )!.inputCustomFilterDialogHistoryButton,
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
          builder:
              (context, value, _) => _DialogButton(
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
    Preferences.of(context, PrefsAspect.nil).addCustomFilterQuery(value);
    Navigator.pop(context, value);
  }

  Future<String?> _pickFromHistory(
    BuildContext context,
    List<String> history,
  ) => showDialog<String>(
    context: context,
    builder: (context) => const CustomFilterHistoryDialog(),
  );
}

class CustomFilterHistoryDialog extends StatelessWidget {
  const CustomFilterHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final history =
        Preferences.of(
          context,
          PrefsAspect.customFilterQueries,
        ).customFilterQueries;
    return SimpleDialog(
      children: [
        for (final entry in history)
          ListTile(
            title: Text(entry),
            onTap: () => Navigator.pop(context, entry),
          ),
      ],
    );
  }
}

class CitationsDialog extends StatelessWidget {
  const CitationsDialog({required this.entries, super.key});

  final List<BibTeXEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.citationsDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, idx) {
            final entry = entries[idx];
            final url = entry.getUrl();
            final details = entry.getDetails();
            return ListTile(
              leading: switch (entry.type.toLowerCase()) {
                'book' ||
                'booklet' ||
                'inbook' ||
                'incollection' ||
                'manual' => const Icon(Icons.book),
                'conference' ||
                'inproceedings' ||
                'proceedings' => const Icon(Icons.mic),
                'article' ||
                'mastersthesis' ||
                'phdthesis' ||
                'techreport' => const Icon(Icons.article),
                // 'misc' is often used for websites; the Language icon is
                // an abstract globe, which in my opinion is more suggestive
                // of a website than Web or Public
                'misc' => const Icon(Icons.language),
                _ => const Icon(Icons.question_mark),
              },
              title: Text(entry.getPrettyValue('title') ?? entry.key),
              subtitle: details.isEmpty ? null : Text(details),
              trailing:
                  url == null
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed:
                            () => launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            ),
                      ),
            );
          },
          itemCount: entries.length,
        ),
      ),
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
      child: Text(text.toUpperCase(), textAlign: TextAlign.end),
    );
  }
}
