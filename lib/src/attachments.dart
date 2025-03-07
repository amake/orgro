import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/util.dart';

OrgFileLink convertLinkResolvingAttachments(
  BuildContext context,
  OrgTree tree,
  OrgLink link,
) {
  final parsed = OrgFileLink.parse(link.location);
  if (parsed.scheme != 'attachment:') return parsed;
  var relativePath = parsed.body;
  final section = tree.findContainingTree(link)!;
  switch (section.attachDir) {
    case (type: OrgAttachDirType.id, :final dir):
      final idDir = OrgSettings.of(context).settings.orgAttachIdDir;
      relativePath = idDir.joinPath(dir).joinPath(relativePath);
      break;
    case (type: OrgAttachDirType.dir, :final dir):
      relativePath = dir.joinPath(relativePath);
      break;
  }
  return parsed.copyWith(scheme: 'file:', body: relativePath);
}
