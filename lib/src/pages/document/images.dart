import 'package:flutter/material.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/components/image.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/pages/document/document.dart';
import 'package:orgro/src/preferences.dart';

extension ImageHandler on DocumentPageState {
  Widget? loadImage(OrgLink link) {
    if (looksLikeUrl(link.location)) {
      return _loadRemoteImage(link);
    }
    final doc = DocumentProvider.of(context).doc;
    try {
      final fileLink = convertLinkResolvingAttachments(doc, link);
      if (fileLink.isRelative) {
        return _loadLocalImage(link, fileLink);
      }
    } on Exception {
      // Not a file link
    }
    // Absolute paths, and...?
    return null;
  }

  Widget? _loadRemoteImage(OrgLink link) {
    assert(looksLikeUrl(link.location));
    final viewSettings = ViewSettings.of(context);
    if (viewSettings.remoteImagesPolicy != RemoteImagesPolicy.allow) {
      return null;
    }
    return RemoteImage(link);
  }

  Widget? _loadLocalImage(OrgLink link, OrgFileLink fileLink) {
    final source = DocumentProvider.of(context).dataSource;
    if (source.needsToResolveParent) {
      return null;
    }
    return LocalImage(
      link: link,
      dataSource: source,
      relativePath: fileLink.body,
    );
  }
}
