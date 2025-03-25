import 'package:org_flutter/org_flutter.dart';

extension OrgTreeEditing on OrgTree {
  List<OrgNode> nodesAtOffset(int offset) {
    final finder = _OffsetFinder(offset);
    toMarkup(serializer: finder);
    return finder.nodes;
  }
}

class _OffsetFinder extends OrgSerializer {
  _OffsetFinder(this.goal);

  final int goal;
  int i = 0;
  final nodes = <OrgNode>[];

  @override
  void visit(OrgNode node) {
    if (i > goal) return;
    super.visit(node);
    if (i > goal) {
      nodes.add(node);
    }
  }

  @override
  void write(String str) {
    i += str.length;
  }
}
