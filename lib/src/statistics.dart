import 'package:org_flutter/org_flutter.dart';

OrgTree recalculateListStats(OrgTree tree) {
  final stack = <_ProgressScope>[];
  final finished = <_ProgressScope>[];

  // This visitor encodes the logic that cookies only count immediate children,
  // not all descendants. If we wanted to support
  // `org-checkbox-hierarchical-statistics` we would adjust here.
  void visit(OrgNode node) {
    // Current scope stuff
    if (node is OrgListItem) {
      if (node.checkbox == '[X]') stack.last.done++;
      if (node.checkbox != null) stack.last.total++;
    } else if (node is OrgStatisticsFractionCookie ||
        node is OrgStatisticsPercentageCookie) {
      stack.last.cookies.add(node);
    }

    var pushedScope = false;
    if (node is OrgTree || node is OrgListItem) {
      stack.add(_ProgressScope(node));
      pushedScope = true;
    }
    final children = node.children;
    if (children != null) {
      for (final child in children) {
        visit(child);
      }
    }
    if (pushedScope) finished.add(stack.removeLast());
  }

  visit(tree);

  var result = tree;
  var recalculate = false;
  for (final scope in finished) {
    for (final cookie in scope.cookies) {
      final newCookie = scope.updatedCookie(cookie);
      result = result.editNode(cookie)!.replace(newCookie).commit() as OrgTree;
    }
    final parent = scope.parent;
    if (parent is OrgListItem && parent.checkbox != null && scope.total > 0) {
      final newCheckbox = scope.done == 0
          ? '[ ]'
          : scope.done == scope.total
              ? '[X]'
              : '[-]';
      // The parent progress may have changed now, so we take a second pass
      //
      // TODO(aaron): See if there's a simple way to do this in a single pass
      recalculate |= parent.checkbox != newCheckbox;
      final newListItem = switch (parent) {
        OrgListOrderedItem() => parent.copyWith(checkbox: newCheckbox),
        OrgListUnorderedItem() => parent.copyWith(checkbox: newCheckbox),
      };
      result =
          result.editNode(parent)!.replace(newListItem).commit() as OrgTree;
    }
  }
  if (recalculate) {
    result = recalculateListStats(result);
  }
  return result;
}

class _ProgressScope {
  _ProgressScope(this.parent);

  final OrgNode parent;
  int total = 0;
  int done = 0;
  final List<OrgNode> cookies = [];

  OrgNode updatedCookie(OrgNode cookie) {
    if (cookie is OrgStatisticsFractionCookie) {
      return cookie.copyWith(
          numerator: done.toString(), denominator: total.toString());
    } else if (cookie is OrgStatisticsPercentageCookie) {
      return cookie.copyWith(
          percentage:
              done == 0 ? '0' : (done / total * 100).round().toString());
    } else {
      throw Error();
    }
  }
}

OrgTree recalculateHeadlineStats(OrgTree tree) {
  final stack = <_ProgressScope>[];
  final finished = <_ProgressScope>[];

  void visit(OrgTree tree) {
    var pushedScope = false;
    if (tree is OrgSection) {
      pushedScope = true;
      if (stack.isNotEmpty && tree.headline.keyword != null) {
        if (tree.headline.keyword!.done) stack.last.done++;
        stack.last.total++;
      }

      stack.add(_ProgressScope(tree));

      tree.headline.visit<OrgNode>((node) {
        if (node is OrgStatisticsFractionCookie ||
            node is OrgStatisticsPercentageCookie) {
          stack.last.cookies.add(node);
        }
        return true;
      });
    }
    for (final child in tree.sections) {
      visit(child);
    }
    if (pushedScope) finished.add(stack.removeLast());
  }

  visit(tree);

  var result = tree;
  for (final scope in finished) {
    for (final cookie in scope.cookies) {
      final newCookie = scope.updatedCookie(cookie);
      result = result.editNode(cookie)!.replace(newCookie).commit() as OrgTree;
    }
  }
  return result;
}
