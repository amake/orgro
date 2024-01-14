import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
      .getBoxesForSelection(TextSelection(
          baseOffset: 0, extentOffset: widget.text.toPlainText().length))
      .first;
}

final platformShortcutKey = Platform.isIOS || Platform.isMacOS
    ? LogicalKeyboardKey.meta
    : LogicalKeyboardKey.control;

extension GlobalPaintBounds on BuildContext {
  Rect? get _globalPaintBounds {
    final renderObject = findRenderObject();
    if (renderObject == null) return null;

    final translation = renderObject.getTransformTo(null).getTranslation();
    return renderObject.paintBounds.shift(Offset(translation.x, translation.y));
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

String joinPath(String base, String rest) {
  if (rest.isEmpty) return base;
  if (base.isEmpty) return rest;
  if (base.endsWith('/')) return '$base$rest';
  return '$base/$rest';
}
