import 'package:file_picker_writable/file_picker_writable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/pages/recent_files.dart';
import 'package:orgro/src/platform.dart';
import 'package:url_launcher/url_launcher.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with RecentFilesState {
  @override
  Widget build(BuildContext context) => buildWithRecentFiles(
        whenEmpty: const _EmptyStartPage(),
        whenNotEmpty: const _RecentFilesStartPage(),
      );
}

class _EmptyStartPage extends StatelessWidget {
  const _EmptyStartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orgro')),
      body: PlatformOpenHandler(
        child: Center(
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
      appBar: AppBar(title: const Text('Orgro')),
      body: PlatformOpenHandler(
        child: ListView.builder(
          itemCount: recentFiles.length,
          itemBuilder: (context, idx) {
            final recentFile = recentFiles[idx];
            return ListTile(
              title: Text(recentFile.name),
              onTap: () async => _load(
                  context,
                  FilePickerWritable()
                      .readFileWithIdentifier(recentFile.identifier)),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _pickFile(context),
      ),
    );
  }
}

Future<void> _pickFile(BuildContext context) async =>
    _load(context, FilePickerWritable().openFilePicker());

Future<void> _load(
    BuildContext context, Future<FileInfo> fileInfoFuture) async {
  final loaded = await loadInPlaceFile(context, fileInfoFuture);
  if (loaded) {
    final fileInfo = await fileInfoFuture;
    RecentFiles.of(context)
        .add(RecentFile(fileInfo.identifier, fileInfo.fileName));
  }
}

class _PickFileButton extends StatelessWidget {
  const _PickFileButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open File'),
      color: Theme.of(context).accentColor,
      textColor: Theme.of(context).accentTextTheme.button.color,
      onPressed: () => _pickFile(context),
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
      onPressed: () => loadAsset(context, 'assets/orgro-manual.org'),
    );
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton.icon(
      icon: const Icon(Icons.help),
      label: const Text('Support · Feedback'),
      onPressed: () => launch(
        'https://github.com/amake/orgro/issues',
        forceSafariVC: false,
      ),
      textColor: Theme.of(context).disabledColor,
    );
  }
}

class _LicensesButton extends StatelessWidget {
  const _LicensesButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: const Text('Licenses'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const LicensePage(),
        ),
      ),
      textColor: Theme.of(context).disabledColor,
    );
  }
}
