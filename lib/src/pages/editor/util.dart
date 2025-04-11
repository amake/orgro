import 'package:org_flutter/org_flutter.dart';

// TODO(aaron): End is truncated by the end of the visited range, which seems
// like it must be surprising for consumers. What to do?
typedef NodeSpan = ({int start, int end});

extension OrgTreeEditing on OrgTree {
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
  final nodes = <({OrgNode node, NodeSpan span})>[];

  @override
  void visit(OrgNode node) {
    if (i > end) return;
    final nodeStart = i;
    super.visit(node);
    if (i > start || i > end) {
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

class Region {
  Region(int start, int end) {
    spans.add((start, end));
  }

  final List<(int, int)> spans = [];

  bool get isEmpty => spans.isEmpty;

  void consume(int start, int end) {
    if (isEmpty) return;
    final newSpans = <(int, int)>[];
    for (final (s, e) in spans) {
      if (start > e || end < s) {
        newSpans.add((s, e));
      } else {
        if (start > s) newSpans.add((s, start));
        if (end < e) newSpans.add((end, e));
      }
    }
    spans.clear();
    spans.addAll(newSpans);
  }
}
