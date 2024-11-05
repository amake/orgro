import 'package:org_flutter/org_flutter.dart';

class _ProgressScope {
  _ProgressScope(this.parent);

  final OrgNode parent;
  int total = 0;
  int done = 0;
  final List<OrgStatisticsCookie> cookies = [];
}

OrgTree recalculateListStats(OrgTree root, OrgListItem target) {
  final (node: _, :path) = root.find((node) => identical(node, target))!;
  final tree = path.reversed.whereType<OrgTree>().first;
  var replacement = _recalculateCheckboxes(tree);
  replacement = _recalculateListStats(replacement);
  return root.edit().find(tree)!.replace(replacement).commit() as OrgTree;
}

OrgTree _recalculateCheckboxes(OrgTree tree) {
  final scopes = _visitListScopes(tree);

  var result = tree;
  var recalculate = false;
  for (final scope in scopes) {
    if (scope.total == 0) continue;

    final parent = scope.parent;
    if (parent is! OrgListItem || parent.checkbox == null) continue;

    final newCheckbox = scope.done == 0
        ? '[ ]'
        : scope.done == scope.total
            ? '[X]'
            : '[-]';

    if (parent.checkbox == newCheckbox) continue;

    // The parent progress may have changed now, so we take another pass
    //
    // TODO(aaron): See if there's a simple way to do this in a single pass
    recalculate = true;
    final zipper = result.editNode(parent);
    if (zipper != null) {
      final newListItem = switch (parent) {
        OrgListOrderedItem() => parent.copyWith(checkbox: newCheckbox),
        OrgListUnorderedItem() => parent.copyWith(checkbox: newCheckbox),
      };
      result = zipper.replace(newListItem).commit() as OrgTree;
    } else {
      // The parent has been removed from the tree by a previous edit; we
      // are recalculating anyway so just ignore.
    }
  }
  if (recalculate) {
    result = _recalculateCheckboxes(result);
  }
  return result;
}

OrgTree _recalculateListStats(OrgTree tree) {
  final scopes = _visitListScopes(tree);

  var result = tree;
  for (final scope in scopes) {
    final parent = scope.parent;
    if (parent is OrgSection &&
        parent.getProperties(':COOKIE_DATA:').firstOrNull == 'todo') continue;
    for (final cookie in scope.cookies) {
      final newCookie = cookie.update(done: scope.done, total: scope.total);
      result = result.editNode(cookie)!.replace(newCookie).commit() as OrgTree;
    }
  }
  return result;
}

// This visitor encodes the logic that cookies only count immediate children,
// not all descendants. If we wanted to support
// `org-checkbox-hierarchical-statistics` we would adjust here.
List<_ProgressScope> _visitListScopes(
  OrgNode node, [
  List<_ProgressScope>? stack,
  List<_ProgressScope>? acc,
]) {
  stack ??= [];
  acc ??= [];

  // Current scope stuff
  if (node is OrgListItem) {
    if (node.checkbox == '[X]') stack.last.done++;
    if (node.checkbox != null) stack.last.total++;
  } else if (node is OrgStatisticsCookie) {
    stack.last.cookies.add(node);
  }

  if (stack.isNotEmpty && node is OrgSection) {
    // Don't recurse any deeper than first tree
    return acc;
  }

  var pushedScope = false;
  if (node is OrgTree || node is OrgListItem) {
    stack.add(_ProgressScope(node));
    pushedScope = true;
  }
  final children = node.children;
  if (children != null) {
    for (final child in children) {
      _visitListScopes(child, stack, acc);
    }
  }
  if (pushedScope) acc.add(stack.removeLast());
  return acc;
}

OrgTree recalculateHeadlineStats(OrgTree root, OrgHeadline target) {
  final (node: _, :path) = root.find((node) => identical(node, target))!;
  final tree = path.reversed
      .whereType<OrgTree>()
      // Skip the section that the headline belongs to
      .skip(1)
      .first;
  final replacement = _recalculateHeadlineStats(tree);
  return root.edit().find(tree)!.replace(replacement).commit() as OrgTree;
}

OrgTree _recalculateHeadlineStats(OrgTree tree) {
  final scopes = _visitHeadlineScopes(tree);

  var result = tree;
  for (final scope in scopes) {
    final parent = scope.parent;
    if (parent is OrgSection &&
        parent.getProperties(':COOKIE_DATA:').firstOrNull == 'checkbox') {
      continue;
    }
    for (final cookie in scope.cookies) {
      final newCookie = cookie.update(done: scope.done, total: scope.total);
      result = result.editNode(cookie)!.replace(newCookie).commit() as OrgTree;
    }
  }
  return result;
}

List<_ProgressScope> _visitHeadlineScopes(
  OrgTree tree, [
  List<_ProgressScope>? stack,
  List<_ProgressScope>? acc,
]) {
  stack ??= [];
  acc ??= [];
  var pushedScope = false;
  if (tree is OrgSection) {
    pushedScope = true;
    if (stack.isNotEmpty && tree.headline.keyword != null) {
      if (tree.headline.keyword!.done) stack.last.done++;
      stack.last.total++;
    }

    final scope = _ProgressScope(tree);
    stack.add(scope);

    tree.headline.visit<OrgNode>((node) {
      if (node is OrgStatisticsCookie) {
        scope.cookies.add(node);
      }
      return true;
    });
  }
  for (final child in tree.sections) {
    _visitHeadlineScopes(child, stack);
  }
  if (pushedScope) acc.add(stack.removeLast());
  return acc;
}
