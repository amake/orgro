import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/editor/util.dart';
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
  final attachRelPath = getAttachmentRelativePath(context, section);
  if (attachRelPath != null) {
    relativePath = attachRelPath.joinPath(relativePath);
  }
  return parsed.copyWith(scheme: 'file:', body: relativePath);
}

String? getAttachmentRelativePath(BuildContext context, OrgTree section) {
  switch (section.attachDir) {
    case (type: OrgAttachDirType.id, :final dir):
      final idDir = OrgSettings.of(context).settings.orgAttachIdDir;
      return idDir.joinPath(dir);
    case (type: OrgAttachDirType.dir, :final dir):
      return dir;
  }
  return null;
}

/// Note that if the offset is at the very end of the document, it will not be
/// considered to be within the last section, and thus may not resolve
/// attachments correctly.
String? getAttachmentRelativePathAtOffset(
  BuildContext context,
  OrgTree doc,
  int offset,
) {
  final found = doc.nodesAtOffset(offset);
  final enclosingTree =
      found.where((e) => e.node is OrgTree).firstOrNull?.node as OrgTree?;
  if (enclosingTree == null) return null;
  return getAttachmentRelativePath(context, enclosingTree);
}
