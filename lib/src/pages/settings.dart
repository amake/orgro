import 'package:flutter/material.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/appearance.dart';
import 'package:orgro/src/appearance.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/components/list.dart';
import 'package:orgro/src/components/recent_files.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewSettings = ViewSettings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'), // TODO(aaron): L10N
      ),
      body: ListView(
        children: [
          appearanceListItem(context),
          Divider(),
          ListHeader(title: Text('Default text')), // TODO(aaron): L10N
          fontFamilyListItem(
            context,
            fontFamily: viewSettings.fontFamily,
            onChanged: (value) => viewSettings.fontFamily = value,
          ),
          textScaleListItem(
            context,
            textScale: viewSettings.textScale,
            onChanged: (value) => viewSettings.textScale = value,
          ),
          _TextPreview(),
          Divider(),
          ListHeader(title: Text('Data management')), // TODO(aaron): L10N
          ListTile(
            title: Text('Clear cache'), // TODO(aaron): L10N
            onTap: () async {
              await clearCaches(context);
              if (context.mounted)
                _reportResult(context, 'Cache cleared'); // TODO(aaron): L10N
            },
          ),
          ListTile(
            title: Text('Restore defaults'), // TODO(aaron): L10N
            onTap: () async {
              await resetPreferences(context);
              if (context.mounted) {
                // TODO(aaron): We shouldn't need to manuall reset these things.
                // They should pick up changes to Preferences automatically.
                viewSettings.reload(context);
                Appearance.of(context).reload();
                RecentFiles.of(context).reload();
                _reportResult(
                    context, 'Preferences reset'); // TODO(aaron): L10N
              }
            },
          ),
        ]
            .map(
              (child) => switch (child) {
                Divider() => child,
                _ => _constrain(child),
              },
            )
            .toList(growable: false),
      ),
    );
  }

  void _reportResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _constrain(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      );
}

class _TextPreview extends StatelessWidget {
  const _TextPreview();

  @override
  Widget build(BuildContext context) {
    final viewSettings = ViewSettings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              style: BorderStyle.solid,
              color: Theme.of(context).dividerColor,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: viewSettings.textStyle),
        ),
      ),
    );
  }
}
