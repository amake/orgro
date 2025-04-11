import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/util.dart';
import 'package:orgro/src/util.dart';

(String, int)? insertCheckboxAtPoint(String text, int offset) {
  final doc = OrgDocument.parse(text);
  final found = doc
      .nodesAtOffset(offset)
      .map((result) => result.node)
      .toList(growable: false);
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
  // In a multi-edit scenario, the original item might have been replaced (e.g.
  // if a sub-item has been edited) so we also look up by ID.
  final zipper = doc.edit().findWhere(
    (n) => identical(n, item) || (n is OrgListItem && n.id == item.id),
  );
  if (zipper == null) return (doc, null);
  // If the original item was replaced, then we need to use the current item.
  item = zipper.node as OrgListItem;

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
    (e) => e.node is OrgListItem || e.node is OrgList || e.node is OrgParagraph,
  );

  final region = Region(start, end);
  OrgNode? lastModifiedNode;

  for (final (:node, :span) in nodes) {
    final (newDoc, modifiedNode) = switch (node) {
      // Skip OrgListItem with checkbox because somehow in the case of a range,
      // it feels like we should only be modifying existing objects, not adding
      // new ones
      OrgListItem(checkbox: null) => _checkboxifyListItem(node, doc),
      // Skip OrgList because:
      // - The boundaries of a list are a bit unintuitive due to trailing blank
      //   lines
      // - Same as the checkbox list item case, with a range it feels like we
      //   should only be modifying existing objects.
      //
      // OrgList() => _checkboxifyList(node, doc),
      OrgParagraph() => _checkboxifyParagraph(node, doc),
      _ => (doc, null),
    };
    doc = newDoc;
    if (modifiedNode != null) {
      lastModifiedNode = modifiedNode;
      region.consume(span.start, span.end);
      if (region.isEmpty) break;
    }
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
