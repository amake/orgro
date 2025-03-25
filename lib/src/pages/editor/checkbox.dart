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

  var zipper = doc.editNode(node)!;

  if (node is OrgListItem) {
    if (node.checkbox == null) {
      // Add checkbox if it doesn't exist
      final replacement = node.toggleCheckbox(add: true);
      final newDoc = zipper.replace(replacement).commit();
      return (newDoc.toMarkup(), offset + 4);
    } else {
      // Insert new checkbox item below
      final sibling = _newEmptyCheckboxItem(from: node);
      final newDoc = zipper.insertRight(sibling).commit();
      final newText = newDoc.toMarkup();
      final needle = sibling.toMarkup();
      final newOffset = newText.indexOf(needle, offset) + needle.length - 1;
      return (newText, newOffset);
    }
  } else if (node is OrgList) {
    // Insert new checkbox item at the end of the list

    // Go to the end of the list
    zipper = zipper.goDown();
    while (zipper.canGoRight()) {
      zipper = zipper.goRight();
    }
    final lastItem = zipper.node as OrgListItem;
    final sibling = _newEmptyCheckboxItem(from: lastItem);
    final newDoc = zipper.insertRight(sibling).commit();
    final newText = newDoc.toMarkup();
    final needle = sibling.toMarkup();
    final newOffset = newText.indexOf(needle, offset) + needle.length - 1;
    return (newText, newOffset);
  } else if (node is OrgParagraph) {
    // Convert paragraph to checkbox item
    final (leading, body, trailing) =
        node.toMarkup().splitSurroundingWhitespace();
    final item = OrgListUnorderedItem(
      leading,
      '- ',
      '[ ]',
      null,
      OrgContent([OrgPlainText(body)]),
    );
    final replacement = OrgList([item], trailing);
    final newDoc = zipper.replace(replacement).commit();
    final newText = newDoc.toMarkup();
    final newOffset = newText.indexOf(body) + body.length;
    return (newText, newOffset);
  }

  return null;
}

(String, int)? insertCheckboxOverRange(String text, int start, int end) {
  final rangeText = text.substring(start, end);
  final lines = rangeText.split('\n');
  final transformedLines = <String>[];

  for (final line in lines) {
    final info = _ListItemInfo.parse(line);
    final indentation = info.indentation;
    if (info.marker != null && info.checkbox == null) {
      final marker = info.marker!; // Promote marker to String
      // Add checkbox to list items without one
      final newContent = '$indentation$marker [ ] ${info.content.trim()}';
      transformedLines.add(newContent);
    } else if (info.marker == null) {
      // Convert non-list items to list items with checkbox
      final newContent = '$indentation- [ ] ${info.content.trim()}';
      transformedLines.add(newContent);
    } else {
      // Leave lines with existing checkboxes unchanged
      transformedLines.add(line);
    }
  }

  // Join transformed lines and replace the selected range
  final transformedText = transformedLines.join('\n');
  final newText = text.replaceRange(start, end, transformedText);
  final newOffset = start + transformedText.length;
  return (newText, newOffset);
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

// Helper class to hold list item information
class _ListItemInfo {
  // Parse a line into its list item components
  factory _ListItemInfo.parse(String line) {
    final match = _listPattern.firstMatch(line);
    if (match != null) {
      final indentation = match.group(1)!;
      final marker = match.group(2);
      final checkbox = match.group(3);
      final content = match.group(4)!;
      return _ListItemInfo(indentation, marker, checkbox, content);
    }
    return _ListItemInfo('', null, null, line);
  }

  final String indentation;
  final String? marker; // e.g., "-", "+", "*", "1.", "1)"
  final String? checkbox; // "[ ]" or "[X]"
  final String content;

  String get markerOrDefault => marker ?? '-';

  _ListItemInfo(this.indentation, this.marker, this.checkbox, this.content);
}

final _listPattern = RegExp(r'^(\s*)([-\+\*]|\d+[\.\)])?\s*(\[.\])?\s*(.*)$');

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
