import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/capture.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/document/citations.dart';
import 'package:orgro/src/pages/start/remembered_files.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/serialization.dart';
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
        child: Text(AppLocalizations.of(context)!.bannerBodySaveDocument),
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

class SaveChangesDialog extends StatelessWidget {
  const SaveChangesDialog({
    required this.doc,
    required this.serializer,
    required this.message,
    super.key,
  });

  final OrgDocument doc;
  final OrgroSerializer serializer;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.save),
      title: Text(AppLocalizations.of(context)!.saveChangesDialogTitle),
      content: message == null ? null : Text(message!),
      actions: [
        ListTile(
          title: Text(SaveAction.saveAs.toDisplayString(context)),
          onTap: () async {
            final fileName = await showDialog<String>(
              context: context,
              builder: (context) => InputFileNameDialog(
                title: AppLocalizations.of(context)!.saveAsDialogTitle,
              ),
            );
            if (fileName == null || !context.mounted) return;
            final markup = await serializeWithProgressUI(
              context,
              doc,
              serializer,
            );
            if (markup == null) return;
            final savedFile = await createAndSaveFile(fileName, markup);
            if (savedFile == null || !context.mounted) return;
            final rememberedFiles = RememberedFiles.of(context);
            final rememberedFile = RememberedFile(
              name: fileName,
              uri: savedFile.uri,
              identifier: savedFile.identifier,
              lastOpened: DateTime.now(),
            );
            await rememberedFiles.add([rememberedFile]);
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
        ),
        Builder(
          builder: (context) {
            return ListTile(
              title: Text(SaveAction.share.toDisplayString(context)),
              onTap: () async {
                final navigator = Navigator.of(context);
                final route = ModalRoute.of(context)!;

                // Compute origin of share sheet for tablets
                final box = context.findRenderObject() as RenderBox?;
                final origin = box!.localToGlobal(Offset.zero) & box.size;

                final markup = await serializeWithProgressUI(
                  context,
                  doc,
                  serializer,
                );
                if (markup == null) return;

                final result = await SharePlus.instance.share(
                  ShareParams(text: markup, sharePositionOrigin: origin),
                );

                // Don't close popup unless user successfully shared
                if (result.status == ShareResultStatus.success) {
                  // We remove the route instead of popping because we might
                  // have shared back into Orgro, in which case a new route
                  // (capture target selection dialog or scratch doc) is pushed
                  // just as we're closing this one (the save dialog) and the
                  // document.
                  navigator.removeRoute(route, true);
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

enum SaveAction { saveAs, share, discard }

extension SaveActionDisplayString on SaveAction {
  String toDisplayString(BuildContext context) => switch (this) {
    SaveAction.saveAs => AppLocalizations.of(context)!.saveActionSaveAs,
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
    );
    if (bodyText != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [Text(bodyText!), content],
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
  const InputFileNameDialog({required this.title, super.key});

  final String title;

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
      title: Text(widget.title),
      content: TextField(
        autofocus: true,
        controller: _controller,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
    );
  }
}

Future<({bool succeeded, T? result})> cancelableProgressTask<T>(
  BuildContext context, {
  required Future<T> task,
  String? dialogTitle,
  VoidCallback? onCancel,
}) async {
  var canceled = false;

  final route = DialogRoute<(T, Object?)>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        ProgressIndicatorDialog(title: dialogTitle, dismissable: true),
  );
  final dialogFuture = Navigator.push(context, route);

  task
      .then((result) {
        if (!canceled && context.mounted) {
          Navigator.removeRoute(context, route, (result, null));
        }
      })
      .onError((error, stackTrace) {
        if (context.mounted) showErrorSnackBar(context, error);
        logError(error, stackTrace);
        if (!canceled && context.mounted) {
          Navigator.removeRoute(context, route, (null, error));
        }
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

Future<({bool succeeded, T? result})> progressTask<T>(
  BuildContext context, {
  String? dialogTitle,
  required FutureOr<T> task,
}) async {
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        ProgressIndicatorDialog(title: dialogTitle, dismissable: false),
  );
  Navigator.push(context, route);
  try {
    final result = await task;
    return (succeeded: true, result: result);
  } catch (error, stackTrace) {
    if (context.mounted) showErrorSnackBar(context, error);
    logError(error, stackTrace);
    return (succeeded: false, result: null);
  } finally {
    if (context.mounted) Navigator.removeRoute(context, route);
  }
}

class ProgressIndicatorDialog extends StatelessWidget {
  const ProgressIndicatorDialog({
    required this.title,
    this.dismissable = false,
    super.key,
  });

  final String? title;
  final bool dismissable;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissable,
      child: AlertDialog(
        title: title == null ? null : Text(title!),
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
      ),
      actions: [
        DialogButton(
          text: AppLocalizations.of(context)!.dialogActionHelp,
          onPressed: () => launchUrl(
            Uri.parse(
              'https://orgmode.org/manual/Matching-tags-and-properties.html',
            ),
            mode: LaunchMode.externalApplication,
          ),
        ),
        if (history.isNotEmpty)
          DialogButton(
            text: AppLocalizations.of(
              context,
            )!.inputCustomFilterDialogHistoryButton,
            onPressed: () async {
              final entry = await _pickFromHistory(context, history);
              if (entry != null) _controller.text = entry;
            },
          ),
        DialogButton(
          text: AppLocalizations.of(context)!.dialogActionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => DialogButton(
            text: AppLocalizations.of(context)!.dialogActionConfirm,
            onPressed: _validate(value.text)
                ? () => _confirm(value.text)
                : null,
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
    final history = Preferences.of(
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
              trailing: url == null
                  ? null
                  : IconButton(
                      tooltip: AppLocalizations.of(
                        context,
                      )!.citationsDialogOpenLink,
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () =>
                          launchUrl(url, mode: LaunchMode.externalApplication),
                    ),
            );
          },
          itemCount: entries.length,
        ),
      ),
    );
  }
}

class RecentFilesSortDialog extends StatefulWidget {
  const RecentFilesSortDialog({
    required this.sortKey,
    required this.sortOrder,
    super.key,
  });

  final RecentFilesSortKey sortKey;
  final SortOrder sortOrder;

  @override
  State<RecentFilesSortDialog> createState() => _RecentFilesSortDialogState();
}

class _RecentFilesSortDialogState extends State<RecentFilesSortDialog> {
  late RecentFilesSortKey _sortKey;
  late SortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    _sortKey = widget.sortKey;
    _sortOrder = widget.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.recentFilesSortDialogTitle),
      content: SizedBox(
        width: 0,
        child: RadioGroup<RecentFilesSortKey>(
          groupValue: _sortKey,
          onChanged: (value) {
            if (value != null) setState(() => _sortKey = value);
          },
          child: RadioGroup<SortOrder>(
            groupValue: _sortOrder,
            onChanged: (value) {
              if (value != null) setState(() => _sortOrder = value);
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final key in RecentFilesSortKey.values)
                  RadioListTile<RecentFilesSortKey>(
                    value: key,
                    title: Text(key.toDisplayString(context)),
                  ),
                const Divider(),
                for (final order in SortOrder.values)
                  RadioListTile<SortOrder>(
                    value: order,
                    title: Text(order.toDisplayString(context)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        DialogButton(
          text: AppLocalizations.of(context)!.dialogActionCancel,
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          text: AppLocalizations.of(context)!.dialogActionConfirm,
          onPressed: () => Navigator.pop(context, (_sortKey, _sortOrder)),
        ),
      ],
    );
  }
}

class InputUrlDialog extends StatefulWidget {
  const InputUrlDialog({super.key});

  @override
  State<InputUrlDialog> createState() => _InputUrlDialogState();
}

class _InputUrlDialogState extends State<InputUrlDialog> {
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
      _maybeFillFromClipboard();
      _inited = true;
    }
  }

  void _maybeFillFromClipboard() async {
    if (!await Clipboard.hasStrings()) return;
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text;
    if (text == null || !_isUrl(text)) return;
    _controller.text = text;
  }

  bool _isUrl(String text) => Uri.tryParse(text)?.hasScheme == true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.insert_link),
      title: Text(AppLocalizations.of(context)!.inputUrlDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: _confirm,
      ),
    );
  }

  bool _validate(String value) {
    if (value.isEmpty) return false;
    return _isUrl(value);
  }

  Future<void> _confirm(String value) async {
    if (!_validate(value)) return;
    Navigator.pop(context, Uri.parse(value));
  }
}

extension RecentFilesSortKeyDisplayString on RecentFilesSortKey {
  String toDisplayString(BuildContext context) => switch (this) {
    RecentFilesSortKey.lastOpened => AppLocalizations.of(
      context,
    )!.sortKeyLastOpened,
    RecentFilesSortKey.name => AppLocalizations.of(context)!.sortKeyName,
    RecentFilesSortKey.location => AppLocalizations.of(
      context,
    )!.sortKeyLocation,
  };
}

extension SortOrderDisplayString on SortOrder {
  String toDisplayString(BuildContext context) => switch (this) {
    SortOrder.ascending => AppLocalizations.of(context)!.sortOrderAscending,
    SortOrder.descending => AppLocalizations.of(context)!.sortOrderDescending,
  };
}

class CaptureTargetDialog extends StatelessWidget {
  const CaptureTargetDialog({
    required this.title,
    required this.files,
    super.key,
  });

  final String title;
  final List<RememberedFile> files;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, idx) {
            switch (idx) {
              case 0:
                return ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(
                    AppLocalizations.of(context)!.captureToClipboardItem,
                  ),
                  onTap: () =>
                      Navigator.pop(context, (CaptureTarget.clipboard, null)),
                );
              case 1:
                return ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(
                    AppLocalizations.of(context)!.captureToNewDocumentItem,
                  ),
                  onTap: () =>
                      Navigator.pop(context, (CaptureTarget.scratch, null)),
                );
              default:
                final file = files[idx - 2];
                return RememberedFileListTile(
                  file,
                  onTap: () =>
                      Navigator.pop(context, (CaptureTarget.document, file)),
                );
            }
          },
          itemCount: files.length + 2,
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  const DialogButton({super.key, required this.text, required this.onPressed});

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
