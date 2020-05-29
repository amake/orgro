import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/recent_files.dart';
import 'package:url_launcher/url_launcher.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with RecentFilesState, PlatformOpenHandler {
  @override
  Widget build(BuildContext context) => buildWithRecentFiles(
        whenEmpty: const _EmptyStartPage(),
        whenNotEmpty: const _RecentFilesStartPage(),
      );

  @override
  Future<bool> loadFileFromPlatform(OpenFileInfo info) async {
    final recentFile = await _loadFile(context, info);
    if (recentFile != null) {
      addRecentFile(recentFile);
      return true;
    } else {
      return false;
    }
  }
}

class _EmptyStartPage extends StatelessWidget {
  const _EmptyStartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orgro')),
      body: Center(
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
      ),
    );
  }
}

class _RecentFilesStartPage extends StatelessWidget {
  const _RecentFilesStartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recentFiles = RecentFiles.of(context).list;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orgro · Recent files'),
        actions: [
          PopupMenuButton<VoidCallback>(
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
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: recentFiles.length,
        itemBuilder: (context, idx) => _RecentFileListTile(recentFiles[idx]),
        separatorBuilder: (context, idx) => const Divider(),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _loadAndRememberFile(context, pickFile()),
        foregroundColor: Theme.of(context).accentTextTheme.button.color,
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
    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(recentFile.name),
      subtitle: Text(_kLastOpenedFormat.format(recentFile.lastOpened)),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => RecentFiles.of(context).remove(recentFile),
      ),
      onTap: () async => _loadAndRememberFile(
        context,
        readFileWithIdentifier(recentFile.identifier),
      ),
    );
  }
}

Future<RecentFile> _loadFile(
  BuildContext context,
  FutureOr<OpenFileInfo> fileInfoFuture,
) async {
  final loaded = await loadDocument(context, fileInfoFuture);
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
