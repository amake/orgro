import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/pages/editor/edits.dart';
import 'package:orgro/src/timestamps.dart';

class SaveChangesIntent extends Intent {
  const SaveChangesIntent();
}

abstract class _TextEditingAction<T extends Intent> extends ContextAction<T> {
  _TextEditingAction(this.controller);
  final TextEditingController controller;

  @override
  bool isEnabled(T intent, [BuildContext? context]) {
    return super.isEnabled(intent, context) &&
        controller.value.selection.isValid;
  }

  void _applyEdit(
    FutureOr<TextEditingValue?> Function(TextEditingValue) edit,
  ) async {
    final value = await edit(controller.value);
    if (value == null) return;
    controller.value = value;
    ContextMenuController.removeAny();
  }
}

class MakeBoldIntent extends Intent {
  const MakeBoldIntent();
}

class MakeBoldAction extends _TextEditingAction<MakeBoldIntent> {
  MakeBoldAction(super.controller);

  @override
  void invoke(covariant MakeBoldIntent intent, [BuildContext? context]) {
    _applyEdit(makeBold);
  }
}

class MakeItalicIntent extends Intent {
  const MakeItalicIntent();
}

class MakeItalicAction extends _TextEditingAction<MakeItalicIntent> {
  MakeItalicAction(super.controller);

  @override
  void invoke(covariant MakeItalicIntent intent, [BuildContext? context]) {
    _applyEdit(makeItalic);
  }
}

class MakeUnderlineIntent extends Intent {
  const MakeUnderlineIntent();
}

class MakeUnderlineAction extends _TextEditingAction<MakeUnderlineIntent> {
  MakeUnderlineAction(super.controller);

  @override
  void invoke(covariant MakeUnderlineIntent intent, [BuildContext? context]) {
    _applyEdit(makeUnderline);
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
    _applyEdit(makeStrikethrough);
  }
}

class MakeCodeIntent extends Intent {
  const MakeCodeIntent();
}

class MakeCodeAction extends _TextEditingAction<MakeCodeIntent> {
  MakeCodeAction(super.controller);

  @override
  void invoke(covariant MakeCodeIntent intent, [BuildContext? context]) {
    _applyEdit(makeCode);
  }
}

class MakeSubscriptIntent extends Intent {
  const MakeSubscriptIntent();
}

class MakeSubscriptAction extends _TextEditingAction<MakeSubscriptIntent> {
  MakeSubscriptAction(super.controller);

  @override
  void invoke(covariant MakeSubscriptIntent intent, [BuildContext? context]) {
    _applyEdit(makeSubscript);
  }
}

class MakeSuperscriptIntent extends Intent {
  const MakeSuperscriptIntent();
}

class MakeSuperscriptAction extends _TextEditingAction<MakeSuperscriptIntent> {
  MakeSuperscriptAction(super.controller);

  @override
  void invoke(covariant MakeSuperscriptIntent intent, [BuildContext? context]) {
    _applyEdit(makeSuperscript);
  }
}

class InsertLinkIntent extends Intent {
  const InsertLinkIntent();
}

class InsertLinkAction extends _TextEditingAction<InsertLinkIntent> {
  InsertLinkAction(super.controller);

  @override
  void invoke(
    covariant InsertLinkIntent intent, [
    BuildContext? context,
  ]) async {
    final clipboardText = await Clipboard.hasStrings()
        ? (await Clipboard.getData(Clipboard.kTextPlain))?.text
        : null;
    _applyEdit(((value) => insertLink(value, clipboardText)));
  }
}

class InsertDateIntent extends Intent {
  const InsertDateIntent();
}

class InsertDateAction extends _TextEditingAction<InsertDateIntent> {
  InsertDateAction(super.controller);

  @override
  void invoke(
    covariant InsertDateIntent intent, [
    BuildContext? context,
  ]) async {
    if (context != null) {
      final date = await showDatePicker(
        context: context,
        firstDate: kDatePickerFirstDate,
        lastDate: kDatePickerLastDate,
      );
      if (date == null || !context.mounted) return null;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      _applyEdit((value) => insertDate(value, date, time));
    }
  }
}

class ToggleListItemIntent extends Intent {
  const ToggleListItemIntent({required this.ordered});
  final bool ordered;
}

class ToggleListItemAction extends _TextEditingAction<ToggleListItemIntent> {
  ToggleListItemAction(super.controller);

  @override
  void invoke(covariant ToggleListItemIntent intent, [BuildContext? context]) {
    _applyEdit((value) => toggleListItem(value, intent.ordered));
  }
}

