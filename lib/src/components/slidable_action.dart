import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ResponsiveSlidableAction extends StatelessWidget {
  const ResponsiveSlidableAction({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        this.backgroundColor ?? Theme.of(context).colorScheme.secondary;
    final foregroundColor =
        this.foregroundColor ?? Theme.of(context).colorScheme.onSecondary;
    return Expanded(
      child: SizedBox.expand(
        child: OutlinedButton(
          onPressed: () {
            onPressed();
            Slidable.of(context)?.close();
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledForegroundColor: backgroundColor.withAlpha(
              (0.38 * 255).round(),
            ),
            foregroundColor: foregroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            side: BorderSide.none,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final short =
                  constraints.maxHeight < IconTheme.of(context).size! * 2;
              final veryTall =
                  !short &&
                  constraints.maxHeight > MediaQuery.sizeOf(context).height / 2;
              final children = [
                if (veryTall) const SizedBox(height: 32),
                Icon(icon),
                const SizedBox(height: 4, width: 4),
                Text(label),
              ];
              return short
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children,
                  )
                  : Column(
                    mainAxisAlignment:
                        veryTall
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                    children: children,
                  );
            },
          ),
        ),
      ),
    );
  }
}
