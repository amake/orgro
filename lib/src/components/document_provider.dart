import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/encryption.dart';
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
  List<OrgroPassword> _passwords = [];
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
    final accessibleDirs =
        Preferences.of(context, PrefsAspect.accessibleDirs).accessibleDirs;
    _resolveDataSourceParent(accessibleDirs).then((dataSource) {
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

  Future<(bool, DocumentAnalysis)> _pushDoc(OrgTree doc) async {
    if (doc == _docs[_cursor]) return (false, _analyses[_cursor]);

    widget.onDocChanged?.call(doc);
    final analysis = await _analyze(doc);
    setState(() {
      _docs = _pushAtIndexAndTrim(_docs, doc, _cursor, _kMaxUndoStackSize);
      _analyses =
          _pushAtIndexAndTrim(_analyses, analysis, _cursor, _kMaxUndoStackSize);
      _cursor = _docs.length - 1;
    });
    return (true, analysis);
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

  List<OrgroPassword> _addPasswords(Iterable<OrgroPassword> passwords) {
    final newPasswords = [..._passwords, ...passwords];
    setState(() => _passwords = newPasswords);
    return newPasswords;
  }

  bool get _canUndo => _cursor >= 1;

  (OrgTree, DocumentAnalysis) _undo() {
    if (!_canUndo) throw Exception("can't undo");
    final newCursor = _cursor - 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return (newDoc, _analyses[newCursor]);
  }

  bool get _canRedo => _cursor < _docs.length - 1;

  (OrgTree, DocumentAnalysis) _redo() {
    if (!_canRedo) throw Exception("can't redo");
    final newCursor = _cursor + 1;
    setState(() => _cursor = newCursor);
    final newDoc = _docs[newCursor];
    widget.onDocChanged?.call(newDoc);
    return (newDoc, _analyses[newCursor]);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDocumentProvider(
      doc: _docs[_cursor],
      dataSource: _dataSource,
      analysis: _analyses[_cursor],
      pushDoc: _pushDoc,
      passwords: List.unmodifiable(_passwords),
      addPasswords: _addPasswords,
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
    required this.pushDoc,
    required this.passwords,
    required this.addPasswords,
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
  final Future<(bool, DocumentAnalysis)> Function(OrgTree) pushDoc;
  final List<OrgroPassword> passwords;
  final List<OrgroPassword> Function(Iterable<OrgroPassword>) addPasswords;
  final (OrgTree, DocumentAnalysis) Function() undo;
  final (OrgTree, DocumentAnalysis) Function() redo;
  final bool canUndo;
  final bool canRedo;

  @override
  bool updateShouldNotify(InheritedDocumentProvider oldWidget) =>
      doc != oldWidget.doc ||
      dataSource != oldWidget.dataSource ||
      analysis != oldWidget.analysis;
}

Future<DocumentAnalysis> _analyze(OrgTree doc) => time(
      'analyze',
      () async => DocumentAnalysis.of(doc,
          canResolveRelativeLinks: await canObtainNativeDirectoryPermissions()),
    );

class DocumentAnalysis {
  factory DocumentAnalysis.of(
    OrgTree doc, {
    required bool canResolveRelativeLinks,
  }) {
    var hasRemoteImages = false;
    var hasRelativeLinks = false;
    var hasEncryptedContent = false;
    doc.visit<OrgNode>((node) {
      if (node is OrgLink) {
        hasRemoteImages |=
            looksLikeImagePath(node.location) && looksLikeUrl(node.location);
        try {
          hasRelativeLinks |= OrgFileLink.parse(node.location).isRelative;
        } on Exception {
          // Not a file link
        }
      } else if (node is OrgPgpBlock) {
        hasEncryptedContent = true;
      }
      return !hasRemoteImages ||
          (!hasRelativeLinks && canResolveRelativeLinks) ||
          !hasEncryptedContent;
    });

    final keywords = <String>{};
    final tags = <String>{};
    final priorities = <String>{};
    var needsEncryption = doc.find<OrgDecryptedContent>((_) => true) != null;
    doc.visitSections((section) {
      needsEncryption |= section.needsEncryption();
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
      needsEncryption: needsEncryption,
      keywords: keywords.toList(growable: false),
      tags: tags.toList(growable: false),
      priorities: priorities.toList(growable: false),
    );
  }

  const DocumentAnalysis({
    this.hasRemoteImages,
    this.hasRelativeLinks,
    this.hasEncryptedContent,
    this.needsEncryption,
    this.keywords,
    this.tags,
    this.priorities,
  });

  final bool? hasRemoteImages;
  final bool? hasRelativeLinks;
  final bool? hasEncryptedContent;
  final bool? needsEncryption;
  final List<String>? keywords;
  final List<String>? tags;
  final List<String>? priorities;

  @override
  bool operator ==(Object other) =>
      other is DocumentAnalysis &&
      hasRemoteImages == other.hasRemoteImages &&
      hasRelativeLinks == other.hasRelativeLinks &&
      hasEncryptedContent == other.hasEncryptedContent &&
      needsEncryption == other.needsEncryption &&
      listEquals(keywords, other.keywords) &&
      listEquals(tags, other.tags) &&
      listEquals(priorities, other.priorities);

  @override
  int get hashCode => Object.hash(
        hasRemoteImages,
        hasRelativeLinks,
        hasEncryptedContent,
        needsEncryption,
        keywords == null ? null : Object.hashAll(keywords!),
        tags == null ? null : Object.hashAll(tags!),
        priorities == null ? null : Object.hashAll(priorities!),
      );
}
