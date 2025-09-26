import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/util.dart';
import 'package:orgro/src/timestamps.dart';

TextEditingValue? _wrapSelection(
  TextEditingValue value,
  String prefix,
  String suffix,
) {
  if (!value.selection.isValid) return null;
  final selection = value.selection.textInside(value.text);
  final replacement = '$prefix$selection$suffix';
  return value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset:
              value.selection.baseOffset + replacement.length - suffix.length,
        ),
      );
}

TextEditingValue? makeBold(TextEditingValue value) =>
    _wrapSelection(value, '*', '*');

TextEditingValue? makeItalic(TextEditingValue value) =>
    _wrapSelection(value, '/', '/');

TextEditingValue? makeUnderline(TextEditingValue value) =>
    _wrapSelection(value, '_', '_');

TextEditingValue? makeStrikethrough(TextEditingValue value) =>
    _wrapSelection(value, '+', '+');

TextEditingValue? makeCode(TextEditingValue value) =>
    _wrapSelection(value, '~', '~');

TextEditingValue? makeSubscript(TextEditingValue value) =>
    _wrapSelection(value, '_{', '}');

TextEditingValue? makeSuperscript(TextEditingValue value) =>
    _wrapSelection(value, '^{', '}');

Future<TextEditingValue?> insertLink(
  TextEditingValue value,
  String? clipboardText,
) async {
  final selection = value.selection.textInside(value.text);
  String? url;
  String? description;
  if ((url = _tryParseUrl(selection)) != null) {
    description = 'description';
  } else {
    url = _tryParseUrl(clipboardText);
    description = selection.isEmpty ? 'description' : selection;
  }
  final replacement = '[[${url ?? 'URL'}][$description]]';
  return value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length - 2,
        ),
      );
}

String? _tryParseUrl(String? str) {
  if (str == null) return null;
  final uri = Uri.tryParse(str);
  // Uri.tryParse is very lenient and will accept lots of things other than what
  // people usually think of as URLs so we filter out anything that doesn't have
  // a scheme.
  return uri?.hasScheme == true ? str : null;
}

Future<TextEditingValue?> insertDate(
  TextEditingValue value,
  DateTime date,
  TimeOfDay? time,
) async {
  if (!value.selection.isValid) return null;
  final replacement = OrgSimpleTimestamp(
    '[',
    date.toOrgDate(),
    time?.toOrgTime(),
    [],
    ']',
  ).toMarkup();
  return value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length - 1,
        ),
      );
}

TextEditingValue? toggleOrderedListItem(TextEditingValue value) {
  if (!value.selection.isValid) return null;

  final doc = OrgDocument.parse(value.text);
  final (:lineStart, :lastEOLIdx, :itemAtPoint) = _itemInfoAtPoint(value, doc);

  switch (itemAtPoint) {
    case null:
      {
        TextEditingValue replaceBOL(String replacement) => value
            .replaced(TextRange.collapsed(lineStart), replacement)
            .copyWith(selection: value.selection.shift(replacement.length));

        // No preceding line, so just insert a list item at the start
        if (lastEOLIdx == -1) return replaceBOL('1. ');

        // No list item at the cursor, but there is a preceding line.
        // If that line is a list item, insert a new one after it.
        final previous =
            doc
                    .nodesAtOffset(lastEOLIdx)
                    .where((e) => e.node is OrgListItem)
                    .firstOrNull
                    ?.node
                as OrgListItem?;

        // List item not found or not ordered, so just insert a new list item at
        // line start
        if (previous is! OrgListOrderedItem) return replaceBOL('1. ');

        final replacement = previous.next().toMarkup();
        return replaceBOL(replacement);
      }
    case OrgListOrderedItem(checkbox: null):
      {
        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Add empty checkbox
        final replacement = OrgListOrderedItem(
          itemAtPoint.indent,
          itemAtPoint.bullet,
          '[ ]',
          null,
          itemAtPoint.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + itemAtPointLength),
              replacement,
            )
            .copyWith(
              selection: value.selection.shift(
                replacement.length - itemAtPointLength,
              ),
            );
      }
    case OrgListOrderedItem():
      {
        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Turn into normal text
        final firstBodyNode = itemAtPoint.body;
        final preambleLength = firstBodyNode == null
            ? itemAtPointLength
            : itemAtPoint.toMarkupLocating(firstBodyNode).start;
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + preambleLength),
              '',
            )
            .copyWith(selection: value.selection.shift(-preambleLength));
      }
    case OrgListUnorderedItem():
      {
        if (itemAtPoint.tag != null) {
          // Ordered list items can't have tags, so avoid destructive change
          return null;
        }

        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Switch type of list
        // TODO(aaron): Should this act on entire list, not just this item?
        final previous =
            doc
                    .nodesAtOffset(lastEOLIdx)
                    .where((e) => e.node is OrgListItem)
                    .firstOrNull
                    ?.node
                as OrgListItem?;
        final replacement = OrgListOrderedItem(
          itemAtPoint.indent,
          previous is OrgListOrderedItem ? previous.nextBullet : '1. ',
          null,
          itemAtPoint.checkbox,
          itemAtPoint.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + itemAtPointLength),
              replacement,
            )
            .copyWith(
              selection: value.selection.shift(
                replacement.length - itemAtPointLength,
              ),
            );
      }
  }
}

