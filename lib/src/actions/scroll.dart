import 'package:material_ui/material_ui.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/actions/util.dart';

class ScrollToDocumentBoundaryAction
    extends ContextAction<ScrollToDocumentBoundaryIntent> {
  @override
  void invoke(
    covariant ScrollToDocumentBoundaryIntent intent, [
    BuildContext? context,
  ]) {
    if (context != null) {
      if (intent.forward) {
        scrollToBottom(context);
      } else {
        _scrollToTop(context);
      }
    }
  }
}

void _scrollTo(ScrollController controller, double position) =>
    controller.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );

void _scrollToTop(BuildContext context) {
  final controller = PrimaryScrollController.of(context);
  _scrollTo(controller, controller.position.minScrollExtent);
}

void scrollToBottom(BuildContext context) {
  final controller = PrimaryScrollController.of(context);
  _scrollTo(controller, controller.position.maxScrollExtent);
}

class ScrollTopButton extends StatelessWidget {
  const ScrollTopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.tooltipScrollTop,
      icon: const Icon(Icons.keyboard_arrow_up),
      onPressed: ActionsUtil.handler(
        context,
        const ScrollToDocumentBoundaryIntent(forward: false),
      ),
    );
  }
}

PopupMenuItem<VoidCallback> scrollTopMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: ActionsUtil.handler(
      context,
      ScrollToDocumentBoundaryIntent(forward: false),
    ),
    child: Text(AppLocalizations.of(context)!.menuItemScrollTop),
  );
}

class ScrollBottomButton extends StatelessWidget {
  const ScrollBottomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.tooltipScrollBottom,
      icon: const Icon(Icons.keyboard_arrow_down),
      onPressed: ActionsUtil.handler(
        context,
        const ScrollToDocumentBoundaryIntent(forward: true),
      ),
    );
  }
}

PopupMenuItem<VoidCallback> scrollBottomMenuItem(BuildContext context) {
  return PopupMenuItem<VoidCallback>(
    value: ActionsUtil.handler(
      context,
      ScrollToDocumentBoundaryIntent(forward: true),
    ),
    child: Text(AppLocalizations.of(context)!.menuItemScrollBottom),
  );
}
