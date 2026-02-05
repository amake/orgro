import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/preferences.dart';

class DeveloperAccess extends StatefulWidget {
  const DeveloperAccess({required this.child, super.key});

  final Widget child;

  @override
  State<DeveloperAccess> createState() => _DeveloperAccessState();
}

class _DeveloperAccessState extends State<DeveloperAccess> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (++_taps % 5 == 0) {
          final prefs = Preferences.of(context, PrefsAspect.customization);
          final newMode = !prefs.developerMode;
          await prefs.setDeveloperMode(newMode);
          if (kReleaseMode) {
            debugPrint = newMode ? debugPrintThrottled : debugPrintNoop;
          }
          if (!context.mounted) return;
          showErrorSnackBar(
            context,
            newMode ? 'Developer mode enabled' : 'Developer mode disabled',
          );
        }
      },
      child: widget.child,
    );
  }
}
