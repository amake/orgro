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
