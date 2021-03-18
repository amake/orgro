import 'package:org_flutter/org_flutter.dart';

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

extension OrgTreeUtils on OrgTree {
  bool hasRemoteImages() {
    var result = false;
    visit<OrgLink>((link) {
      result |=
          looksLikeImagePath(link.location) && looksLikeUrl(link.location);
      return !result;
    });
    return result;
  }
}
