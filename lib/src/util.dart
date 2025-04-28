import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension IterUtils<T> on Iterable<T> {
  Iterable<R> zipMap<R, U>(Iterable<U> b, R Function(T, U) visit) sync* {
    final iterA = iterator;
    final iterB = b.iterator;
    while (iterA.moveNext() && iterB.moveNext()) {
      yield visit(iterA.current, iterB.current);
    }
  }

  Iterable<T> unique({Set<T>? cache}) sync* {
    final seen = cache ?? <T>{};
    for (final item in this) {
      if (seen.contains(item)) {
        // skip
      } else {
        seen.add(item);
        yield item;
      }
    }
  }
}

extension Iter2Utils<T, U> on Iterable<(T, U)> {
  Iterable<V> map2<V>(V Function(T, U) visit) sync* {
    for (final (a, b) in this) {
      yield visit(a, b);
    }
  }
}

extension MapUtils<T, U> on Map<T, U> {
  bool unorderedEquals(Map<T, U> other, {bool Function(U?, U?)? valueEquals}) {
    valueEquals ??= (a, b) => a == b;
    if (identical(this, other)) return true;
    if (length != other.length) return false;
    for (final key in keys) {
      if (!other.containsKey(key) || !valueEquals(this[key], other[key])) {
        return false;
      }
    }
    return true;
  }
}

extension ChildrenIterUtils on Iterable<Widget> {
  Iterable<Widget> separatedBy(Widget separator) sync* {
    final iter = iterator;
    if (!iter.moveNext()) return;
    yield iter.current;
    while (iter.moveNext()) {
      yield separator;
      yield iter.current;
    }
  }
}

TextBox renderedBounds(
  BuildContext context,
  BoxConstraints constraints,
  Text text,
) {
  final widget = text.build(context) as RichText;
  final renderObject = widget.createRenderObject(context);
  renderObject.layout(constraints);
  return renderObject
      .getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: widget.text.toPlainText().length,
        ),
      )
      .first;
}

final platformShortcutKey =
    Platform.isIOS || Platform.isMacOS
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;

extension GlobalPaintBounds on BuildContext {
  Rect? get _globalPaintBounds {
    if (!mounted) return null;
    try {
      final renderObject = findRenderObject();
      if (renderObject == null) return null;

      final translation = renderObject.getTransformTo(null).getTranslation();
      return renderObject.paintBounds.shift(
        Offset(translation.x, translation.y),
      );
    } catch (_) {
      return null;
    }
  }
}

extension TopBoundComparator on GlobalKey {
  int compareByTopBound(GlobalKey other) {
    final thisBounds = currentContext?._globalPaintBounds;
    final otherBounds = other.currentContext?._globalPaintBounds;
    if (thisBounds != null && otherBounds != null) {
      return thisBounds.top.compareTo(otherBounds.top);
    }
    if (thisBounds == null && otherBounds != null) return -1;
    if (thisBounds != null && otherBounds == null) return 1;
    return 0;
  }
}

VoidCallback debounce(VoidCallback func, Duration duration) {
  Timer? timer;
  return () {
    timer?.cancel();
    timer = Timer(duration, func);
  };
}

extension StringExtension on String {
  (String, String) splitLeadingWhitespace() {
    final idx = indexOf(RegExp(r'\S'));
    if (idx == -1) return ('', this);
    return (substring(0, idx), substring(idx));
  }

  (String, String, String) splitSurroundingWhitespace() {
    final leadingIdx = indexOf(RegExp(r'\S'));
    final leading = (leadingIdx == -1) ? '' : (substring(0, leadingIdx));
    final trailingIdx = lastIndexOf(RegExp(r'\S'));
    final trailing = (trailingIdx == -1) ? '' : (substring(trailingIdx + 1));
    return (
      leading,
      substring(
        leadingIdx == -1 ? 0 : leadingIdx,
        trailingIdx == -1 ? length : trailingIdx + 1,
      ),
      trailing,
    );
  }

  String trimSuff(String suffix) {
    if (endsWith(suffix)) {
      return substring(0, length - suffix.length);
    }
    return this;
  }

  String trimPrefSuff(String prefix, String suffix) {
    if (startsWith(prefix) && endsWith(suffix)) {
      return substring(prefix.length, length - suffix.length);
    }
    return this;
  }

  String? detectLineBreak() {
    final idx = indexOf('\n');
    if (idx == -1) return null;
    if (idx > 0 && this[idx - 1] == '\r') {
      return '\r\n';
    }
    return '\n';
  }

  String withTrailingLineBreak() {
    final lineBreak = detectLineBreak() ?? '\n';
    return endsWith(lineBreak) ? this : '$this$lineBreak';
  }

  String joinPath(String next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    if (endsWith('/')) return '$this$next';
    return '$this/$next';
  }

  RegExp asRegex() {
    final escaped = RegExp.escape(this);
    return RegExp(escaped, unicode: true, caseSensitive: false);
  }
}

// Work around iOS paste permission dialog appearing on every paste. This should
// be unnecessary pending https://github.com/flutter/flutter/issues/103163
Widget nativeWhenPossibleContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  if (SystemContextMenu.isSupported(context)) {
    return SystemContextMenu.editableText(editableTextState: editableTextState);
  }
  return AdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );
}

extension BoolUtil on bool {
  int compareTo(bool other) {
    if (this == other) return 0;
    return this ? 1 : -1;
  }
}
