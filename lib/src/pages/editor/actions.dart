import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/common.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/pages/editor/clipboard.dart';
import 'package:orgro/src/pages/editor/editor.dart';
import 'package:orgro/src/pages/editor/edits.dart';
import 'package:orgro/src/timestamps.dart';

class EditorActions extends StatelessWidget {
  EditorActions({
    required this.controller,
    required this.onSave,
    required this.child,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final Widget child;

  late final _actions = <Type, Action<Intent>>{
    SaveChangesIntent: CallbackAction(onInvoke: (_) => onSave()),
    CloseViewIntent: CloseViewAction(),
    MakeBoldIntent: MakeBoldAction(),
    MakeItalicIntent: MakeItalicAction(),
    MakeUnderlineIntent: MakeUnderlineAction(),
    MakeStrikethroughIntent: MakeStrikethroughAction(),
    MakeCodeIntent: MakeCodeAction(),
    InsertLinkIntent: InsertLinkAction(),
    InsertDateIntent: InsertDateAction(),
    MakeSubscriptIntent: MakeSubscriptAction(),
    MakeSuperscriptIntent: MakeSuperscriptAction(),
    ToggleListItemIntent: ToggleListItemAction(),
    InsertHeadlineIntent: InsertHeadlineAction(),
    AfterNewLineIntent: AfterNewLineAction(),
    ChangeIndentIntent: ChangeIndentAction(),
    EncryptSectionIntent: EncryptSectionAction(),
    ScrollToDocumentBoundaryIntent: ScrollToDocumentBoundaryAction(),
    PasteTextIntent: PasteTextAction(),
  };

  @override
  Widget build(BuildContext context) {
    return _PrimaryTextEditingController(
      controller: controller,
      child: Builder(
        builder: (context) => Actions(actions: _actions, child: child),
      ),
    );
  }
}

class _PrimaryTextEditingController extends InheritedWidget {
  const _PrimaryTextEditingController({
    required this.controller,
    required super.child,
  });

  final TextEditingController controller;

  static TextEditingController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PrimaryTextEditingController>()!
      .controller;

  @override
  bool updateShouldNotify(covariant _PrimaryTextEditingController oldWidget) =>
      controller != oldWidget.controller;
}

class SaveChangesIntent extends Intent {
  const SaveChangesIntent();
}

abstract class _TextEditingAction<T extends Intent> extends ContextAction<T> {
  @override
  bool isEnabled(T intent, [BuildContext? context]) {
    if (!super.isEnabled(intent, context)) return false;
    final controller = _PrimaryTextEditingController.of(context!);
    return controller.value.selection.isValid;
  }

  void _applyEdit(
    BuildContext? context,
    FutureOr<TextEditingValue?> Function(TextEditingValue) edit,
  ) async {
    final controller = _PrimaryTextEditingController.of(context!);
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
  @override
  void invoke(covariant MakeBoldIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeBold);
  }
}

class MakeItalicIntent extends Intent {
  const MakeItalicIntent();
}

class MakeItalicAction extends _TextEditingAction<MakeItalicIntent> {
  @override
  void invoke(covariant MakeItalicIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeItalic);
  }
}

class MakeUnderlineIntent extends Intent {
  const MakeUnderlineIntent();
}

class MakeUnderlineAction extends _TextEditingAction<MakeUnderlineIntent> {
  @override
  void invoke(covariant MakeUnderlineIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeUnderline);
  }
}

class MakeStrikethroughIntent extends Intent {
  const MakeStrikethroughIntent();
}

class MakeStrikethroughAction
    extends _TextEditingAction<MakeStrikethroughIntent> {
  @override
  void invoke(
    covariant MakeStrikethroughIntent intent, [
    BuildContext? context,
  ]) {
    _applyEdit(context, makeStrikethrough);
  }
}

class MakeCodeIntent extends Intent {
  const MakeCodeIntent();
}

class MakeCodeAction extends _TextEditingAction<MakeCodeIntent> {
  @override
  void invoke(covariant MakeCodeIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeCode);
  }
}

class MakeSubscriptIntent extends Intent {
  const MakeSubscriptIntent();
}

class MakeSubscriptAction extends _TextEditingAction<MakeSubscriptIntent> {
  @override
  void invoke(covariant MakeSubscriptIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeSubscript);
  }
}

class MakeSuperscriptIntent extends Intent {
  const MakeSuperscriptIntent();
}

