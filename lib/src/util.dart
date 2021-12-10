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
