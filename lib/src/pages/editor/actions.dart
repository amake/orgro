import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/timestamps.dart';

class SaveChangesIntent extends Intent {
  const SaveChangesIntent();
}

abstract class _TextEditingAction<T extends Intent> extends ContextAction<T> {
  _TextEditingAction(this.controller);
  final TextEditingController controller;
}

class MakeBoldIntent extends Intent {
  const MakeBoldIntent();
}

class MakeBoldAction extends _TextEditingAction<MakeBoldIntent> {
  MakeBoldAction(super.controller);

  @override
  void invoke(covariant MakeBoldIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '*', '*');
  }
}

class MakeItalicIntent extends Intent {
  const MakeItalicIntent();
}

class MakeItalicAction extends _TextEditingAction<MakeItalicIntent> {
  MakeItalicAction(super.controller);

  @override
  void invoke(covariant MakeItalicIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '/', '/');
  }
}

class MakeUnderlineIntent extends Intent {
  const MakeUnderlineIntent();
}

class MakeUnderlineAction extends _TextEditingAction<MakeUnderlineIntent> {
  MakeUnderlineAction(super.controller);

  @override
  void invoke(covariant MakeUnderlineIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '_', '_');
  }
}

class MakeStrikethroughIntent extends Intent {
  const MakeStrikethroughIntent();
}

class MakeStrikethroughAction
    extends _TextEditingAction<MakeStrikethroughIntent> {
  MakeStrikethroughAction(super.controller);

  @override
  void invoke(
    covariant MakeStrikethroughIntent intent, [
    BuildContext? context,
  ]) {
    _wrapSelection(controller, '+', '+');
  }
}

class MakeCodeIntent extends Intent {
  const MakeCodeIntent();
}

class MakeCodeAction extends _TextEditingAction<MakeCodeIntent> {
  MakeCodeAction(super.controller);

  @override
  void invoke(covariant MakeCodeIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '~', '~');
  }
}

class MakeSubscriptIntent extends Intent {
  const MakeSubscriptIntent();
}

class MakeSubscriptAction extends _TextEditingAction<MakeSubscriptIntent> {
  MakeSubscriptAction(super.controller);

  @override
  void invoke(covariant MakeSubscriptIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '_{', '}');
  }
}

class MakeSuperscriptIntent extends Intent {
  const MakeSuperscriptIntent();
}

class MakeSuperscriptAction extends _TextEditingAction<MakeSuperscriptIntent> {
  MakeSuperscriptAction(super.controller);

  @override
  void invoke(covariant MakeSuperscriptIntent intent, [BuildContext? context]) {
    _wrapSelection(controller, '^{', '}');
  }
}

void _wrapSelection(
  TextEditingController controller,
  String prefix,
  String suffix,
) {
  final value = controller.value;
  if (!value.selection.isValid) return;
  final selection = value.selection.textInside(value.text);
  final replacement = '$prefix$selection$suffix';
  controller.value = value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset:
              value.selection.baseOffset + replacement.length - suffix.length,
        ),
      );
  ContextMenuController.removeAny();
}

class InsertLinkIntent extends Intent {
  const InsertLinkIntent();
}

class InsertLinkAction extends _TextEditingAction<InsertLinkIntent> {
  InsertLinkAction(super.controller);

  @override
  void invoke(covariant InsertLinkIntent intent, [BuildContext? context]) {
    _insertLink(controller);
  }
}

void _insertLink(TextEditingController controller) async {
  final value = controller.value;
  if (!value.selection.isValid) return;
  final selection = value.selection.textInside(value.text);
  final url =
      _tryParseUrl(selection) ??
      (await Clipboard.hasStrings()
          ? _tryParseUrl((await Clipboard.getData(Clipboard.kTextPlain))?.text)
          : null);
  final description = url == null ? selection : null;
  final replacement = '[[${url ?? 'URL'}][${description ?? 'description'}]]';
  controller.value = value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length - 2,
        ),
      );
  ContextMenuController.removeAny();
}

class InsertDateIntent extends Intent {
  const InsertDateIntent();
}

class InsertDateAction extends _TextEditingAction<InsertDateIntent> {
  InsertDateAction(super.controller);

  @override
  void invoke(covariant InsertDateIntent intent, [BuildContext? context]) {
    if (context != null) {
      _insertDate(context, controller);
    }
  }
}

void _insertDate(BuildContext context, TextEditingController controller) async {
  final value = controller.value;
  if (!value.selection.isValid) return;
  final date = await showDatePicker(
    context: context,
    firstDate: kDatePickerFirstDate,
    lastDate: kDatePickerLastDate,
  );
  if (date == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  final replacement = OrgSimpleTimestamp(
    '[',
    date.toOrgDate(),
    time?.toOrgTime(),
    [],
    ']',
  ).toMarkup();
  controller.value = value
      .replaced(value.selection, replacement)
      .copyWith(
        selection: TextSelection.collapsed(
          offset: value.selection.baseOffset + replacement.length - 1,
        ),
      );
  ContextMenuController.removeAny();
}

String? _tryParseUrl(String? str) {
  if (str == null) return null;
  final uri = Uri.tryParse(str);
  // Uri.tryParse is very lenient and will accept lots of things other than what
  // people usually think of as URLs so we filter out anything that doesn't have
  // a scheme.
  return uri?.hasScheme == true ? str : null;
}
