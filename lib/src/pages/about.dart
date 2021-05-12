import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const orgroVersion =
    String.fromEnvironment('ORGRO_VERSION', defaultValue: 'dev');

void openAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Orgro',
    applicationVersion: orgroVersion,
    applicationIcon: const Padding(
      padding: EdgeInsets.all(8),
      child: _AppIcon(),
    ),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AboutItem(
            label: 'Support · Feedback',
            onPressed: visitSupportLink,
          ),
          _AboutItem(
            label: 'Changelog',
            onPressed: visitChangelogLink,
          ),
        ],
      ),
    ],
  );
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Image.asset(
        'assets/manual/orgro-icon.png',
        scale: MediaQuery.of(context).devicePixelRatio,
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.label,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      label: Text(label.toUpperCase()),
      icon: const Icon(Icons.open_in_new),
    );
  }
}

void visitSupportLink() => launch(
      'https://github.com/amake/orgro/issues',
      forceSafariVC: false,
    );

void visitChangelogLink() => launch(
      'https://orgro.org/changelog/',
      forceSafariVC: false,
    );
