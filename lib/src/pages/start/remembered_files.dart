import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/list.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class RememberedFilesBody extends StatelessWidget {
  const RememberedFilesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final remembered = RememberedFiles.of(context);
    final sortedPins = remembered.pinned;
    final sortedRecents = remembered.recents
      ..sort((a, b) {
        final result = switch (remembered.sortKey) {
          RecentFilesSortKey.lastOpened => a.lastOpened.compareTo(b.lastOpened),
          RecentFilesSortKey.name => a.name.compareTo(b.name),
          RecentFilesSortKey.location =>
            (_appName(context, a.uri) ?? a.uri).compareTo(
              _appName(context, b.uri) ?? b.uri,
            ),
        };
        return remembered.sortOrder == SortOrder.ascending ? result : -result;
      });
    // We let ListView fill the viewport and constrain its children so that the
    // list can be scrolled even by the edges of the view.
    return ListView(
      children: [
        if (sortedPins.isNotEmpty) ...[
          _constrain(
            ListHeader(
              title: Text(
                AppLocalizations.of(context)!.sectionHeaderPinnedFiles,
              ),
            ),
          ),
          ReorderableListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedPins.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final pinnedFile = sortedPins[index];
              return _constrain(
                _RememberedFileManagementListTile(pinnedFile),
                key: ValueKey(pinnedFile),
              );
            },
            onReorderItem: (oldIndex, newIndex) {
              final pins = [...sortedPins];
              final moved = pins.removeAt(oldIndex);
              final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
              pins.insert(insertAt, moved);
              final reindexed = pins.indexed
                  .map2((i, file) => file.copyWith(pinnedIdx: i))
                  .toList(growable: false);
              RememberedFiles.of(context).add(reindexed);
            },
          ),
        ],
        if (sortedRecents.isNotEmpty) ...[
          _constrain(
            ListHeader(
              title: Text(
                AppLocalizations.of(context)!.sectionHeaderRecentFiles,
              ),
              trailing: _RecentFilesListSortControl(),
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedRecents.length,
            itemBuilder: (context, index) {
              final recentFile = sortedRecents[index];
              return _constrain(
                _RememberedFileManagementListTile(recentFile),
                key: ValueKey(recentFile),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _constrain(Widget child, {Key? key}) => Center(
    key: key,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: child,
    ),
  );
}

class _RecentFilesListSortControl extends StatelessWidget {
  const _RecentFilesListSortControl();

  @override
  Widget build(BuildContext context) {
    final prefs = Preferences.of(context, PrefsAspect.recentFiles);
    final sortKey = prefs.recentFilesSortKey;
    final sortOrder = prefs.recentFilesSortOrder;
    final iconSize = 16.0;
    final iconColor = Theme.of(context).hintColor;
    return TextButton(
      onPressed: () async {
        final result = await showDialog<(RecentFilesSortKey, SortOrder)>(
          context: context,
          builder: (context) =>
              RecentFilesSortDialog(sortKey: sortKey, sortOrder: sortOrder),
        );
        if (result case (final key, final newOrder)) {
          await prefs.setRecentFilesSortKey(key);
          await prefs.setRecentFilesSortOrder(newOrder);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (sortKey) {
              RecentFilesSortKey.lastOpened => Icons.access_time,
              RecentFilesSortKey.name => Icons.sort_by_alpha,
              RecentFilesSortKey.location => Icons.folder,
            },
            size: iconSize,
            color: iconColor,
          ),
          Icon(
            switch (sortOrder) {
              SortOrder.ascending => Icons.arrow_upward,
              SortOrder.descending => Icons.arrow_downward,
            },
            size: iconSize,
            color: iconColor,
          ),
        ],
      ),
    );
  }
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
      'com.google.android.apps.docs.storage' => AppLocalizations.of(
        context,
      )!.fileSourceGoogleDrive,
      'com.seafile.seadroid2.documents' => 'Seafile',
      'com.termux.documents' => 'Termux',
      'com.android.externalstorage.documents' => AppLocalizations.of(
        context,
      )!.fileSourceDocuments,
      'com.android.providers.downloads.documents' => AppLocalizations.of(
        context,
      )!.fileSourceDownloads,
      'com.dropbox.product.android.dbapp.document_provider.documents' =>
        'Dropbox',
      _ => uri.host,
    },
    'file' =>
      uri.path.startsWith(
            '/private/var/mobile/Library/Mobile%20Documents/com~apple~CloudDocs/',
          )
          ? 'iCloud Drive'
          : null,
    _ => null,
  };
}

class _RememberedFileManagementListTile extends StatelessWidget {
  const _RememberedFileManagementListTile(this.recentFile);

  final RememberedFile recentFile;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(recentFile),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            backgroundColor: recentFile.isPinned ? Colors.grey : Colors.blue,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            icon: Icons.push_pin,
            onPressed: (context) {
              if (recentFile.isPinned) {
                RememberedFiles.of(context).unpin(recentFile);
              } else {
                RememberedFiles.of(context).pin(recentFile);
              }
            },
          ),
          SlidableAction(
            backgroundColor: Colors.red,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            icon: Icons.delete,
            onPressed: (context) =>
                RememberedFiles.of(context).remove(recentFile),
          ),
        ],
      ),
      child: RememberedFileListTile(
        recentFile,
        showAccessTime: true,
        onTap: () => _open(context),
      ),
    );
  }

  void _open(BuildContext context) async {
    if (recentFile.isWebUri) {
      await loadAndRememberUrl(context, Uri.parse(recentFile.uri));
      return;
    }
    final (:result, :succeeded) = await progressTask(
      context,
      dialogTitle: AppLocalizations.of(context)!.loadingProgressDialogTitle,
      task: _tryOurDamnedestToLoadFile(context),
    );
    if (!succeeded || result == null) return;
    final (:dataSource, :recovered) = result;
    if (recovered) {
      await loadAndReplaceRememberedFile(
        context,
        recentFile.identifier,
        dataSource,
      );
    } else {
      await loadAndRememberFile(context, dataSource);
    }
  }

  // Returns a tuple of (NativeDataSource, bool) where the bool indicates
  // whether the file needs to be replaced (true) or loaded normally (false).
  // Returns null if the operation was cancelled.
  Future<({NativeDataSource dataSource, bool recovered})?>
  _tryOurDamnedestToLoadFile(
    BuildContext context, {
    Iterable<String>? accessibleDirs,
  }) async {
    accessibleDirs ??= Preferences.of(
      context,
      .accessibleDirs,
    ).data.accessibleDirs;
    try {
      return await readFileWithIdentifierWithRecoveryStrategy(
        identifier: recentFile.identifier,
        fileName: recentFile.name,
        accessibleDirs: accessibleDirs,
      );
    } on NotFoundException catch (e, s) {
      logError(e, s);
      final dirAccessSupported = await canObtainNativeDirectoryPermissions();
      if (!context.mounted) return null;
      final choice = await showDialog<_NotFoundAction>(
        context: context,
        builder: (context) =>
            _NotFoundDialog(dirAccessSupported: dirAccessSupported),
      );
      switch (choice) {
        case .locate:
          final replacement = await pickFile();
          return replacement == null
              ? null
              : (dataSource: replacement, recovered: true);
        case .grant:
          final granted = await pickDirectory();
          if (granted == null) return null;
          if (!context.mounted) return null;
          await Preferences.of(
            context,
            .accessibleDirs,
          ).addAccessibleDir(granted.identifier);
          if (!context.mounted) return null;
          return await _tryOurDamnedestToLoadFile(
            context,
            accessibleDirs: [granted.identifier, ...accessibleDirs].unique(),
          );
        case .remove:
          if (!context.mounted) return null;
          await RememberedFiles.of(context).remove(recentFile);
          return null;
        case null:
          // User dismissed the dialog without making a choice. Cancel.
          return null;
      }
    }
  }
}