TextEditingValue? toggleUnorderedListItem(TextEditingValue value) {
  if (!value.selection.isValid) return null;

  final doc = OrgDocument.parse(value.text);
  final (:lineStart, :lastEOLIdx, :itemAtPoint) = _itemInfoAtPoint(value, doc);

  switch (itemAtPoint) {
    case null:
      {
        TextEditingValue replaceBOL(String replacement) => value
            .replaced(TextRange.collapsed(lineStart), replacement)
            .copyWith(selection: value.selection.shift(replacement.length));

        // No preceding line, so just insert a list item at the start
        if (lastEOLIdx == -1) return replaceBOL('- ');

        // No list item at the cursor, but there is a preceding line.
        // If that line is a list item, insert a new one after it.
        final previous =
            doc
                    .nodesAtOffset(lastEOLIdx)
                    .where((e) => e.node is OrgListItem)
                    .firstOrNull
                    ?.node
                as OrgListItem?;

        // List item not found or not unordered, so just insert a new list item
        // at line start
        if (previous is! OrgListUnorderedItem) return replaceBOL('- ');

        final replacement = previous.next().toMarkup();
        return replaceBOL(replacement);
      }
    case OrgListUnorderedItem(tag: _?):
      {
        // Unordered list items with tags can't be toggled, to avoid destructive
        // change
        return null;
      }
    case OrgListUnorderedItem(checkbox: null):
      {
        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Add empty checkbox
        final replacement = OrgListUnorderedItem(
          itemAtPoint.indent,
          itemAtPoint.bullet,
          '[ ]',
          null,
          itemAtPoint.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + itemAtPointLength),
              replacement,
            )
            .copyWith(
              selection: value.selection.shift(
                replacement.length - itemAtPointLength,
              ),
            );
      }
    case OrgListUnorderedItem():
      {
        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Turn into normal text
        final firstBodyNode = itemAtPoint.tag?.value ?? itemAtPoint.body;
        final preambleLength = firstBodyNode == null
            ? itemAtPointLength
            : itemAtPoint.toMarkupLocating(firstBodyNode).start;
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + preambleLength),
              '',
            )
            .copyWith(selection: value.selection.shift(-preambleLength));
      }
    case OrgListOrderedItem():
      {
        final itemAtPointLength = itemAtPoint.toMarkup().length;

        // Switch type of list
        // TODO(aaron): Should this act on entire list, not just this item?
        final previous =
            doc
                    .nodesAtOffset(lastEOLIdx)
                    .where((e) => e.node is OrgListItem)
                    .firstOrNull
                    ?.node
                as OrgListItem?;
        final replacement = OrgListUnorderedItem(
          itemAtPoint.indent,
          previous is OrgListUnorderedItem ? previous.bullet : '- ',
          itemAtPoint.checkbox,
          null,
          itemAtPoint.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + itemAtPointLength),
              replacement,
            )
            .copyWith(
              selection: value.selection.shift(
                replacement.length - itemAtPointLength,
              ),
            );
      }
  }
}

({int lineStart, int lastEOLIdx, OrgListItem? itemAtPoint}) _itemInfoAtPoint(
  TextEditingValue value,
  OrgDocument doc,
) {
  final lastEOLIdx = value.selection.start == 0
      ? -1
      : value.text.lastIndexOf('\n', value.selection.start - 1);
  final lineStart = lastEOLIdx + 1;

  OrgListItem? foundListItem;
  if (value.selection.start == lineStart) {
    // Org syntax lets list items contain line breaks, so the cursor sitting on
    // the line "after" a list item is still technically in the list item. This is
    // unintuitive when editing raw markup, so we ignore any found item if the
    // cursor is at BOL.
    foundListItem = null;
  } else {
    var searchOffset = value.selection.start;
    // nodesAtOffset excludes the node if the offset is just past it, which is
    // the case if the cursor is at the end of the document.
    if (searchOffset == value.text.length) searchOffset--;
    final foundAtOffset = doc.nodesAtOffset(searchOffset);
    foundListItem =
        foundAtOffset.where((e) => e.node is OrgListItem).firstOrNull?.node
            as OrgListItem?;
  }
  return (
    lineStart: lineStart,
    lastEOLIdx: lastEOLIdx,
    itemAtPoint: foundListItem,
  );
}

TextEditingValue? afterNewLineFixup(TextEditingValue value) {
  if (!value.selection.isValid) return null;
  if (value.selection.start < 2) return null;
  if (!value.text.isEOL(value.selection.start)) return null;
  final lastEOLIdx = value.text.lastIndexOf('\n', value.selection.start - 1);

  final doc = OrgDocument.parse(value.text);
  final atOffset = doc.nodesAtOffset(lastEOLIdx);
  final nodeInfoBeforePoint = atOffset
      .where((e) => e.node is OrgListItem || e.node is OrgHeadline)
      .firstOrNull;
  if (nodeInfoBeforePoint == null) return value;

  final (node: nodeBeforePoint, :span) = nodeInfoBeforePoint;

  // TODO(aaron): This dispatch is ugly. Is there not a better way?
  final nodeIsEmpty = switch (nodeBeforePoint) {
    OrgListItem() => nodeBeforePoint.isEmpty,
    OrgHeadline() => nodeBeforePoint.isEmpty,
    _ => throw ArgumentError(),
  };
  if (nodeIsEmpty) {
    // The node above the cursor is empty (it only contains the line break we
    // just added and maybe some whitespace), so remove it
    return value
        .replaced(TextRange(start: span.start, end: lastEOLIdx + 1), '')
        .copyWith(
          selection: value.selection.shift(-(lastEOLIdx + 1 - span.start)),
        );
  }

  // Insert a new list item
  final replacement = switch (nodeBeforePoint) {
    OrgListItem() => nodeBeforePoint.next(),
    OrgHeadline() => nodeBeforePoint.next(),
    _ => throw ArgumentError(),
  }.toMarkup();
  return value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length,
        ),
      );
}
