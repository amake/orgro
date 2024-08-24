import 'package:flutter/material.dart';
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
        body: PlainTextEditor(
          text: widget.text,
          onChanged: (val) => setState(() => _after = val),
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
}

class PlainTextEditor extends StatefulWidget {
  const PlainTextEditor({
    required this.text,
    required this.onChanged,
    super.key,
  });

  final String text;
  final void Function(String) onChanged;

  @override
  State<PlainTextEditor> createState() => _PlainTextEditorState();
}

class _PlainTextEditorState extends State<PlainTextEditor> {
  late TextEditingController _controller;

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
    return TextField(
      controller: _controller,
      maxLines: null,
      expands: true,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(8),
      ),
      style: ViewSettings.of(context).textStyle,
    );
  }
}
