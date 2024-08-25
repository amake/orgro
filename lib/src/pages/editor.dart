import 'package:flutter/material.dart';
import 'package:orgro/src/components/bottom.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/view_settings.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    required this.text,
    required this.title,
    super.key,
  });

  final String text;
  final String title;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  String? _after;
  bool get _dirty => _after != null && _after != widget.text;

  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
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
            IconButton(
              onPressed: () => Navigator.pop(context, _after),
              icon: const Icon(Icons.check),
            )
          ],
        ),
        body: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          onChanged: (val) => setState(() => _after = val),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(8),
          ),
          style: ViewSettings.of(context).textStyle,
        ),
        bottomSheet: ListenableBuilder(
          listenable: _focusNode,
          builder: (context, child) =>
              _focusNode.hasFocus ? child! : const SizedBox.shrink(),
          child: BottomInputBar(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _wrapSelection('*', '*'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _wrapSelection('/', '/'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underline),
                      onPressed: () => _wrapSelection('_', '_'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_strikethrough),
                      onPressed: () => _wrapSelection('+', '+'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.code),
                      onPressed: () => _wrapSelection('~', '~'),
                    ),
                    // TODO(aaron): Offer more quick-insert actions?
                    // - Lists
                    // - Code blocks
                    // - Sections
                    IconButton(
                      icon: const Icon(Icons.link),
                      // TODO(aaron): Make this nicer?
                      // - Detect whether selection is URL or description?
                      // - Somehow check clipboard?
                      onPressed: () => _wrapSelection('[[', '][description]]'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final value = _controller.value;
    final selection = value.selection.textInside(value.text);
    final replacement = '$prefix$selection$suffix';
    _controller.value = value.replaced(value.selection, replacement).copyWith(
          selection: TextSelection.collapsed(
            offset:
                value.selection.baseOffset + replacement.length - suffix.length,
          ),
        );
    ContextMenuController.removeAny();
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
}
