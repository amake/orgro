import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/restoration.dart';
import 'package:orgro/src/timestamps.dart';
import 'package:orgro/src/util.dart';

const _kRestoreAfterTextKey = 'restore_after_text';

class EditorPage extends StatefulWidget {
  const EditorPage({
    required this.docId,
    required this.text,
    required this.title,
    required this.requestFocus,
    super.key,
  });

  final String docId;
  final String text;
  final String title;
  final bool requestFocus;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with RestorationMixin {
  @override
  String get restorationId => 'editor_page';

  String? _after;
  bool get _dirty => _after != null && _after != widget.text;

  late FullyRestorableTextEditingController _controller;
  late UndoHistoryController _undoController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = FullyRestorableTextEditingController(text: widget.text)
      ..addListener(() {
        if (_controller.value.text != _after) {
          setState(() {
            _after = _controller.value.text;
            bucket?.write(_kRestoreAfterTextKey, _after);
          });
        }
      });
    _undoController = UndoHistoryController();
    if (widget.requestFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'controller');

    if (!initialRestore) return;
    _after = bucket?.read<String>(_kRestoreAfterTextKey);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _undoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(onPressed: _save, icon: const Icon(Icons.check)),
          ],
        ),
        body: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: _controller.value,
                undoController: _undoController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                style:
                    ViewSettings.of(context).forScope(widget.docId).textStyle,
                contextMenuBuilder: nativeWhenPossibleContextMenuBuilder,
              ),
            ),
            _EditorToolbar(
              controller: _controller.value,
              undoController: _undoController,
              enabled: _controller.value.selection.isValid,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop) return;

    final navigator = Navigator.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DiscardChangesDialog(),
    );
    if (result == true) navigator.pop();
  }

  void _save() {
    final result = _dirty ? _after?.withTrailingLineBreak() : null;
    Navigator.pop(context, result);
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.controller,
    required this.undoController,
    required this.enabled,
  });

  final TextEditingController controller;
  final UndoHistoryController undoController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ValueListenableBuilder(
              valueListenable: undoController,
              builder:
                  (context, value, _) => IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed:
                        enabled && value.canUndo ? undoController.undo : null,
                  ),
            ),
            ValueListenableBuilder(
              valueListenable: undoController,
              builder:
                  (context, value, _) => IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed:
                        enabled && value.canRedo ? undoController.redo : null,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: enabled ? () => _wrapSelection('*', '*') : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: enabled ? () => _wrapSelection('/', '/') : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: enabled ? () => _wrapSelection('_', '_') : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: enabled ? () => _wrapSelection('+', '+') : null,
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: enabled ? () => _wrapSelection('~', '~') : null,
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: enabled ? _insertLink : null,
            ),
            IconButton(
              icon: const Icon(Icons.check_box),
              onPressed: enabled ? _insertCheckbox : null,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: enabled ? () => _insertDate(context) : null,
            ),
            IconButton(
              icon: const Icon(Icons.subscript),
              onPressed: enabled ? () => _wrapSelection('_{', '}') : null,
            ),
            IconButton(
              icon: const Icon(Icons.superscript),
              onPressed: enabled ? () => _wrapSelection('^{', '}') : null,
            ),
            // TODO(aaron): Offer more quick-insert actions?
            // - Lists
            // - Code blocks
            // - Sections
          ],
        ),
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final value = controller.value;
    if (!value.selection.isValid) return;
    final selection = value.selection.textInside(value.text);
    final replacement = '$prefix$selection$suffix';
    controller.value = value
        .replaced(value.selection, replacement)
        .copyWith(
          selection: TextSelection.collapsed(
            offset:
                value.selection.baseOffset + replacement.length - suffix.length,
          ),
        );
    ContextMenuController.removeAny();
  }

  void _insertLink() async {
    final value = controller.value;
    if (!value.selection.isValid) return;
    final selection = value.selection.textInside(value.text);
    final url =
        _tryParseUrl(selection) ??
        (await Clipboard.hasStrings()
            ? _tryParseUrl(
              (await Clipboard.getData(Clipboard.kTextPlain))?.text,
            )
            : null);
    final description = url == null ? selection : null;
    final replacement = '[[${url ?? 'URL'}][${description ?? 'description'}]]';
    controller.value = value
        .replaced(value.selection, replacement)
        .copyWith(
          selection: TextSelection.collapsed(
            offset: value.selection.baseOffset + replacement.length - 2,
          ),
        );
    ContextMenuController.removeAny();
  }

  void _insertDate(BuildContext context) async {
    final value = controller.value;
    if (!value.selection.isValid) return;
    final date = await showDatePicker(
      context: context,
      firstDate: kDatePickerFirstDate,
      lastDate: kDatePickerLastDate,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    final replacement =
        OrgSimpleTimestamp(
          '[',
          date.toOrgDate(),
          time?.toOrgTime(),
          [],
          ']',
        ).toMarkup();
    controller.value = value
        .replaced(value.selection, replacement)
        .copyWith(
          selection: TextSelection.collapsed(
            offset: value.selection.baseOffset + replacement.length - 1,
          ),
        );
    ContextMenuController.removeAny();
  }

  void _insertCheckbox() {
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    // Handle single cursor position
    if (selection.isCollapsed) {
      int pos = selection.baseOffset;
      int start = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0) + 1;
      if (start < 0) start = 0;
      int end = text.indexOf('\n', pos);
      if (end < 0) end = text.length;

      List<String> lines = text.split('\n');
      int lineIndex = text.substring(0, start).split('\n').length - 1;
      String currentLine = lines[lineIndex];
      ListItemInfo info = parseListItem(currentLine);
      String indentation = info.indentation;

      String newText;
      int newOffset;

      if (currentLine.trim().isEmpty) {
        // Case 1: Empty line - potentially continue list from previous line
        String newMarker = '-';
        if (lineIndex > 0) {
          ListItemInfo prevInfo = parseListItem(lines[lineIndex - 1]);
          if (indentation == prevInfo.indentation) {
            newMarker = getNextMarker(prevInfo.marker);
          }
        }
        String newLine = '$indentation$newMarker [ ] ';
        newText = text.substring(0, start) + newLine + text.substring(end);
        newOffset = start + newLine.length;
      } else if (info.marker != null) {
        final marker = info.marker!; // Promote marker to String since it's not null
        if (info.checkbox != null) {
          // Case 2: List item with checkbox - insert new item below
          String nextMarker = getNextMarker(marker);
          String newLine = '$indentation$nextMarker [ ] ';
          newText = text.substring(0, end) + '\n$newLine' + text.substring(end);
          newOffset = end + 1 + newLine.length;
        } else {
          // Case 3: List item without checkbox - add checkbox inline
          String newContent = '$indentation$marker [ ] ${info.content.trim()}';
          newText = text.substring(0, start) + newContent + text.substring(end);
          newOffset = start + newContent.length;
        }
      } else {
        // Case 4: Non-list item - convert to list item with checkbox
        String newContent = '$indentation- [ ] ${info.content.trim()}';
        newText = text.substring(0, start) + newContent + text.substring(end);
        newOffset = start + newContent.length;
      }

      // Update the controller with new text and cursor position
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
      // Handle multi-line selection
      int start = selection.start;
      int end = selection.end;
      String rangeText = text.substring(start, end);
      List<String> lines = rangeText.split('\n');
      List<String> transformedLines = [];

      for (String line in lines) {
        ListItemInfo info = parseListItem(line);
        String indentation = info.indentation;
        if (info.marker != null && info.checkbox == null) {
          final marker = info.marker!; // Promote marker to String
          // Add checkbox to list items without one
          String newContent = '$indentation$marker [ ] ${info.content.trim()}';
          transformedLines.add(newContent);
        } else if (info.marker == null) {
          // Convert non-list items to list items with checkbox
          String newContent = '$indentation- [ ] ${info.content.trim()}';
          transformedLines.add(newContent);
        } else {
          // Leave lines with existing checkboxes unchanged
          transformedLines.add(line);
        }
      }

      // Join transformed lines and replace the selected range
      String transformedText = transformedLines.join('\n');
      String newText = text.replaceRange(start, end, transformedText);
      int newOffset = start + transformedText.length;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }

    // Remove any context menu
    ContextMenuController.removeAny();
  }

}

