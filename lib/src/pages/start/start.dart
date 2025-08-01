import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/components/about.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/start/remembered_files.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/routes/routes.dart';
import 'package:orgro/src/util.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State createState() => StartPageState();
}

class StartPageState extends State<StartPage> with PlatformOpenHandler {
  @override
  Widget build(BuildContext context) {
    final hasRememberedFiles = RememberedFiles.of(context).hasRememberedFiles;
    return Scaffold(
      appBar: AppBar(
        actions: _buildActions(
          hasRememberedFiles: hasRememberedFiles,
        ).toList(growable: false),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.appTitle),
            const FontPreloader(),
          ],
        ),
      ),
      body: _KeyboardShortcuts(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: hasRememberedFiles
              ? const RememberedFilesBody()
              : const _EmptyBody(),
        ),
      ),
      floatingActionButton: hasRememberedFiles
          ? _buildFloatingActionButton(context)
          : null,
    );
  }

  Iterable<Widget> _buildActions({required bool hasRememberedFiles}) sync* {
    yield PopupMenuButton<VoidCallback>(
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        if (RememberedFiles.of(context).hasRememberedFiles) ...[
          PopupMenuItem<VoidCallback>(
            value: () => _promptAndOpenUrl(context),
            child: Text(AppLocalizations.of(context)!.menuItemOpenUrl),
          ),
          PopupMenuItem<VoidCallback>(
            value: () => _openOrgroManual(context),
            child: Text(AppLocalizations.of(context)!.menuItemOrgroManual),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<VoidCallback>(
          value: () => _openSettingsScreen(context),
          child: Text(AppLocalizations.of(context)!.menuItemSettings),
        ),
        if (!kReleaseMode && !kScreenshotMode) ...[
          const PopupMenuDivider(),
          if (hasRememberedFiles)
            PopupMenuItem<VoidCallback>(
              value: () => _openOrgManual(context),
              child: Text(AppLocalizations.of(context)!.menuItemOrgManual),
            ),
          PopupMenuItem<VoidCallback>(
            value: () => _openTestFile(context),
            child: Text(AppLocalizations.of(context)!.menuItemTestFile),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem<VoidCallback>(
          value: () => openAboutDialog(context),
          child: Text(AppLocalizations.of(context)!.menuItemAbout),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: 16,
      children: [
        FloatingActionButton(
          onPressed: () => _createAndOpenFile(context),
          heroTag: 'NewFileFAB',
          mini: true,
          child: const Icon(Icons.create),
        ),
        FloatingActionButton(
          onPressed: () => loadAndRememberFile(context, pickFile()),
          heroTag: 'OpenFileFAB',
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          child: const Icon(Icons.folder_open),
        ),
      ],
    );
  }

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _inited = true;
      // RestorationMixin.restoreRoute is ultimately called during
      // didChangeDependencies, so we do the same here.
      //
      // We don't use RestorationMixin here because we don't want StartPage to
      // have its own bucket; we want it and QuickActions to use the root bucket
      // so that routes remembered by either can be restored here.
      _restoreRoute();
    }
  }

  void _restoreRoute() {
    final bucket = RestorationScope.of(context);
    final restoreRoute = bucket.read<String>(kRestoreRouteKey);
    debugPrint('restoreState; restoreRoute=$restoreRoute');
    if (restoreRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final restoreData = json.decode(restoreRoute);
        final context = this.context;
        switch (restoreData) {
          case {'route': Routes.document, 'fileId': String fileId}:
            await loadAndRememberFile(context, readFileWithIdentifier(fileId));
            return;
          case {'route': Routes.document, 'url': String url}:
            await loadAndRememberUrl(context, Uri.parse(url));
            return;
          case {'route': Routes.document, 'assetKey': String key}:
            await loadAndRememberAsset(context, key);
            return;
          default:
            debugPrint('Unknown route: ${restoreData['route']}');
            return;
        }
      });
    }
  }
}

