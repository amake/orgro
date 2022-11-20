import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:orgro/src/actions/appearance.dart';
import 'package:orgro/src/actions/cache.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/about.dart';
import 'package:orgro/src/pages/recent_files.dart';
import 'package:orgro/src/util.dart';

const _kRestoreOpenFileIdKey = 'restore_open_file_id';

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
      child: buildWithRecentFiles(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.appTitle),
            actions: _buildActions().toList(growable: false),
          ),
          body: _KeyboardShortcuts(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasRecentFiles
                  ? const _RecentFilesBody()
                  : const _EmptyBody(),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      }));

  Iterable<Widget> _buildActions() sync* {
    yield PopupMenuButton<VoidCallback>(
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        appearanceMenuItem(context),
        clearCacheMenuItem(context),
        if (hasRecentFiles) ...[
          const PopupMenuDivider(),
          PopupMenuItem<VoidCallback>(
            value: () => _openOrgroManual(context),
            child: Text(AppLocalizations.of(context)!.menuItemOrgroManual),
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
    if (!hasRecentFiles) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () => _loadAndRememberFile(context, pickFile()),
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      child: const Icon(Icons.add),
    );
  }

  @override
  Future<bool> loadFileFromPlatform(NativeDataSource info) async {
    // We can't use _loadAndRememberFile because RecentFiles is not in this
    // context
    final recentFile = await _loadFile(context, info);
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
    final restoreId = bucket?.read<String>(_kRestoreOpenFileIdKey);
    debugPrint('restoreState; restoreId=$restoreId');
    if (restoreId != null) {
      Future.delayed(const Duration(microseconds: 0), () async {
        // We can't use _loadAndRememberFile because RecentFiles is not in this
        // context
        final recentFile = await _loadFile(
          context,
          readFileWithIdentifier(restoreId),
        );
        _rememberFile(recentFile);
      });
    }
  }

  void _rememberFile(RecentFile? recentFile) {
    if (recentFile == null) {
      return;
    }
    addRecentFile(recentFile);
    debugPrint('Saving file ID to state');
    bucket?.write<String>(_kRestoreOpenFileIdKey, recentFile.identifier);
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
            _loadAndRememberFile(context, pickFile()),
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _PickFileButton(),
              const SizedBox(height: 16),
              const _OrgroManualButton(),
              if (!kReleaseMode && !kScreenshotMode) ...[
                const SizedBox(height: 16),
                const _OrgManualButton(),
              ],
              const SizedBox(height: 80),
              const _SupportLink(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _VersionInfoButton(),
                  fontPreloader(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFilesBody extends StatelessWidget {
  const _RecentFilesBody();

  @override
  Widget build(BuildContext context) {
    final recentFiles = RecentFiles.of(context).list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          itemCount: recentFiles.length + 1,
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return _ListHeader(
                title: Text(
                  AppLocalizations.of(context)!.sectionHeaderRecentFiles,
                ),
              );
            } else {
              final recentFile = recentFiles[idx - 1];
              return _RecentFileListTile(recentFile);
            }
          },
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: DefaultTextStyle.merge(
        // Couldn't find actual specs for list subheader typography so this is
        // my best guess
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.secondary,
        ),
        child: title,
      ),
      trailing: fontPreloader(context),
    );
  }
}

// Do not make format object a constant because it will break dynamic UI
// language switching
String _formatLastOpenedDate(DateTime date, String locale) =>
    DateFormat.yMd(locale).add_jm().format(date);

class _RecentFileListTile extends StatelessWidget {
  const _RecentFileListTile(this.recentFile);

  final RecentFile recentFile;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(recentFile),
      onDismissed: (_) => RecentFiles.of(context).remove(recentFile),
      background: const _SwipeDeleteBackground(alignment: Alignment.centerLeft),
      secondaryBackground:
          const _SwipeDeleteBackground(alignment: Alignment.centerRight),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file),
        title: Text(recentFile.name),
        subtitle: Text(
          _formatLastOpenedDate(
              recentFile.lastOpened, AppLocalizations.of(context)!.localeName),
        ),
        onTap: () async => _loadAndRememberFile(
          context,
          readFileWithIdentifier(recentFile.identifier),
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({required this.alignment});

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.all(24),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}

Future<RecentFile?> _loadFile(
  BuildContext context,
  FutureOr<NativeDataSource?> dataSource,
) async {
  final restorationScope = RestorationScope.of(context);
  final loaded = await loadDocument(
    context,
    dataSource,
    onClose: () {
      debugPrint('Clearing saved state');
      restorationScope.remove<String>(_kRestoreOpenFileIdKey);
    },
  );
  RecentFile? result;
  if (loaded) {
    final source = await dataSource;
    if (source == null) {
      // User canceled
    } else {
      if (source.persistable) {
        result = RecentFile(
          source.identifier,
          source.name,
          DateTime.now(),
        );
      } else {
        debugPrint('Couldn’t obtain persistent access to ${source.name}');
      }
    }
  }
  return result;
}

Future<void> _loadAndRememberFile(
  BuildContext context,
  FutureOr<NativeDataSource?> fileInfoFuture,
) async {
  final recentFiles = RecentFiles.of(context);
  final restorationScope = RestorationScope.of(context);
  final recentFile = await _loadFile(context, fileInfoFuture);
  if (recentFile != null) {
    recentFiles.add(recentFile);
    debugPrint('Saving file ID to state');
    restorationScope.write<String>(
      _kRestoreOpenFileIdKey,
      recentFile.identifier,
    );
  }
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
      onPressed: () => _loadAndRememberFile(context, pickFile()),
      child: Text(AppLocalizations.of(context)!.buttonOpenFile),
    );
  }
}

class _OrgManualButton extends StatelessWidget {
  const _OrgManualButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => loadHttpUrl(
        context,
        Uri.parse(
          'https://code.orgmode.org/bzg/org-mode/raw/master/doc/org-manual.org',
        ),
      ),
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

class _SupportLink extends StatelessWidget {
  const _SupportLink();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.help),
      label: Text(AppLocalizations.of(context)!.buttonSupport),
      onPressed: visitSupportLink,
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).disabledColor),
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
          foregroundColor: Theme.of(context).disabledColor),
      child: Text(AppLocalizations.of(context)!.buttonVersion(orgroVersion)),
    );
  }
}
