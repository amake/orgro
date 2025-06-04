import 'package:flutter/widgets.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/assets.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/pages/start/util.dart';
import 'package:quick_actions/quick_actions.dart' as qa;

class QuickAction {
  static const newDocument = 'new_document';
}

class QuickActions extends StatefulWidget {
  const QuickActions({required this.child, super.key});

  final Widget child;

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  late final qa.QuickActions _quickActions;

  @override
  void initState() {
    super.initState();
    _quickActions = qa.QuickActions();
    _quickActions.initialize((shortcutType) async {
      debugPrint('Received shortcut: $shortcutType');
      switch (shortcutType) {
        case QuickAction.newDocument:
          await loadAndRememberAsset(
            context,
            LocalAssets.scratch,
            mode: InitialMode.edit,
          );
          break;
        default:
          break;
      }
    });
  }

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _quickActions.setShortcutItems(<qa.ShortcutItem>[
      qa.ShortcutItem(
        type: QuickAction.newDocument,
        localizedTitle: AppLocalizations.of(context)!.quickActionNewDocument,
        icon: QuickAction.newDocument,
      ),
    ]);
    _inited = true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
