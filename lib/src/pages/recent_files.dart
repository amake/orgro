import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/preferences.dart';
import 'package:orgro/src/util.dart';

class RecentFile {
  RecentFile.fromJson(Map<String, dynamic> json)
      : this(
          json['identifier'] as String,
          json['name'] as String,
          DateTime.fromMillisecondsSinceEpoch(json['lastOpened'] as int),
        );

  RecentFile(this.identifier, this.name, this.lastOpened);
  final String identifier;
  final String name;
  final DateTime lastOpened;

  @override
  bool operator ==(Object other) =>
      other is RecentFile &&
      identifier == other.identifier &&
      name == other.name &&
      lastOpened == other.lastOpened;

  @override
  int get hashCode => hashValues(identifier, name, lastOpened);

  Map<String, Object> toJson() => {
        'identifier': identifier,
        'name': name,
        'lastOpened': lastOpened.millisecondsSinceEpoch,
      };

  @override
  String toString() => 'RecentFile[$name:$_debugShortIdentifier]';

  String get _debugShortIdentifier {
    final length = identifier.length;
    if (length > 20) {
      final front = identifier.substring(0, 10);
      final back = identifier.substring(length - 10);
      return '$front...$back';
    } else {
      return identifier;
    }
  }
}

class RecentFiles extends InheritedWidget {
  const RecentFiles(
    this.list, {
    required this.add,
    required this.remove,
    required Widget child,
    Key? key,
  }) : super(child: child, key: key);

  final List<RecentFile> list;
  final ValueChanged<RecentFile> add;
  final ValueChanged<RecentFile> remove;

  @override
  bool updateShouldNotify(RecentFiles oldWidget) =>
      !listEquals(list, oldWidget.list) ||
      add != oldWidget.add ||
      remove != oldWidget.remove;

  static RecentFiles of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecentFiles>()!;
}

mixin RecentFilesState<T extends StatefulWidget> on State<T> {
  Preferences get _prefs => Preferences.of(context);
  late List<RecentFile> _recentFiles;
  _LifecycleEventHandler? _lifecycleEventHandler;

  bool get hasRecentFiles => _recentFiles.isNotEmpty;

  void addRecentFile(RecentFile newFile) {
    debugPrint('Adding recent file: $newFile');
    final newFiles = [newFile]
        .followedBy(_recentFiles)
        .take(kMaxRecentFiles)
        .unique(
          cache: LinkedHashSet(
            equals: (a, b) => a.identifier == b.identifier,
            hashCode: (o) => o.identifier.hashCode,
          ),
        )
        .toList(growable: false);
    _save(newFiles);
  }

  void removeRecentFile(RecentFile recentFile) {
    debugPrint('Removing recent file: $recentFile');
    final newFiles = List.of(_recentFiles)..remove(recentFile);
    _save(newFiles);
  }

  void _save(List<RecentFile> files) {
    setState(() {
      _recentFiles = files;
    });
    _prefs.setRecentFilesJson(files
        .map((file) => file.toJson())
        .map(json.encode)
        .toList(growable: false));
  }

  @override
  void initState() {
    super.initState();
    _lifecycleEventHandler ??= _LifecycleEventHandler(onResume: _reload);
    WidgetsBinding.instance?.addObserver(_lifecycleEventHandler!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(_lifecycleEventHandler!);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Doing this here instead of [initState] because we need to pull in an
    // InheritedWidget
    _load();
  }

  void _load() {
    _recentFiles = _prefs.recentFilesJson
        .map<dynamic>(json.decode)
        .cast<Map<String, dynamic>>()
        .map((json) => RecentFile.fromJson(json))
        .toList(growable: false);
  }

  Future<void> _reload() async {
    debugPrint('Reloading recent files');
    await _prefs.reload();
    setState(_load);
  }

  Widget buildWithRecentFiles({required WidgetBuilder builder}) {
    return RecentFiles(
      _recentFiles,
      add: addRecentFile,
      remove: removeRecentFile,
      // Builder required to get RecentFiles into context
      child: Builder(builder: builder),
    );
  }
}

class _LifecycleEventHandler extends WidgetsBindingObserver {
  _LifecycleEventHandler({this.onResume});

  final VoidCallback? onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        onResume?.call();
        break;
      default:
      // Nothing
    }
  }
}
