import 'package:material_ui/material_ui.dart';

// Not sure why this size
const kBiggishScreenMaxWidth = 500.0;

// E.g. iPad mini in portrait (768px), iPhone XS in landscape (812px), Pixel 2
// in landscape (731px)
const kWideScreenMaxWidth = 600.0;

class ConstrainForWideScreen extends StatelessWidget {
  final Widget child;

  const ConstrainForWideScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kWideScreenMaxWidth),
      child: child,
    ),
  );
}
