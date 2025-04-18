import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/about.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/settings.dart';
import 'package:orgro/src/pages/start/remembered_files.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/util.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with RecentFilesState, PlatformOpenHandler, RestorationMixin {
  @override
  Widget build(BuildContext context) => UnmanagedRestorationScope(
    bucket: bucket,
    child: buildWithRememberedFiles(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            actions: _buildActions().toList(growable: false),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.appTitle),
                fontPreloader(context),
              ],
            ),
          ),
          body: _KeyboardShortcuts(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  hasRememberedFiles
                      ? const RememberedFilesBody()
                      : const _EmptyBody(),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      },
    ),
  );

  Iterable<Widget> _buildActions() sync* {
    yield PopupMenuButton<VoidCallback>(
      onSelected: (callback) => callback(),
      itemBuilder:
          (context) => [
            PopupMenuItem<VoidCallback>(
              value: () => _openSettingsScreen(context),
              child: Text(AppLocalizations.of(context)!.menuItemSettings),
            ),
            if (hasRememberedFiles) ...[
              const PopupMenuDivider(),
              PopupMenuItem<VoidCallback>(
                value: () => _openOrgroManual(context),
                child: Text(AppLocalizations.of(context)!.menuItemOrgroManual),
              ),
            ],
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

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (!hasRememberedFiles) {
      return null;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => _createAndOpenFile(context),
          heroTag: 'NewFileFAB',
          mini: true,
          child: const Icon(Icons.create),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () => loadAndRememberFile(context, pickFile()),
          heroTag: 'OpenFileFAB',
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          child: const Icon(Icons.folder_open),
        ),
      ],
    );
  }

  @override
  Future<bool> loadFileFromPlatform(NativeDataSource info) async {
    // We can't use _loadAndRememberFile because RecentFiles is not in this
    // context
    final recentFile = await loadFile(context, info);
    if (recentFile != null) {
      _rememberFile(recentFile);
      return true;
    } else {
      return false;
    }
  }

  @override
  String get restorationId => 'start_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (!initialRestore) return;

    final restoreId = bucket?.read<String>(kRestoreOpenFileIdKey);
    debugPrint('restoreState; restoreId=$restoreId');
    if (restoreId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final recentFile = await loadFile(
          context,
          readFileWithIdentifier(restoreId),
          bucket: bucket,
        );
        _rememberFile(recentFile);
      });
    }
  }

  void _rememberFile(RememberedFile? recentFile) {
    if (recentFile == null) {
      return;
    }
    addRecentFiles([recentFile]);
    debugPrint('Saving file ID to state');
    bucket?.write<String>(kRestoreOpenFileIdKey, recentFile.identifier);
  }
}

class _KeyboardShortcuts extends StatelessWidget {
  const _KeyboardShortcuts({required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyO):
            () => loadAndRememberFile(context, pickFile()),
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
                  const _PickFileButton(),
                  const SizedBox(height: 16),
                  const _CreateFileButton(),
                  const SizedBox(height: 16),
                  const _OrgroManualButton(),
                  if (!kReleaseMode && !kScreenshotMode) ...[
                    const SizedBox(height: 16),
                    const _OrgManualButton(),
                  ],
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
    builder: (context) => InputFileNameDialog(),
  );
  if (fileName == null || !context.mounted) return;
  final orgFileName =
      fileName.toLowerCase().endsWith('.org') ? fileName : '$fileName.org';
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

void _openOrgroManual(BuildContext context) =>
    loadAsset(context, 'assets/manual/orgro-manual.org');

void _openOrgManual(BuildContext context) => loadHttpUrl(
  context,
  Uri.parse('https://git.sr.ht/~bzg/org-mode/blob/main/doc/org-manual.org'),
);

void _openTestFile(BuildContext context) =>
    loadAsset(context, 'assets/test/test.org');

void _openSettingsScreen(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder:
        (context) =>
            ViewSettings.defaults(context, child: const SettingsPage()),
    fullscreenDialog: true,
  ),
);

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
