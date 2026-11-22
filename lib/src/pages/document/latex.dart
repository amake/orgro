import 'package:flutter_tex_js/flutter_tex_js.dart';
import 'package:material_ui/material_ui.dart';
import 'package:org_flutter/org_flutter.dart';

/// An inline LaTeX fragment such as `\(a^2\)`
InlineSpan? loadLatexInline(OrgLatexInline latex) {
  return WidgetSpan(
    alignment: .middle,
    child: TexImage(
      latex.content,
      displayMode: false,
      error: (context, error) {
        debugPrint(error.toString());
        return Text(latex.toMarkup());
      },
    ),
  );
}

/// A LaTeX block such as `\begin{equation}...\end{equation}`
Widget? loadLatexBlock(OrgLatexBlock block) {
  return TexImage(
    flutterTexJsSupportedEnvironments.contains(block.environment)
        ? '${block.begin}${block.content}${block.end}'
        : block.content,
    displayMode: true,
    error: (context, error) {
      debugPrint(error.toString());
      return Text(block.toMarkup());
    },
  );
}
