import 'package:flutter/widgets.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:orgro/src/util.dart';
import 'package:quick_actions/quick_actions.dart' as qa;

enum QuickAction { newDocument, topPin }

class QuickActions extends StatefulWidget {
  const QuickActions({required this.child, super.key});

  final Widget child;

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  late final qa.QuickActions _quickActions;

  DateTime? _lastInvoked;

  // TODO(aaron): Remove this workaround pending fix of
  // https://github.com/flutter/flutter/issues/131121
  bool get _shouldThrottle {
    if (_lastInvoked == null) return false;
    final now = DateTime.now();
    final diff = now.difference(_lastInvoked!);
    return diff < const Duration(seconds: 1);
  }

  @override
  void initState() {
    super.initState();
    _quickActions = qa.QuickActions();
    _quickActions.initialize((shortcutType) {
      _handleQuickAction(QuickAction.values.byName(shortcutType));
    });
  }

  Future<void> _handleQuickAction(QuickAction action) async {
    if (_shouldThrottle) return;
    _lastInvoked = DateTime.now();
    debugPrint('Received shortcut: $action');
    switch (action) {
      case QuickAction.newDocument:
        await loadAndRememberAsset(
          context,
          LocalAssets.scratch,
          mode: InitialMode.edit,
        );
        break;
      case QuickAction.topPin:
        final pin = RememberedFiles.of(context).pinned.firstOrNull;
        if (pin != null) {
          await loadAndRememberFile(
            context,
            readFileWithIdentifier(pin.identifier),
          );
        }
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pin = RememberedFiles.of(context).pinned.firstOrNull;
    _quickActions.setShortcutItems(<qa.ShortcutItem>[
      qa.ShortcutItem(
        type: QuickAction.newDocument.name,
        localizedTitle: AppLocalizations.of(context)!.quickActionNewDocument,
        icon: QuickAction.newDocument.name.toSnakeCase(),
      ),
      if (pin != null)
        qa.ShortcutItem(
          type: QuickAction.topPin.name,
          localizedTitle: AppLocalizations.of(
            context,
          )!.quickActionTopPin(pin.name),
          icon: QuickAction.topPin.name.toSnakeCase(),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
