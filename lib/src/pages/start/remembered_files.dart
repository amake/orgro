import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/list.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class RememberedFilesBody extends StatelessWidget {
  const RememberedFilesBody({super.key});

  @override
  Widget build(BuildContext context) {
    final remembered = RememberedFiles.of(context);
    final sortedPins =
        remembered.pinned..sort((a, b) => a.pinnedIdx.compareTo(b.pinnedIdx));
    final sortedRecents =
        remembered.recents..sort((a, b) {
          final result = switch (remembered.sortKey) {
            RecentFilesSortKey.lastOpened => a.lastOpened.compareTo(
              b.lastOpened,
            ),
            RecentFilesSortKey.name => a.name.compareTo(b.name),
            RecentFilesSortKey.location => (_appName(context, a.uri) ?? a.uri)
                .compareTo(_appName(context, b.uri) ?? b.uri),
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
                _RememberedFileListTile(pinnedFile),
                key: ValueKey(pinnedFile),
              );
            },
            onReorder: (oldIndex, newIndex) {
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
                _RememberedFileListTile(recentFile),
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
          builder:
              (context) =>
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
    'file' =>
      uri.path.startsWith(
            '/private/var/mobile/Library/Mobile%20Documents/com~apple~CloudDocs/',
          )
          ? 'iCloud Drive'
          : null,
    _ => null,
  };
}

class _RememberedFileListTile extends StatelessWidget {
  const _RememberedFileListTile(this.recentFile);

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
            onPressed:
                (context) => RememberedFiles.of(context).remove(recentFile),
          ),
        ],
      ),
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
        onTap:
            () async => loadAndRememberFile(
              context,
              readFileWithIdentifier(recentFile.identifier),
            ),
      ),
    );
  }
}
