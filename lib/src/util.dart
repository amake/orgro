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

extension ListUtils<T> on List<T> {
  Map<T, T> keyValueListAsMap() {
    if ((length % 2) != 0) {
      throw Exception('List must have an even number of elements');
    }
    final result = <T, T>{};
    for (var i = 0; i < length; i += 2) {
      final key = this[i];
      final value = this[i + 1];
      result[key] = value;
    }
    return result;
  }
}

bool looksLikeRelativePath(String text) =>
    _relativePathLikeRegexp.hasMatch(text);

final _relativePathLikeRegexp = RegExp(r'^\.');
