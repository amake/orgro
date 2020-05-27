import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class RecentFile {
  RecentFile(this.identifier, this.name)
      : assert(identifier != null),
        assert(name != null);
  final String identifier;
  final String name;

  @override
  bool operator ==(Object o) =>
      o is RecentFile && identifier == o.identifier && name == o.name;

  @override
  int get hashCode => hashValues(identifier, name);
}

class RecentFiles extends InheritedWidget {
  const RecentFiles(
    this.list,
    this.add, {
    @required Widget child,
    Key key,
  })  : assert(list != null),
        assert(add != null),
        super(child: child, key: key);

  final List<RecentFile> list;
  final ValueChanged<RecentFile> add;

  @override
  bool updateShouldNotify(RecentFiles oldWidget) =>
      !listEquals(list, oldWidget.list) || add != oldWidget.add;

  static RecentFiles of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecentFiles>();
}

mixin RecentFilesState<T extends StatefulWidget> on State<T> {
  Preferences get _prefs => Preferences.of(context);
  List<RecentFile> _recentFiles;

  void add(RecentFile newFile) {
    final newFiles = [newFile]
        .followedBy(_recentFiles)
        .take(kMaxRecentFiles)
        .unique()
        .toList(growable: false);
    setState(() {
      _recentFiles = newFiles;
    });
    _prefs
      ..recentFileIds =
          newFiles.map((file) => file.identifier).toList(growable: false)
      ..recentFileNames =
          newFiles.map((file) => file.name).toList(growable: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Doing this here instead of [initState] because we need to pull in an
    // InheritedWidget
    _recentFiles = _prefs.recentFileIds
        .zipMap<RecentFile, String>(
          _prefs.recentFileNames,
          (id, name) => RecentFile(id, name),
        )
        .toList(growable: false);
  }

  Widget buildWithRecentFiles({
    @required Widget whenEmpty,
    @required Widget whenNotEmpty,
  }) {
    return RecentFiles(
      _recentFiles,
      add,
      child: _recentFiles.isEmpty ? whenEmpty : whenNotEmpty,
    );
  }
}
