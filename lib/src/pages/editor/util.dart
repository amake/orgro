import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';

// TODO(aaron): End is truncated by the end of the visited range, which seems
// like it must be surprising for consumers. What to do?
typedef NodeSpan = ({int start, int end});

extension OrgTreeEditing on OrgNode {
  List<({OrgNode node, NodeSpan span})> nodesAtOffset(int offset) {
    final finder = _NodeFinder(offset, offset);
    toMarkup(serializer: finder);
    return finder.nodes;
  }

  List<({OrgNode node, NodeSpan span})> nodesInRange(int start, int end) {
    if (start > end) (start, end) = (end, start);
    final finder = _NodeFinder(start, end);
    toMarkup(serializer: finder);
    return finder.nodes;
  }

  ({String text, int start, int end}) toMarkupLocating(OrgNode node) {
    final serializer = _NodeLocatingSeralizer(node);
    final text = toMarkup(serializer: serializer);
    return (text: text, start: serializer.start, end: serializer.end);
  }
}

class _NodeFinder extends OrgSerializer {
  _NodeFinder(this.start, this.end) : assert(start <= end);

  final int start;
  final int end;
  int i = 0;
  final nodes = <({OrgNode node, NodeSpan span})>[];

  @override
  void visit(OrgNode node) {
    if (i > end) return;
    final nodeStart = i;
    super.visit(node);
    if (i > start) {
      nodes.add((node: node, span: (start: nodeStart, end: i)));
    }
  }

  @override
  void write(String str) {
    i += str.length;
  }
}

class _NodeLocatingSeralizer extends OrgSerializer {
  _NodeLocatingSeralizer(this.node);

  final OrgNode node;
  int start = -1;
  int end = -1;

  @override
  void visit(OrgNode node) {
    final isTarget = identical(node, this.node);
    if (isTarget) start = length;
    super.visit(node);
    if (isTarget) end = length;
  }
}

bool lineBreakInserted(String? before, TextEditingValue after) {
  if (before == null) return false;
  if (before.length + 1 != after.text.length) return false;
  if (!after.selection.isValid) return false;
  if (!after.selection.isCollapsed) return false;
  if (after.selection.start < 1) return false;
  if (after.text.codeUnitAt(after.selection.start - 1) != 0x0a) return false;
  return true;
}
