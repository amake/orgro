import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/attachments.dart';
import 'package:orgro/src/components/document_provider.dart';
import 'package:orgro/src/data_source.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/document/links.dart';
import 'package:orgro/src/pages/editor/edits.dart';
import 'package:orgro/src/util.dart';

const _channel = MethodChannel('com.madlonkay.orgro/clipboard');

Future<bool> hasClipboardImageData() async {
  final result = await _channel.invokeMethod<bool>('hasClipboardImageData');
  return result ?? false;
}

Future<List<String>> saveClipboardImages({
  required String dirIdentifier,
  required String? relativePath,
  required String filenamePrefix,
}) async {
  final result = await _channel
      .invokeListMethod<String>('saveClipboardImages', {
        'dirIdentifier': dirIdentifier,
        'relativePath': relativePath,
        'filenamePrefix': filenamePrefix,
      });
  return result ?? [];
}

Future<String?> saveKeyboardImage({
  required String dirIdentifier,
  required String? relativePath,
  required String filenamePrefix,
  required KeyboardInsertedContent content,
}) async {
  return await _channel.invokeMethod<String>('saveKeyboardImage', {
    'dirIdentifier': dirIdentifier,
    'relativePath': relativePath,
    'filenamePrefix': filenamePrefix,
    'mimeType': content.mimeType,
    'uri': content.uri.toString(),
    'data': content.data,
  });
}

class ContextMenuItemsWithImagePaste extends StatefulWidget {
  final EditableTextState editableTextState;
  final TextEditingController controller;

  /// The context of the parent widget that the context menu will be shown for.
  ///
  /// The context menu context apparently does not derive from its parent, so
  /// inheritable widgets above the parent are unavailabe. Further, especially
  /// (it seems) on iOS, the context menu is quickly unmounted, so follow-up
  /// async work that needs to happen after the lifetime of the context menu
  /// will fail (e.g. returning early due to mountedness checks).
  final BuildContext parentContext;

  const ContextMenuItemsWithImagePaste({
    required this.editableTextState,
    required this.controller,
    required this.parentContext,
    super.key,
  });

  @override
  State<ContextMenuItemsWithImagePaste> createState() =>
      _ContextMenuItemsWithImagePasteState();
}

class _ContextMenuItemsWithImagePasteState
    extends State<ContextMenuItemsWithImagePaste> {
  final _hasImageDataFuture = hasClipboardImageData();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasImageDataFuture,
      builder: (context, snapshot) {
        // We don't replace the default paste item because the clipboard can
        // contain both images and text, and not all contexts support pasting
        // images (e.g. the data source is not writable).
        //
        // Example: Long-pressing an image in Safari and choosing "Copy" on iOS
        // copies both the image and its URL.
        final hasImageData = snapshot.data ?? false;
        if (SystemContextMenu.isSupportedByField(widget.editableTextState)) {
          final items = SystemContextMenu.getDefaultItems(
            widget.editableTextState,
          );
          if (hasImageData) {
            items.insertMaybeAfter(
              IOSSystemContextMenuItemCustom(
                title: AppLocalizations.of(
                  context,
                )!.pasteImageContextMenuTitle.toTitleCase(),
                onPressed: _doPaste,
              ),
              where: (item) => item is IOSSystemContextMenuItemPaste,
            );
          }
          return SystemContextMenu.editableText(
            editableTextState: widget.editableTextState,
            items: items,
          );
        }
        final items = widget.editableTextState.contextMenuButtonItems;
        if (hasImageData) {
          items.insertMaybeAfter(
            ContextMenuButtonItem(
              type: ContextMenuButtonType.paste,
              label: AppLocalizations.of(context)!.pasteImageContextMenuTitle,
              onPressed: _doPaste,
            ),
            where: (item) => item.type == ContextMenuButtonType.paste,
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: items,
          anchors: widget.editableTextState.contextMenuAnchors,
        );
      },
    );
  }

  Future<void> _doPaste() async {
    try {
      await pasteImagesFromClipboard(widget.parentContext, widget.controller);
    } catch (e, s) {
      logError(e, s);
      if (widget.parentContext.mounted) {
        showErrorSnackBar(widget.parentContext, e);
      }
    } finally {
      ContextMenuController.removeAny();
    }
  }
}

