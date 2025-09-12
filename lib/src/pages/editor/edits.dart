import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/util.dart';
import 'package:orgro/src/timestamps.dart';
import 'package:petitparser/petitparser.dart';

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

final listParser = (() {
  final grammar = OrgContentParserDefinition();
  return grammar.buildFrom(grammar.listItem());
})();

TextEditingValue? toggleListItem(TextEditingValue value, bool ordered) {
  if (!value.selection.isValid) return null;
  final lineStart = max(
    0,
    value.text.lastIndexOf('\n', value.selection.start) + 1,
  );
  final result = listParser.parse(value.text, start: lineStart);
  if (result is Failure) {
    // Turn into list item
    final previous = listItemAtOffset(value.text, lineStart - 1);
    final replacement = switch (previous) {
      OrgListItem() => nextListItem(previous).toMarkup(),
      null => ordered ? '1. ' : '- ',
    };
    return value
        .replaced(TextRange.collapsed(lineStart), replacement)
        .copyWith(
          selection: TextSelection.collapsed(
            offset: value.selection.baseOffset + replacement.length,
          ),
        );
  } else {
    final existing = result.value as OrgListItem;
    final existingLength = existing.toMarkup().length;
    switch ((existing, ordered)) {
      // Turn into normal text
      case (OrgListUnorderedItem(), false): // Fallthrough
      case (OrgListOrderedItem(), true):
        final firstBodyNode = switch (existing) {
          OrgListUnorderedItem(tag: final tag?) => tag.value,
          _ => existing.body,
        };
        final preambleLength = firstBodyNode == null
            ? existingLength
            : existing.toMarkupLocating(firstBodyNode).$2;
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
      default:
        // Switch type of list
        // TODO(aaron): Should act on entire list, not just this item
        final previous = listItemAtOffset(value.text, lineStart - 1);
        final replacement = switch ((existing, ordered)) {
          (OrgListUnorderedItem(tag: null), true) => OrgListOrderedItem(
            existing.indent,
            previous is OrgListOrderedItem ? nextBullet(previous) : '1. ',
            null,
            existing.checkbox,
            existing.body,
          ),
          // Ordered list items can't have tags, so avoid destructive change
          (OrgListUnorderedItem(), true) => existing,
          (OrgListOrderedItem(), false) => OrgListUnorderedItem(
            existing.indent,
            previous is OrgListUnorderedItem ? previous.bullet : '- ',
            existing.checkbox,
            null,
            existing.body,
          ),
          _ => throw Exception('Unreachable'),
        }.toMarkup();
        return value
            .replaced(
              TextRange(start: lineStart, end: lineStart + existingLength),
              replacement,
            )
            .copyWith(
              selection: TextSelection.collapsed(
                offset:
                    value.selection.baseOffset +
                    replacement.length -
                    existingLength,
              ),
            );
    }
  }
}

OrgListItem? listItemAtOffset(String text, int offset) {
  final doc = OrgDocument.parse(text);
  final found = doc.nodesAtOffset(offset);
  if (found.isEmpty) return null;
  final (:node, :span) = found.firstWhere((e) => e.node is OrgListItem);
  if (span.end != offset + 1) return null;
  return node as OrgListItem;
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

