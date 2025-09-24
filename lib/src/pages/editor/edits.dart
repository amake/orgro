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
  final atOffset = doc.nodesAtOffset(value.selection.start);

  final foundListItem =
      atOffset.where((e) => e.node is OrgListItem).firstOrNull?.node
          as OrgListItem?;

  final lastEOLIdx = value.selection.start == 0
      ? -1
      : value.text.lastIndexOf('\n', value.selection.start - 1);
  final lineStart = lastEOLIdx + 1;

  switch (foundListItem) {
    case null:
      {
        TextEditingValue replaceBOL(String replacement) => value
            .replaced(TextRange.collapsed(lineStart), replacement)
            .copyWith(
              selection: TextSelection.collapsed(
                offset: value.selection.baseOffset + replacement.length,
              ),
            );

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

        // No list item found, so just insert a new list item at line start
        if (previous == null) return replaceBOL('1. ');

        final replacement = nextListItem(previous).toMarkup();
        return replaceBOL(replacement);
      }
    case OrgListOrderedItem():
      {
        final foundListItemLength = foundListItem.toMarkup().length;

        // Turn into normal text
        final firstBodyNode = foundListItem.body;
        final preambleLength = firstBodyNode == null
            ? foundListItemLength
            : foundListItem.toMarkupLocating(firstBodyNode).$2;
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + preambleLength),
              '',
            )
            .copyWith(
              selection: TextSelection.collapsed(
                offset: value.selection.baseOffset - preambleLength,
              ),
            );
      }
    case OrgListUnorderedItem():
      {
        if (foundListItem.tag != null) {
          // Ordered list items can't have tags, so avoid destructive change
          return null;
        }

        final foundListItemLength = foundListItem.toMarkup().length;

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
          foundListItem.indent,
          previous is OrgListOrderedItem ? nextBullet(previous) : '1. ',
          null,
          foundListItem.checkbox,
          foundListItem.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + foundListItemLength),
              replacement,
            )
            .copyWith(
              selection: TextSelection.collapsed(
                offset:
                    value.selection.baseOffset +
                    replacement.length -
                    foundListItemLength,
              ),
            );
      }
  }
}

TextEditingValue? toggleUnorderedListItem(TextEditingValue value) {
  if (!value.selection.isValid) return null;

  final doc = OrgDocument.parse(value.text);
  final atOffset = doc.nodesAtOffset(value.selection.start);

  final foundListItem =
      atOffset.where((e) => e.node is OrgListItem).firstOrNull?.node
          as OrgListItem?;

  final lastEOLIdx = value.selection.start == 0
      ? -1
      : value.text.lastIndexOf('\n', value.selection.start - 1);
  final lineStart = lastEOLIdx + 1;

  switch (foundListItem) {
    case null:
      {
        TextEditingValue replaceBOL(String replacement) => value
            .replaced(TextRange.collapsed(lineStart), replacement)
            .copyWith(
              selection: TextSelection.collapsed(
                offset: value.selection.baseOffset + replacement.length,
              ),
            );

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

        // No list item found, so just insert a new list item at line start
        if (previous == null) return replaceBOL('- ');

        final replacement = nextListItem(previous).toMarkup();
        return replaceBOL(replacement);
      }
    case OrgListUnorderedItem():
      {
        final foundListItemLength = foundListItem.toMarkup().length;

        // Turn into normal text
        final firstBodyNode = foundListItem.tag?.value ?? foundListItem.body;
        final preambleLength = firstBodyNode == null
            ? foundListItemLength
            : foundListItem.toMarkupLocating(firstBodyNode).$2;
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + preambleLength),
              '',
            )
            .copyWith(
              selection: TextSelection.collapsed(
                offset: value.selection.baseOffset - preambleLength,
              ),
            );
      }
    case OrgListOrderedItem():
      {
        final foundListItemLength = foundListItem.toMarkup().length;

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
          foundListItem.indent,
          previous is OrgListUnorderedItem ? previous.bullet : '- ',
          foundListItem.checkbox,
          null,
          foundListItem.body,
        ).toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + foundListItemLength),
              replacement,
            )
            .copyWith(
              selection: TextSelection.collapsed(
                offset:
                    value.selection.baseOffset +
                    replacement.length -
                    foundListItemLength,
              ),
            );
      }
  }
}

String nextBullet(OrgListItem item) => switch (item) {
  OrgListUnorderedItem() => item.bullet,
  OrgListOrderedItem() => (() {
    final decimalIdx = item.bullet.indexOf('.');
    if (decimalIdx == -1) return item.bullet;
    final number = int.parse(item.bullet.substring(0, decimalIdx));
    final delimiter = item.bullet.substring(decimalIdx);
    return '${number + 1}$delimiter';
  })(),
};

OrgListItem nextListItem(OrgListItem previous) => switch (previous) {
  OrgListUnorderedItem() => OrgListUnorderedItem(
    previous.indent,
    nextBullet(previous),
    previous.checkbox != null ? '[ ]' : null,
    null,
    null,
  ),
  OrgListOrderedItem() => OrgListOrderedItem(
    previous.indent,
    nextBullet(previous),
    null,
    previous.checkbox != null ? '[ ]' : null,
    null,
  ),
};

bool atEOL(String text, int offset) {
  if (offset == text.length) return true;
  return text.codeUnitAt(offset) == 0x0a;
}

TextEditingValue? afterNewLineFixup(TextEditingValue value) {
  if (!value.selection.isValid) return null;
  if (value.selection.start < 2) return null;
  if (!atEOL(value.text, value.selection.start)) return null;
  final lastEOLIdx = value.text.lastIndexOf('\n', value.selection.start - 1);

  final doc = OrgDocument.parse(value.text);
  final atOffset = doc.nodesAtOffset(lastEOLIdx);
  final foundListItem =
      atOffset.where((e) => e.node is OrgListItem).firstOrNull?.node
          as OrgListItem?;
  if (foundListItem == null) return value;

  // Insert a new list item
  final replacement = nextListItem(foundListItem).toMarkup();
  return value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length,
        ),
      );
}