class _KeyboardShortcuts extends StatelessWidget {
  const _KeyboardShortcuts({required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyO): () =>
            loadAndRememberFile(context, pickFile()),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    // This Center ensures that its entire child is centered on screen when the
    // screen is tall enough that no scrolling is requied.
    return Center(
      child: SingleChildScrollView(
        // This Center allows the child to fill the available space, so you can
        // e.g. scroll the very edges of the view rather than just the Column.
        child: Center(
          // Padding ensures the child is not flush against the screen edges
          // when the screen is short.
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // IntrinsicWidth needed to get all elements the same width without
            // having to specify a fixed width. This then requires a Column rather
            // than e.g. a ListView.
            child: IntrinsicWidth(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...[
                    const _PickFileButton(),
                    const _CreateFileButton(),
                    const _OpenUrlButton(),
                    const _OrgroManualButton(),
                    if (!kReleaseMode && !kScreenshotMode)
                      const _OrgManualButton(),
                  ].separatedBy(const SizedBox(height: 16)),
                  const SizedBox(height: 80),
                  const _SupportLink(),
                  const _VersionInfoButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _createAndOpenFile(BuildContext context) async {
  final fileName = await showDialog<String>(
    context: context,
    builder: (context) => InputFileNameDialog(
      title: AppLocalizations.of(context)!.createFileDialogTitle,
    ),
  );
  if (fileName == null || !context.mounted) return;
  final orgFileName = fileName.toLowerCase().endsWith('.org')
      ? fileName
      : '$fileName.org';
  return await loadAndRememberFile(
    context,
    createAndLoadFile(orgFileName),
    mode: InitialMode.edit,
  );
}

class _PickFileButton extends StatelessWidget {
  const _PickFileButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      onPressed: () => loadAndRememberFile(context, pickFile()),
      child: Text(AppLocalizations.of(context)!.buttonOpenFile),
    );
  }
}

Future<void> _promptAndOpenUrl(BuildContext context) async {
  final url = await showDialog<Uri>(
    context: context,
    builder: (context) => const InputUrlDialog(),
  );
  if (url == null || !context.mounted) return;
  return await loadHttpUrl(context, url);
}

class _CreateFileButton extends StatelessWidget {
  const _CreateFileButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      onPressed: () => _createAndOpenFile(context),
      child: Text(AppLocalizations.of(context)!.buttonCreateFile),
    );
  }
}

class _OpenUrlButton extends StatelessWidget {
  const _OpenUrlButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      onPressed: () => _promptAndOpenUrl(context),
      child: Text(AppLocalizations.of(context)!.buttonOpenUrl),
    );
  }
}

class _OrgManualButton extends StatelessWidget {
  const _OrgManualButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _openOrgManual(context),
      child: Text(AppLocalizations.of(context)!.buttonOpenOrgManual),
    );
  }
}

class _OrgroManualButton extends StatelessWidget {
  const _OrgroManualButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _openOrgroManual(context),
      child: Text(AppLocalizations.of(context)!.buttonOpenOrgroManual),
    );
  }
}

Future<void> _openOrgroManual(BuildContext context) =>
    loadAndRememberAsset(context, LocalAssets.manual);

Future<void> _openOrgManual(BuildContext context) =>
    loadAndRememberUrl(context, Uri.parse(RemoteAssets.orgManual));

Future<void> _openTestFile(BuildContext context) =>
    loadAndRememberAsset(context, LocalAssets.testFile);

void _openSettingsScreen(BuildContext context) =>
    Navigator.pushNamed(context, Routes.settings);

class _SupportLink extends StatelessWidget {
  const _SupportLink();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.help),
      label: Text(AppLocalizations.of(context)!.buttonSupport),
      onPressed: visitSupportLink,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).disabledColor,
      ),
    );
  }
}

class _VersionInfoButton extends StatelessWidget {
  const _VersionInfoButton();
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: visitChangelogLink,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).disabledColor,
      ),
      child: Text(AppLocalizations.of(context)!.buttonVersion(orgroVersion)),
    );
  }
}
