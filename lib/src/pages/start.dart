import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:orgro/src/components/about.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/list.dart';
import 'package:orgro/src/components/recent_files.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/settings.dart';
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
        PopupMenuItem<VoidCallback>(
          value: () => _openSettingsScreen(context),
          child: Text('Settings...'), // TODO(aaron): L10N
        ),
        if (hasRecentFiles) ...[
          const PopupMenuDivider(),
          PopupMenuItem<VoidCallback>(
            value: () => _openOrgroManual(context),
            child: Text(AppLocalizations.of(context)!.menuItemOrgroManual),
          ),
        ],
        if (!kReleaseMode && !kScreenshotMode) ...[
          const PopupMenuDivider(),
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
    if (!hasRecentFiles) {
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
          onPressed: () => _loadAndRememberFile(context, pickFile()),
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
    if (!initialRestore) return;

    final restoreId = bucket?.read<String>(_kRestoreOpenFileIdKey);
    debugPrint('restoreState; restoreId=$restoreId');
    if (restoreId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final recentFile = await _loadFile(
          context,
          readFileWithIdentifier(restoreId),
          bucket: bucket,
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
    // We let ListView fill the viewport and constrain its children so that the
    // list can be scrolled even by the edges of the view.
    return ListView.builder(
      itemCount: recentFiles.length + 1,
      itemBuilder: (context, idx) {
        if (idx == 0) {
          return _constrain(ListHeader(
            title: Text(
              AppLocalizations.of(context)!.sectionHeaderRecentFiles,
            ),
          ));
        } else {
          final recentFile = recentFiles[idx - 1];
          return _constrain(_RecentFileListTile(recentFile));
        }
      },
    );
  }

  Widget _constrain(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      );
}

// Do not make format object a constant because it will break dynamic UI
// language switching
String _formatLastOpenedDate(DateTime date, String locale) =>
    DateFormat.yMd(locale).add_jm().format(date);

String? _appName(BuildContext context, String uriString) {
  final uri = Uri.tryParse(uriString);
  if (uri == null) return null;
  // On Android we can reliably get the package name from the URI. On iOS,
  // iCloud Drive has a distinguishable path, but all apps are in
  // /private/var/mobile/Containers/Shared/AppGroup/GUID where the GUID is
  // device-specific so we have no chance.
  //
  // Supposedly we can get the human-readable app names on Android, but it
  // requires an invasive permission:
  // https://developer.android.com/training/package-visibility
  return switch (uri.scheme) {
    'content' => switch (uri.host) {
        'org.nextcloud.documents' => 'Nextcloud',
        'com.google.android.apps.docs.storage' =>
          AppLocalizations.of(context)!.fileSourceGoogleDrive,
        'com.seafile.seadroid2.documents' => 'Seafile',
        'com.termux.documents' => 'Termux',
        'com.android.externalstorage.documents' =>
          AppLocalizations.of(context)!.fileSourceDocuments,
        'com.android.providers.downloads.documents' =>
          AppLocalizations.of(context)!.fileSourceDownloads,
        'com.dropbox.product.android.dbapp.document_provider.documents' =>
          'Dropbox',
        _ => uri.host,
      },
    'file' => uri.path.startsWith(
            '/private/var/mobile/Library/Mobile%20Documents/com~apple~CloudDocs/')
        ? 'iCloud Drive'
        : null,
    _ => null,
  };
}

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
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time,
              size: Theme.of(context).textTheme.bodyMedium?.fontSize,
              applyTextScaling: true,
            ),
            const SizedBox(width: 2),
            Text(
              _formatLastOpenedDate(
                recentFile.lastOpened,
                AppLocalizations.of(context)!.localeName,
              ),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            ...(() sync* {
              final appName = _appName(context, recentFile.uri);
              if (appName != null) {
                yield const SizedBox(width: 8);
                yield Icon(
                  Icons.folder_outlined,
                  size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  applyTextScaling: true,
                );
                yield const SizedBox(width: 2);
                yield Expanded(
                  child: Text(
                    appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
            })(),
          ],
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
  FutureOr<NativeDataSource?> dataSource, {
  RestorationBucket? bucket,
  InitialMode? mode,
}) async {
  bucket ??= RestorationScope.of(context);
  final loaded = await loadDocument(
    context,
    dataSource,
    onClose: () {
      debugPrint('Clearing saved state from bucket $bucket');
      bucket!.remove<String>(_kRestoreOpenFileIdKey);
    },
    mode: mode,
  );
  RecentFile? result;
  if (loaded) {
    final source = await dataSource;
    if (source == null) {
      // User canceled
    } else {
      if (source.persistable) {
        result = RecentFile(
          identifier: source.identifier,
          name: source.name,
          uri: source.uri,
          lastOpened: DateTime.now(),
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
  FutureOr<NativeDataSource?> fileInfoFuture, {
  InitialMode? mode,
}) async {
  final recentFiles = RecentFiles.of(context);
  final bucket = RestorationScope.of(context);
  final recentFile = await _loadFile(context, fileInfoFuture, mode: mode);
  if (recentFile != null) {
    recentFiles.add(recentFile);
    debugPrint('Saving file ID to bucket $bucket');
    bucket.write<String>(
      _kRestoreOpenFileIdKey,
      recentFile.identifier,
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
  return await _loadAndRememberFile(
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
      onPressed: () => _loadAndRememberFile(context, pickFile()),
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
      onPressed: () => loadHttpUrl(
        context,
        Uri.parse(
          'https://git.sr.ht/~bzg/org-mode/blob/main/doc/org-manual.org',
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

void _openTestFile(BuildContext context) =>
    loadAsset(context, 'assets/test/test.org');

void _openSettingsScreen(BuildContext context) {
  final recentFiles = RecentFiles.of(context);
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => RecentFiles.from(
        recentFiles,
        child: ViewSettings.defaults(context, child: const SettingsPage()),
      ),
      fullscreenDialog: true,
    ),
  );
}

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