// Helper class to hold list item information
class ListItemInfo {
  final String indentation;
  final String? marker; // e.g., "-", "+", "*", "1.", "1)"
  final String? checkbox; // "[ ]" or "[X]"
  final String content;

  String get markerOrDefault => marker ?? '-';

  ListItemInfo(this.indentation, this.marker, this.checkbox, this.content);
}

// Parse a line into its list item components
ListItemInfo parseListItem(String line) {
  final pattern = RegExp(r'^(\s*)([-\+\*]|\d+[\.\)])?\s*(\[.\])?\s*(.*)$');
  final match = pattern.firstMatch(line);
  if (match != null) {
    String indentation = match.group(1)!;
    String? marker = match.group(2);
    String? checkbox = match.group(3);
    String content = match.group(4)!;
    return ListItemInfo(indentation, marker, checkbox, content);
  }
  return ListItemInfo('', null, null, line);
}

// Generate the next marker for ordered lists
String getNextMarker(String? marker) {
  if (marker == null) return '-';
  final numPattern = RegExp(r'(\d+)([\.\)])');
  final match = numPattern.firstMatch(marker);
  if (match != null) {
    int num = int.parse(match.group(1)!);
    String suffix = match.group(2)!;
    return '${num + 1}$suffix';
  }
  return marker; // Return same marker for unordered lists
}

String? _tryParseUrl(String? str) {
  if (str == null) return null;
  final uri = Uri.tryParse(str);
  if (uri == null) return null;
  // Uri.tryParse is very lenient and will accept lots of things other than what
  // people usually think of as URLs so we filter out anything that doesn't have
  // a scheme.
  if (uri.scheme.isEmpty) return null;
  return str;
}

