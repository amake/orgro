import 'package:flutter/widgets.dart';

class AppLifecycle extends StatefulWidget {
  const AppLifecycle({
    super.key,
    required this.onStateChange,
    required this.child,
  });

  final void Function(AppLifecycleState state) onStateChange;
  final Widget child;

  @override
  State<AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends State<AppLifecycle> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) => widget.onStateChange(state),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _lifecycleListener.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
