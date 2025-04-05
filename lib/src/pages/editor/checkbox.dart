import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/util.dart';
import 'package:orgro/src/util.dart';

(String, int)? insertCheckboxAtPoint(String text, int offset) {
  final doc = OrgDocument.parse(text);
  final found = doc.nodesAtOffset(offset);
  final node =
      found.whereType<OrgListItem>().firstOrNull ??
      found.whereType<OrgList>().firstOrNull ??
      found.whereType<OrgParagraph>().firstOrNull;
  if (node == null) return null;

  late OrgTree newDoc;
  OrgNode? modifiedNode;
  if (node is OrgListItem) {
    (newDoc, modifiedNode) = _checkboxifyListItem(node, doc);
  } else if (node is OrgList) {
    (newDoc, modifiedNode) = _checkboxifyList(node, doc);
  } else if (node is OrgParagraph) {
    (newDoc, modifiedNode) = _checkboxifyParagraph(node, doc);
  }

  if (modifiedNode == null) throw Error();

  final (newText, _, end) = newDoc.toMarkupLocating(modifiedNode);
  if (end == -1) throw Error();

  var newOffset = end;
  while (newText.codeUnitAt(newOffset - 1) == 0x0A) {
    newOffset--;
  }
  return (newText, newOffset);
}

(OrgTree, OrgNode?) _checkboxifyListItem(OrgListItem item, OrgTree doc) {
  final zipper = doc.editNode(item);
  if (zipper == null) return (doc, null);

  if (item.checkbox == null) {
    // Add checkbox if it doesn't exist
    final replacement = item.toggleCheckbox(add: true);
    final newDoc = zipper.replace(replacement).commit() as OrgTree;
    return (newDoc, replacement);
  }

  // Insert new checkbox item below
  final sibling = _newEmptyCheckboxItem(from: item);
  final newDoc = zipper.insertRight(sibling).commit() as OrgTree;
  return (newDoc, sibling);
}

(OrgTree, OrgNode?) _checkboxifyList(OrgList list, OrgTree doc) {
  var zipper = doc.editNode(list);
  if (zipper == null) return (doc, null);

  // Insert new checkbox item at the end of the list

  // Go to the end of the list
  zipper = zipper.goDown();
  while (zipper!.canGoRight()) {
    zipper = zipper.goRight();
  }
  final lastItem = zipper.node as OrgListItem;
  final sibling = _newEmptyCheckboxItem(from: lastItem);
  final newDoc = zipper.insertRight(sibling).commit() as OrgTree;
  return (newDoc, sibling);
}

(OrgTree, OrgNode?) _checkboxifyParagraph(OrgParagraph paragraph, OrgTree doc) {
  final zipper = doc.editNode(paragraph);
  if (zipper == null) return (doc, null);

  // Convert paragraph to checkbox item
  final (leading, body, trailing) =
      paragraph.toMarkup().splitSurroundingWhitespace();
  final item = OrgListUnorderedItem(
    leading,
    '- ',
    '[ ]',
    null,
    OrgContent([OrgPlainText(body)]),
  );
  final replacement = OrgList([item], trailing);
  final newDoc = zipper.replace(replacement).commit() as OrgTree;
  return (newDoc, replacement);
}

(String, int)? insertCheckboxOverRange(String text, int start, int end) {
  OrgTree doc = OrgDocument.parse(text);
  final found = doc.nodesInRange(start, end);
  final nodes = found.where(
    (node) => node is OrgListItem || node is OrgList || node is OrgParagraph,
  );

  OrgNode? lastModifiedNode;

  for (final node in nodes) {
    final (newDoc, modifiedNode) = switch (node) {
      OrgListItem() => _checkboxifyListItem(node, doc),
      OrgList() => _checkboxifyList(node, doc),
      OrgParagraph() => _checkboxifyParagraph(node, doc),
      _ => (doc, null),
    };
    doc = newDoc;
    lastModifiedNode = modifiedNode ?? lastModifiedNode;
  }

  if (lastModifiedNode == null) return null;

  final (newText, _, modifiedEnd) = doc.toMarkupLocating(lastModifiedNode);
  return (newText, modifiedEnd);
}

OrgListItem _newEmptyCheckboxItem({required OrgListItem from}) {
  final body = OrgContent([OrgPlainText('\n')]);
  return switch (from) {
    OrgListOrderedItem() => OrgListOrderedItem(
      from.indent,
      _getNextMarker(from.bullet),
      null,
      '[ ]',
      body,
    ),
    OrgListUnorderedItem() => OrgListUnorderedItem(
      from.indent,
      from.bullet,
      '[ ]',
      null,
      body,
    ),
  };
}

final _numPattern = RegExp(r'(\d+)(.*)');

// Generate the next marker for ordered lists
String _getNextMarker(String? marker) {
  if (marker == null) return '-';
  final match = _numPattern.firstMatch(marker);
  if (match != null) {
    final num = int.parse(match.group(1)!);
    final suffix = match.group(2)!;
    return '${num + 1}$suffix';
  }
  return marker; // Return same marker for unordered lists
}
