import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
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
