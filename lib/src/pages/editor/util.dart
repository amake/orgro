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
