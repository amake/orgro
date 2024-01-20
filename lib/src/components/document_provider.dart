import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/preferences.dart';

const _kMaxUndoStackSize = 10;

class DocumentProvider extends StatefulWidget {
  static InheritedDocumentProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDocumentProvider>()!;

  const DocumentProvider({
    required this.doc,
    required this.dataSource,
    required this.child,
    this.onDocChanged,
    super.key,
  });

  final OrgTree doc;
  final DataSource dataSource;
  final Widget child;
  final void Function(OrgTree)? onDocChanged;

  @override
  State<DocumentProvider> createState() => _DocumentProviderState();
}

class _DocumentProviderState extends State<DocumentProvider> {
  List<OrgTree> _docs = [];
  List<DocumentAnalysis> _analyses = [];
  late DataSource _dataSource;
  List<String> _accessibleDirs = [];
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _docs = [widget.doc];
    _analyses = [const DocumentAnalysis()];
    _analyze(widget.doc).then((analysis) {
      setState(() => _analyses[0] = analysis);
    });
    _dataSource = widget.dataSource;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accessibleDirs = Preferences.of(context).accessibleDirs;
    _resolveDataSourceParent(_accessibleDirs).then((dataSource) {
      if (dataSource != null) {
        setState(() => _dataSource = dataSource);
      }
    });
  }

  Future<DataSource?> _resolveDataSourceParent(
      List<String> accessibleDirs) async {
    final dataSource = _dataSource;
    if (dataSource is NativeDataSource && dataSource.needsToResolveParent) {
      return dataSource.resolveParent(accessibleDirs);
    }
    return null;
  }

  Future<void> _addAccessibleDir(String dir) async {
    final accessibleDirs = _accessibleDirs..add(dir);
    await Preferences.of(context).setAccessibleDirs(accessibleDirs);
    final dataSource = await _resolveDataSourceParent(accessibleDirs);
    setState(() {
      if (dataSource != null) {
        _dataSource = dataSource;
      }
      _accessibleDirs = accessibleDirs;
    });
  }

  Future<bool> _pushDoc(OrgTree doc) async {
    if (doc == _docs[_cursor]) return false;

    widget.onDocChanged?.call(doc);
    final analysis = await _analyze(doc);
    setState(() {
      _docs = _pushAtIndexAndTrim(_docs, doc, _cursor, _kMaxUndoStackSize);
      _analyses =
          _pushAtIndexAndTrim(_analyses, analysis, _cursor, _kMaxUndoStackSize);
      _cursor = _docs.length - 1;
    });
    return true;
  }

  static List<T> _pushAtIndexAndTrim<T>(
    List<T> list,
    T item,
    int idx,
    int maxLen,
  ) =>
      [
        // +2 is because we keep the item at idx and the new item, so the total
        // will be maxLen
        ...list.sublist(max(0, idx - maxLen + 2), idx + 1), item,
      ];

  bool get _canUndo => _cursor >= 1;

  OrgTree _undo() {
    if (!_canUndo) throw Exception("can't undo");
    final newCursor = _cursor - 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return newDoc;
  }

  bool get _canRedo => _cursor < _docs.length - 1;

  OrgTree _redo() {
    if (!_canRedo) throw Exception("can't redo");
    final newCursor = _cursor + 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return newDoc;
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDocumentProvider(
      doc: _docs[_cursor],
      dataSource: _dataSource,
      analysis: _analyses[_cursor],
      addAccessibleDir: _addAccessibleDir,
      pushDoc: _pushDoc,
      undo: _undo,
      redo: _redo,
      canUndo: _canUndo,
      canRedo: _canRedo,
      child: widget.child,
    );
  }
}

class InheritedDocumentProvider extends InheritedWidget {
  const InheritedDocumentProvider({
    required this.doc,
    required this.dataSource,
    required this.analysis,
    required this.addAccessibleDir,
    required this.pushDoc,
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
    required super.child,
    super.key,
  });

  final OrgTree doc;
  final DataSource dataSource;
  final DocumentAnalysis analysis;
  final Future<void> Function(String) addAccessibleDir;
  final Future<bool> Function(OrgTree) pushDoc;
  final OrgTree Function() undo;
  final OrgTree Function() redo;
  final bool canUndo;
  final bool canRedo;

  @override
  bool updateShouldNotify(InheritedDocumentProvider oldWidget) =>
      doc != oldWidget.doc ||
      dataSource != oldWidget.dataSource ||
      analysis != oldWidget.analysis;
}

Future<DocumentAnalysis> _analyze(OrgTree doc) => time('analyze', () async {
      final canResolveRelativeLinks =
          await canObtainNativeDirectoryPermissions();
      var hasRemoteImages = false;
      var hasRelativeLinks = false;
      var hasEncryptedContent = false;
      doc.visit<OrgLeafNode>((node) {
        if (node is OrgLink) {
          hasRemoteImages |=
              looksLikeImagePath(node.location) && looksLikeUrl(node.location);
          try {
            hasRelativeLinks |= OrgFileLink.parse(node.location).isRelative;
          } on Exception {
            // Not a file link
          }
          return !hasRemoteImages ||
              (!hasRelativeLinks && canResolveRelativeLinks) ||
              !hasEncryptedContent;
        } else if (node is OrgPgpBlock) {
          hasEncryptedContent = true;
          return !hasRemoteImages ||
              (!hasRelativeLinks && canResolveRelativeLinks);
        }
        return true;
      });

      final keywords = <String>{};
      final tags = <String>{};
      final priorities = <String>{};
      doc.visitSections((section) {
        final keyword = section.headline.keyword?.value;
        if (keyword != null) {
          keywords.add(keyword);
        }
        final sectionTags = section.headline.tags;
        if (sectionTags != null) {
          tags.addAll(sectionTags.values);
        }
        final priority = section.headline.priority?.value;
        if (priority != null) {
          priorities.add(priority);
        }
        return true;
      });

      return DocumentAnalysis(
        hasRemoteImages: hasRemoteImages,
        hasRelativeLinks: hasRelativeLinks,
        hasEncryptedContent: hasEncryptedContent,
        keywords: keywords.toList(growable: false),
        tags: tags.toList(growable: false),
        priorities: priorities.toList(growable: false),
      );
    });

class DocumentAnalysis {
  const DocumentAnalysis({
    this.hasRemoteImages,
    this.hasRelativeLinks,
    this.hasEncryptedContent,
    this.keywords,
    this.tags,
    this.priorities,
  });

  final bool? hasRemoteImages;
  final bool? hasRelativeLinks;
  final bool? hasEncryptedContent;
  final List<String>? keywords;
  final List<String>? tags;
  final List<String>? priorities;

  @override
  bool operator ==(Object other) =>
      other is DocumentAnalysis &&
      hasRemoteImages == other.hasRemoteImages &&
      hasRelativeLinks == other.hasRelativeLinks &&
      hasEncryptedContent == other.hasEncryptedContent &&
      listEquals(keywords, other.keywords) &&
      listEquals(tags, other.tags) &&
      listEquals(priorities, other.priorities);

  @override
  int get hashCode => Object.hash(
        hasRemoteImages,
        hasRelativeLinks,
        hasEncryptedContent,
        keywords == null ? null : Object.hashAll(keywords!),
        tags == null ? null : Object.hashAll(tags!),
        priorities == null ? null : Object.hashAll(priorities!),
      );
}
