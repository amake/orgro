import 'package:flutter/services.dart';

TextEditingValue testValue(String text) {
  final cleaned = text.replaceAll('|', '');
  final baseOffset = text.indexOf('|');
  final cursorCount = text.length - cleaned.length;
  assert(cursorCount == 1 || cursorCount == 2);
  final extentOffset = cursorCount == 2
      ? text.lastIndexOf('|') - 1
      : baseOffset;
  return TextEditingValue(
    text: cleaned,
    selection: TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
    ),
  );
}
