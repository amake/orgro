import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pageTitleError),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error),
              const SizedBox(height: 16),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
