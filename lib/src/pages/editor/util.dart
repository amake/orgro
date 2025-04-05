import 'package:org_flutter/org_flutter.dart';

extension OrgTreeEditing on OrgTree {
  List<OrgNode> nodesAtOffset(int offset) {
    final finder = _NodeFinder(offset, offset);
    toMarkup(serializer: finder);
    return finder.nodes;
  }

  List<OrgNode> nodesInRange(int start, int end) {
    if (start > end) (start, end) = (end, start);
    final finder = _NodeFinder(start, end);
    toMarkup(serializer: finder);
    return finder.nodes;
  }

  (String, int, int) toMarkupLocating(OrgNode node) {
    final serializer = _NodeLocatingSeralizer(node);
    final text = toMarkup(serializer: serializer);
    return (text, serializer.start, serializer.end);
  }
}

class _NodeFinder extends OrgSerializer {
  _NodeFinder(this.start, this.end) : assert(start <= end);

  final int start;
  final int end;
  int i = 0;
  final nodes = <OrgNode>[];

  @override
  void visit(OrgNode node) {
    if (i > end) return;
    super.visit(node);
    if (i > start || i > end) {
      nodes.add(node);
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
