import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/navigation.dart';
import 'package:orgro/src/platform.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orgro')),
      body: PlatformOpenHandler(
        child: Center(
          child: PickFileButton(onSelected: (path) => loadPath(context, path)),
        ),
      ),
    );
  }
}

class PickFileButton extends StatelessWidget {
  const PickFileButton({@required this.onSelected, Key key})
      : assert(onSelected != null),
        super(key: key);

  final Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text('Open File'),
      onPressed: () async {
        final path = await FilePicker.getFilePath(type: FileType.any);
        if (path != null) {
          onSelected(path);
        }
      },
    );
  }
}