class MakeSuperscriptAction extends _TextEditingAction<MakeSuperscriptIntent> {
  @override
  void invoke(covariant MakeSuperscriptIntent intent, [BuildContext? context]) {
    _applyEdit(context, makeSuperscript);
  }
}

class InsertLinkIntent extends Intent {
  const InsertLinkIntent();
}

class InsertLinkAction extends _TextEditingAction<InsertLinkIntent> {
  @override
  void invoke(
    covariant InsertLinkIntent intent, [
    BuildContext? context,
  ]) async {
    if (context == null) return;
    final clipboardText = await Clipboard.hasStrings()
        ? (await Clipboard.getData(Clipboard.kTextPlain))?.text
        : null;
    if (!context.mounted) return;
    _applyEdit(context, ((value) => insertLink(value, clipboardText)));
  }
}

class InsertDateIntent extends Intent {
  const InsertDateIntent({required this.active});
  final bool active;
}

class InsertDateAction extends _TextEditingAction<InsertDateIntent> {
  @override
  void invoke(
    covariant InsertDateIntent intent, [
    BuildContext? context,
  ]) async {
    if (context == null) return;
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
    if (!context.mounted) return;
    _applyEdit(
      context,
      (value) => insertDate(value, intent.active, date, time),
    );
  }
}

class InsertHeadlineIntent extends Intent {
  const InsertHeadlineIntent();
}

class InsertHeadlineAction extends _TextEditingAction<InsertHeadlineIntent> {
  @override
  void invoke(covariant InsertHeadlineIntent intent, [BuildContext? context]) {
    _applyEdit(context, insertHeadline);
  }
}

class ToggleListItemIntent extends Intent {
  const ToggleListItemIntent({required this.ordered});
  final bool ordered;
}

class ToggleListItemAction extends _TextEditingAction<ToggleListItemIntent> {
  @override
  void invoke(covariant ToggleListItemIntent intent, [BuildContext? context]) {
    _applyEdit(
      context,
      (value) => intent.ordered
          ? toggleOrderedListItem(value)
          : toggleUnorderedListItem(value),
    );
  }
}

class AfterNewLineIntent extends Intent {
  const AfterNewLineIntent();
}

class AfterNewLineAction extends _TextEditingAction<AfterNewLineIntent> {
  // TODO(aaron): This is only needed because where we want to apply this action
  // doesn't actually have the right context, so we have to apply it directly to
  // the controller instead of using the standard mechanism.
  static void directlyApply(TextEditingController controller) {
    final value = afterNewLineFixup(controller.value);
    if (value == null) return;
    controller.value = value;
    ContextMenuController.removeAny();
  }

  @override
  void invoke(covariant AfterNewLineIntent intent, [BuildContext? context]) {
    _applyEdit(context, afterNewLineFixup);
  }
}

class ChangeIndentIntent extends Intent {
  const ChangeIndentIntent({required this.increase});
  final bool increase;
}

class ChangeIndentAction extends _TextEditingAction<ChangeIndentIntent> {
  @override
  void invoke(covariant ChangeIndentIntent intent, [BuildContext? context]) {
    _applyEdit(context, (value) => changeIndent(value, intent.increase));
  }
}

class EncryptSectionIntent extends Intent {
  const EncryptSectionIntent();
}

class EncryptSectionAction extends _TextEditingAction<EncryptSectionIntent> {
  @override
  void invoke(covariant EncryptSectionIntent intent, [BuildContext? context]) {
    _applyEdit(context, encryptSection);
  }
}

class PasteTextAction extends ContextAction<PasteTextIntent> {
  @override
  void invoke(PasteTextIntent intent, [BuildContext? context]) async {
    if (context != null &&
        await hasClipboardImageData() &&
        context.mounted == true) {
      final controller = _PrimaryTextEditingController.of(context);
      try {
        final success = await pasteImagesFromClipboard(context, controller);
        if (success) return;
      } catch (e, s) {
        logError(e, s);
        if (context.mounted) showErrorSnackBar(context, e);
      }
    }
    _delegatePaste(intent);
  }

  void _delegatePaste(PasteTextIntent intent) {
    final textFieldState = editorTextFieldKey.currentState;
    if (textFieldState == null) return;
    if (textFieldState is! TextSelectionGestureDetectorBuilderDelegate) return;
    final editableTextKey =
        (textFieldState as TextSelectionGestureDetectorBuilderDelegate)
            .editableTextKey;
    editableTextKey.currentState?.pasteText(intent.cause);
  }
}
