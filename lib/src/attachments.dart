import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/util.dart';

OrgFileLink convertLinkResolvingAttachments(OrgTree tree, OrgLink link) {
  final parsed = OrgFileLink.parse(link.location);
  if (parsed.scheme != 'attachment:') return parsed;
  var relativePath = parsed.body;
  final section = tree.findContainingTree(link)!;
  final attachDir = section.attachDir;
  if (attachDir != null) {
    relativePath = joinPath(attachDir, relativePath);
  }
  return parsed.copyWith(scheme: 'file:', body: relativePath);
}