enum _NotFoundAction { locate, grant, remove }

class _NotFoundDialog extends StatelessWidget {
  const _NotFoundDialog({required this.dirAccessSupported});

  final bool dirAccessSupported;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.link_off),
      title: Text(AppLocalizations.of(context)!.notFoundDialogTitle),
      contentPadding: const EdgeInsets.all(8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              // This padding adapted from [AlertDialog.contentPadding] defaults.
              // Needs to be updated when moving to Material 3.
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: dirAccessSupported
                  ? Text(AppLocalizations.of(context)!.notFoundDialogBody)
                  : Text(
                      AppLocalizations.of(context)!
                          .notFoundDialogNoDirAccessBody,
                    ),
            ),
            if (dirAccessSupported)
              ListTile(
                title: Text(
                  AppLocalizations.of(context)!.notFoundDialogActionGrantAccess
                      .toUpperCase(),
                ),
                onTap: () => Navigator.pop(context, _NotFoundAction.grant),
              ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.notFoundDialogActionLocate
                    .toUpperCase(),
              ),
              onTap: () => Navigator.pop(context, _NotFoundAction.locate),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.notFoundDialogActionRemove
                    .toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.pop(context, _NotFoundAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

class RememberedFileListTile extends StatelessWidget {
  const RememberedFileListTile(
    this.rememberedFile, {
    required this.onTap,
    this.showAccessTime,
    super.key,
  });

  final RememberedFile rememberedFile;
  final VoidCallback onTap;
  final bool? showAccessTime;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: rememberedFile.isWebUri
          // The Language icon is an abstract globe, which in my opinion is more
          // suggestive of a website than Web or Public
          ? const Icon(Icons.language)
          : const Icon(Icons.insert_drive_file),
      title: Text(rememberedFile.name),
      subtitle: Row(
        children: [
          if (showAccessTime == true) ...[
            Icon(
              Icons.access_time,
              size: Theme.of(context).textTheme.bodyMedium?.fontSize,
              applyTextScaling: true,
            ),
            const SizedBox(width: 2),
            Text(
              _formatLastOpenedDate(
                rememberedFile.lastOpened,
                AppLocalizations.of(context)!.localeName,
              ),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
          ...(() sync* {
            final appName = _appName(context, rememberedFile.uri);
            if (appName != null) {
              if (showAccessTime == true) {
                yield const SizedBox(width: 8);
              }
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
      onTap: onTap,
    );
  }
}