extension _ListUtil<T> on List<T> {
  void insertMaybeAfter(
    T itemToInsert, {
    required bool Function(T item) where,
  }) {
    final idx = indexWhere(where);
    insert(idx == -1 ? length : idx + 1, itemToInsert);
  }
}

Future<List<String>?> saveImagesFromClipboard(
  BuildContext context,
  String? relativePath,
) async {
  final dataSource = DocumentProvider.of(context).dataSource;
  if (dataSource is! NativeDataSource) {
    debugPrint('Unsupported data source: ${dataSource.runtimeType}');
    showErrorSnackBar(
      context,
      AppLocalizations.of(context)!.errorUnsupportedDataSource(dataSource),
    );
    return null;
  }

  if (dataSource.needsToResolveParent) {
    await _showDirectoryPermissionsSnackBar(context);
    return null;
  }

  final parent = dataSource.parentDirIdentifier;
  if (parent == null) return null;

  final now = DateTime.now().millisecondsSinceEpoch / 1000;
  final filenamePrefix = 'paste_${now.toStringAsFixed(0)}';
  return await saveClipboardImages(
    dirIdentifier: parent,
    relativePath: relativePath,
    filenamePrefix: filenamePrefix,
  );
}

Future<String?> saveImageFromKeyboard(
  BuildContext context,
  KeyboardInsertedContent content,
  String? relativePath,
) async {
  final dataSource = DocumentProvider.of(context).dataSource;
  if (dataSource is! NativeDataSource) {
    debugPrint('Unsupported data source: ${dataSource.runtimeType}');
    showErrorSnackBar(
      context,
      AppLocalizations.of(context)!.errorUnsupportedDataSource(dataSource),
    );
    return null;
  }

  if (dataSource.needsToResolveParent) {
    await _showDirectoryPermissionsSnackBar(context);
    return null;
  }

  final parent = dataSource.parentDirIdentifier;
  if (parent == null) return null;

  final now = DateTime.now().millisecondsSinceEpoch / 1000;
  final filenamePrefix = 'insert_${now.toStringAsFixed(0)}';
  return await saveKeyboardImage(
    dirIdentifier: parent,
    relativePath: relativePath,
    filenamePrefix: filenamePrefix,
    content: content,
  );
}

Future<void> _showDirectoryPermissionsSnackBar(BuildContext context) async {
  // TODO(aaron): We have dropped support for platforms that need this check
  final showAction = await canObtainNativeDirectoryPermissions();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context)!.snackbarMessageNeedsDirectoryPermissions,
      ),
      action: showAction
          ? SnackBarAction(
              label: AppLocalizations.of(
                context,
              )!.snackbarActionGrantAccess.toUpperCase(),
              onPressed: () => doPickDirectory(context),
            )
          : null,
    ),
  );
}

Future<bool> pasteImagesFromClipboard(
  BuildContext context,
  TextEditingController controller,
) async {
  final doc = OrgDocument.parse(controller.value.text);
  var offset = controller.value.selection.baseOffset;
  if (offset > 0 && offset == controller.value.text.length) {
    offset -= 1;
  }
  final attachRelPath = getAttachmentRelativePathAtOffset(context, doc, offset);

  final fileNames = await saveImagesFromClipboard(context, attachRelPath);
  if (fileNames == null) return false;
  if (fileNames.isEmpty) {
    debugPrint('No files were saved from the clipboard');
    if (context.mounted) {
      showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.pasteImageErrorNoFiles,
      );
    }
    return false;
  }
  final value = insertImageLinks(
    controller.value,
    fileNames,
    asAttachment: attachRelPath != null,
  );
  if (value == null) return false;
  controller.value = value;
  return true;
}

Future<bool> pasteImagesFromKeyboard(
  BuildContext context,
  KeyboardInsertedContent content,
  TextEditingController controller,
) async {
  final doc = OrgDocument.parse(controller.value.text);
  var offset = controller.value.selection.baseOffset;
  if (offset > 0 && offset == controller.value.text.length) {
    offset -= 1;
  }
  final attachRelPath = getAttachmentRelativePathAtOffset(context, doc, offset);
  final fileName = await saveImageFromKeyboard(context, content, attachRelPath);
  if (fileName == null) return false;
  final value = insertImageLinks(controller.value, [
    fileName,
  ], asAttachment: attachRelPath != null);
  if (value == null) return false;
  controller.value = value;
  return true;
}
