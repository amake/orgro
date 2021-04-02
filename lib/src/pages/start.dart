import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:orgro/src/actions/appearance.dart';
import 'package:orgro/src/actions/cache.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/recent_files.dart';
import 'package:url_launcher/url_launcher.dart';

const _kRestoreOpenFileIdKey = 'restore_open_file_id';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with RecentFilesState, PlatformOpenHandler, RestorationMixin {
  @override
  Widget build(BuildContext context) => UnmanagedRestorationScope(
      bucket: bucket,
      child: buildWithRecentFiles(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Orgro'),
            actions: _buildActions().toList(growable: false),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                hasRecentFiles ? const _RecentFilesBody() : const _EmptyBody(),
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
            child: const Text('Orgro Manual'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<VoidCallback>(
            value: _visitSupportLink,
            child: Text('Support · Feedback'),
          ),
          PopupMenuItem<VoidCallback>(
            value: () => _openLicensePage(context),
            child: const Text('Licenses'),
          ),
        ]
      ],
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (!hasRecentFiles) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () => _loadAndRememberFile(context, pickFile()),
      foregroundColor: Theme.of(context).accentTextTheme.button?.color,
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

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({Key? key}) : super(key: key);

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
                  const _LicensesButton(),
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
  const _RecentFilesBody({Key? key}) : super(key: key);

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
              return const _ListHeader(title: Text('Recent files'));
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
  const _ListHeader({required this.title, Key? key}) : super(key: key);

  final Widget title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: DefaultTextStyle.merge(
        // Couldn't find actual specs for list subheader typography so this is
        // my best guess
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).accentColor,
        ),
        child: title,
      ),
      trailing: fontPreloader(context),
    );
  }
}

final _kLastOpenedFormat = DateFormat.yMd().add_jm();

class _RecentFileListTile extends StatelessWidget {
  const _RecentFileListTile(this.recentFile, {Key? key}) : super(key: key);

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
        subtitle: Text(_kLastOpenedFormat.format(recentFile.lastOpened)),
        onTap: () async => _loadAndRememberFile(
          context,
          readFileWithIdentifier(recentFile.identifier),
        ),
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({required this.alignment, Key? key})
      : super(key: key);

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.all(24),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Theme.of(context).accentTextTheme.button?.color,
      ),
    );
  }
}

Future<RecentFile?> _loadFile(
  BuildContext context,
  FutureOr<NativeDataSource?> dataSource,
) async {
  final loaded = await loadDocument(
    context,
    dataSource,
    onClose: () {
      debugPrint('Clearing saved state');
      RestorationScope.of(context)?.remove<String>(_kRestoreOpenFileIdKey);
    },
  );
  RecentFile? result;
  if (loaded) {
    final source = await dataSource;
    if (source == null) {
      // User canceled
    } else {
      final identifier = source.identifier;
      if (identifier != null) {
        result = RecentFile(
          identifier,
          source.name,
          DateTime.now(),
        );
      } else {
        debugPrint("Couldn't obtain persistent access to ${source.name}");
      }
    }
  }
  return result;
}

Future<void> _loadAndRememberFile(
  BuildContext context,
  FutureOr<NativeDataSource?> fileInfoFuture,
) async {
  final recentFile = await _loadFile(context, fileInfoFuture);
  if (recentFile != null) {
    RecentFiles.of(context).add(recentFile);
    debugPrint('Saving file ID to state');
    RestorationScope.of(context)?.write<String>(
      _kRestoreOpenFileIdKey,
      recentFile.identifier,
    );
  }
}

class _PickFileButton extends StatelessWidget {
  const _PickFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).accentColor,
        onPrimary: Theme.of(context).accentTextTheme.button?.color,
      ),
      onPressed: () => _loadAndRememberFile(context, pickFile()),
      child: const Text('Open File'),
    );
  }
}

class _OrgManualButton extends StatelessWidget {
  const _OrgManualButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).buttonColor,
        onPrimary: DefaultTextStyle.of(context).style.color,
      ),
      onPressed: () => loadHttpUrl(
        context,
        Uri.parse(
          'https://code.orgmode.org/bzg/org-mode/raw/master/doc/org-manual.org',
        ),
      ),
      child: const Text('Open Org Manual'),
    );
  }
}

class _OrgroManualButton extends StatelessWidget {
  const _OrgroManualButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).buttonColor,
        onPrimary: DefaultTextStyle.of(context).style.color,
      ),
      onPressed: () => _openOrgroManual(context),
      child: const Text('Open Orgro Manual'),
    );
  }
}

void _openOrgroManual(BuildContext context) =>
    loadAsset(context, 'assets/orgro-manual.org');

class _SupportLink extends StatelessWidget {
  const _SupportLink({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.help),
      label: const Text('Support · Feedback'),
      onPressed: _visitSupportLink,
      style: TextButton.styleFrom(primary: Theme.of(context).disabledColor),
    );
  }
}

void _visitSupportLink() => launch(
      'https://github.com/amake/orgro/issues',
      forceSafariVC: false,
    );

class _LicensesButton extends StatelessWidget {
  const _LicensesButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _openLicensePage(context),
      style: TextButton.styleFrom(primary: Theme.of(context).disabledColor),
      child: const Text('Licenses'),
    );
  }
}

void _openLicensePage(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const LicensePage(),
      ),
    );
