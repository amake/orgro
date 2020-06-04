import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:native_state/native_state.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/recent_files.dart';
import 'package:url_launcher/url_launcher.dart';

const _kRestoreOpenFileIdKey = 'restore_open_file_id';

class StartPage extends StatefulWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with RecentFilesState, PlatformOpenHandler, StateRestoration {
  @override
  Widget build(BuildContext context) =>
      buildWithRecentFiles(builder: (context) {
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
          floatingActionButton: _buildFloatingActionButton(),
        );
      });

  Iterable<Widget> _buildActions() sync* {
    if (!hasRecentFiles) {
      return;
    }
    yield PopupMenuButton<VoidCallback>(
      onSelected: (callback) => callback(),
      itemBuilder: (context) => [
        PopupMenuItem<VoidCallback>(
          child: const Text('Orgro Manual'),
          value: () => _openOrgroManual(context),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<VoidCallback>(
          child: Text('Support · Feedback'),
          value: _visitSupportLink,
        ),
        PopupMenuItem<VoidCallback>(
          child: const Text('Licenses'),
          value: () => _openLicensePage(context),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (!hasRecentFiles) {
      return null;
    }
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => _loadAndRememberFile(context, pickFile()),
      foregroundColor: Theme.of(context).accentTextTheme.button.color,
    );
  }

  @override
  Future<bool> loadFileFromPlatform(OpenFileInfo info) async {
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
  void restoreState(SavedStateData savedState) {
    final restoreId = savedState.getString(_kRestoreOpenFileIdKey);
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

  void _rememberFile(RecentFile recentFile) {
    addRecentFile(recentFile);
    debugPrint('Saving file ID to state');
    SavedState.of(context)
        .putString(_kRestoreOpenFileIdKey, recentFile.identifier);
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
            const _LicensesButton(),
          ],
        ),
      ),
    );
  }
}

class _RecentFilesBody extends StatelessWidget {
  const _RecentFilesBody({Key key}) : super(key: key);

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
              return const _ListHeader(child: Text('Recent files'));
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
  const _ListHeader({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  final Widget child;

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
        child: child,
      ),
    );
  }
}

final _kLastOpenedFormat = DateFormat.yMd().add_jm();

class _RecentFileListTile extends StatelessWidget {
  const _RecentFileListTile(this.recentFile, {Key key})
      : assert(recentFile != null),
        super(key: key);

  final RecentFile recentFile;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(recentFile),
      onDismissed: (_) => RecentFiles.of(context).remove(recentFile),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.all(24),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).accentTextTheme.button.color,
        ),
      ),
      direction: DismissDirection.endToStart,
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

Future<RecentFile> _loadFile(
  BuildContext context,
  FutureOr<OpenFileInfo> fileInfoFuture,
) async {
  final loaded = await loadDocument(
    context,
    fileInfoFuture,
    onClose: () {
      debugPrint('Clearing saved state');
      SavedState.of(context).remove(_kRestoreOpenFileIdKey);
    },
  );
  RecentFile result;
  if (loaded) {
    final fileInfo = await fileInfoFuture;
    if (fileInfo.identifier != null) {
      result = RecentFile(fileInfo.identifier, fileInfo.title, DateTime.now());
    } else {
      debugPrint("Couldn't obtain persistent access to ${fileInfo.title}");
    }
  }
  return result;
}

Future<void> _loadAndRememberFile(
  BuildContext context,
  FutureOr<OpenFileInfo> fileInfoFuture,
) async {
  final recentFile = await _loadFile(context, fileInfoFuture);
  RecentFiles.of(context).add(recentFile);
  debugPrint('Saving file ID to state');
  await SavedState.of(context)
      .putString(_kRestoreOpenFileIdKey, recentFile.identifier);
}

class _PickFileButton extends StatelessWidget {
  const _PickFileButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open File'),
      color: Theme.of(context).accentColor,
      textColor: Theme.of(context).accentTextTheme.button.color,
      onPressed: () => _loadAndRememberFile(context, pickFile()),
    );
  }
}

class _OrgManualButton extends StatelessWidget {
  const _OrgManualButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open Org Manual'),
      onPressed: () => loadHttpUrl(context,
          'https://code.orgmode.org/bzg/org-mode/raw/master/doc/org-manual.org'),
    );
  }
}

class _OrgroManualButton extends StatelessWidget {
  const _OrgroManualButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open Orgro Manual'),
      onPressed: () => _openOrgroManual(context),
    );
  }
}

void _openOrgroManual(BuildContext context) =>
    loadAsset(context, 'assets/orgro-manual.org');

class _SupportLink extends StatelessWidget {
  const _SupportLink({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      icon: const Icon(Icons.help),
      label: const Text('Support · Feedback'),
      onPressed: _visitSupportLink,
      textColor: Theme.of(context).disabledColor,
    );
  }
}

void _visitSupportLink() => launch(
      'https://github.com/amake/orgro/issues',
      forceSafariVC: false,
    );

class _LicensesButton extends StatelessWidget {
  const _LicensesButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: const Text('Licenses'),
      onPressed: () => _openLicensePage(context),
      textColor: Theme.of(context).disabledColor,
    );
  }
}

void _openLicensePage(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const LicensePage(),
      ),
    );
