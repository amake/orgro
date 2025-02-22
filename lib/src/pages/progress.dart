import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pageTitleLoading),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
