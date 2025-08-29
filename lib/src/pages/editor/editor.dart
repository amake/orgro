import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orgro/src/actions/common.dart';
import 'package:orgro/src/actions/scroll.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/pages/editor/actions.dart';
import 'package:orgro/src/restoration.dart';
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
  late TextStyle _textStyle;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textStyle = ViewSettings.of(context).forScope(widget.docId).textStyle;
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
        body: Shortcuts(
          shortcuts: {
            LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyS):
                const SaveChangesIntent(),
            LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW):
                const CloseViewIntent(),
            const SingleActivator(LogicalKeyboardKey.escape):
                const CloseViewIntent(),
            LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyB):
                const MakeBoldIntent(),
            LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyI):
                const MakeItalicIntent(),
            LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyU):
                const MakeUnderlineIntent(),
            // TODO(aaron): These are already set by default in
            // DefaultTextEditingShortcuts so it seems like we shouldn't need
            // them here, but they didn't seem to work otherwise.
            const SingleActivator(LogicalKeyboardKey.end):
                const ScrollToDocumentBoundaryIntent(forward: true),
            const SingleActivator(LogicalKeyboardKey.home):
                const ScrollToDocumentBoundaryIntent(forward: false),
            // TODO(aaron): Test these. I don't have a keyboard with these keys.
            const SingleActivator(LogicalKeyboardKey.copy):
                CopySelectionTextIntent.copy,
            const SingleActivator(LogicalKeyboardKey.cut):
                CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
            const SingleActivator(LogicalKeyboardKey.paste): PasteTextIntent(
              SelectionChangedCause.keyboard,
            ),
          },
          child: Actions(
            actions: {
              SaveChangesIntent: CallbackAction(onInvoke: (_) => _save()),
              CloseViewIntent: CloseViewAction(),
              MakeBoldIntent: MakeBoldAction(_controller.value),
              MakeItalicIntent: MakeItalicAction(_controller.value),
              MakeUnderlineIntent: MakeUnderlineAction(_controller.value),
              MakeStrikethroughIntent: MakeStrikethroughAction(
                _controller.value,
              ),
              MakeCodeIntent: MakeCodeAction(_controller.value),
              InsertLinkIntent: InsertLinkAction(_controller.value),
              InsertDateIntent: InsertDateAction(_controller.value),
              MakeSubscriptIntent: MakeSubscriptAction(_controller.value),
              MakeSuperscriptIntent: MakeSuperscriptAction(_controller.value),
              ScrollToDocumentBoundaryIntent: ScrollToDocumentBoundaryAction(),
            },
            child: Column(
              // mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller.value,
                    undoController: _undoController,
                    scrollController: PrimaryScrollController.of(context),
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    style: _textStyle,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).highlightColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ValueListenableBuilder(
              valueListenable: undoController,
              builder: (context, value, _) => IconButton(
                icon: const Icon(Icons.undo),
                onPressed: enabled && value.canUndo
                    ? undoController.undo
                    : null,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: undoController,
              builder: (context, value, _) => IconButton(
                icon: const Icon(Icons.redo),
                onPressed: enabled && value.canRedo
                    ? undoController.redo
                    : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: enabled
                  ? Actions.handler(context, const MakeBoldIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: enabled
                  ? Actions.handler(context, const MakeItalicIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: enabled
                  ? Actions.handler(context, const MakeUnderlineIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: enabled
                  ? Actions.handler(context, const MakeStrikethroughIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: enabled
                  ? Actions.handler(context, const MakeCodeIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: enabled
                  ? Actions.handler(context, const InsertLinkIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: enabled
                  ? Actions.handler(context, const InsertDateIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.subscript),
              onPressed: enabled
                  ? Actions.handler(context, const MakeSubscriptIntent())
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.superscript),
              onPressed: enabled
                  ? Actions.handler(context, const MakeSuperscriptIntent())
                  : null,
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
}
