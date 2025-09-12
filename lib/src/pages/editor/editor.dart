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

  final _shortcuts = <ShortcutActivator, Intent>{
    LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyW):
        const CloseViewIntent(),
    LogicalKeySet(platformShortcutKey, LogicalKeyboardKey.keyS):
        const SaveChangesIntent(),
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
    const SingleActivator(LogicalKeyboardKey.cut): CopySelectionTextIntent.cut(
      SelectionChangedCause.keyboard,
    ),
    const SingleActivator(LogicalKeyboardKey.paste): PasteTextIntent(
      SelectionChangedCause.keyboard,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: {
            // TODO(aaron): Init these outside of build
            SaveChangesIntent: CallbackAction(onInvoke: (_) => _save()),
            CloseViewIntent: CloseViewAction(),
            MakeBoldIntent: MakeBoldAction(_controller.value),
            MakeItalicIntent: MakeItalicAction(_controller.value),
            MakeUnderlineIntent: MakeUnderlineAction(_controller.value),
            MakeStrikethroughIntent: MakeStrikethroughAction(_controller.value),
            MakeCodeIntent: MakeCodeAction(_controller.value),
            InsertLinkIntent: InsertLinkAction(_controller.value),
            InsertDateIntent: InsertDateAction(_controller.value),
            MakeSubscriptIntent: MakeSubscriptAction(_controller.value),
            MakeSuperscriptIntent: MakeSuperscriptAction(_controller.value),
            ToggleListItemIntent: ToggleListItemAction(_controller.value),
            ScrollToDocumentBoundaryIntent: ScrollToDocumentBoundaryAction(),
          },
          child: FocusScope(
            autofocus: true,
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
                  _EditorToolbar(undoController: _undoController),
                ],
              ),
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
  const _EditorToolbar({required this.undoController});

  final UndoHistoryController undoController;

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
                onPressed: value.canUndo ? undoController.undo : null,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: undoController,
              builder: (context, value, _) => IconButton(
                icon: const Icon(Icons.redo),
                onPressed: value.canRedo ? undoController.redo : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: Actions.handler(
                context,
                const ToggleListItemIntent(ordered: false),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: Actions.handler(
                context,
                const ToggleListItemIntent(ordered: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: Actions.handler(context, const MakeBoldIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: Actions.handler(context, const MakeItalicIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: Actions.handler(context, const MakeUnderlineIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: Actions.handler(
                context,
                const MakeStrikethroughIntent(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: Actions.handler(context, const MakeCodeIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: Actions.handler(context, const InsertLinkIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: Actions.handler(context, const InsertDateIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.subscript),
              onPressed: Actions.handler(context, const MakeSubscriptIntent()),
            ),
            IconButton(
              icon: const Icon(Icons.superscript),
              onPressed: Actions.handler(
                context,
                const MakeSuperscriptIntent(),
              ),
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
