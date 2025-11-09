import 'package:flutter/material.dart';

/// A copy of [RestorableTextEditingController] with the addition of
/// restoring the selection.
class FullyRestorableTextEditingController
    extends RestorableChangeNotifier<TextEditingController> {
  factory FullyRestorableTextEditingController({
    String? text,
    int? selectionBaseOffset,
    int? selectionExtentOffset,
  }) {
    final selection =
        selectionBaseOffset == null || selectionExtentOffset == null
        ? null
        : TextSelection(
            baseOffset: selectionBaseOffset,
            extentOffset: selectionExtentOffset,
          );
    final value = text == null
        ? TextEditingValue.empty
        : selection == null
        ? TextEditingValue(text: text)
        : TextEditingValue(text: text, selection: selection);
    return FullyRestorableTextEditingController.fromValue(value);
  }

  FullyRestorableTextEditingController.fromValue(TextEditingValue value)
    : _initialValue = value;

  final TextEditingValue _initialValue;

  @override
  TextEditingController createDefaultValue() {
    return TextEditingController.fromValue(_initialValue);
  }

  @override
  TextEditingController fromPrimitives(Object? data) {
    final [
      text as String,
      selectionBaseOffset as int,
      selectionExtentOffset as int,
    ] = data as List<Object?>;
    return TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(
          baseOffset: selectionBaseOffset,
          extentOffset: selectionExtentOffset,
        ),
      ),
    );
  }

  @override
  Object toPrimitives() {
    return [
      value.text,
      value.selection.baseOffset,
      value.selection.extentOffset,
    ];
  }
}
