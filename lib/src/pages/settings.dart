import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/actions/actions.dart';
import 'package:orgro/src/actions/appearance.dart';
import 'package:orgro/src/agenda.dart';
import 'package:orgro/src/cache.dart';
import 'package:orgro/src/components/list.dart';
import 'package:orgro/src/components/view_settings.dart';
import 'package:orgro/src/entitlements.dart';
import 'package:orgro/src/preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final developerMode = Preferences.of(
      context,
      PrefsAspect.customization,
    ).developerMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsScreenTitle),
      ),
      body: ListView(
        children:
            [
                  if (kFreemium && developerMode) ...[
                    ListHeader(
                      title: Text(
                        AppLocalizations.of(context)!.settingsSectionPurchase,
                      ),
                    ),
                    EntitlementsSettingListItems(),
                    const Divider(),
                  ],
                  if (!kWalledGarden) ...[
                    ListHeader(
                      title: Text(
                        AppLocalizations.of(context)!.settingsSectionDonate,
                      ),
                    ),
                    const DonateSettingListItem(),
                    const Divider(),
                  ],
                  ListHeader(
                    title: Text(
                      AppLocalizations.of(context)!.settingsSectionAppearance,
                    ),
                  ),
                  const AppearanceSettingListItem(),
                  const Divider(),
                  ListHeader(
                    title: Text(
                      AppLocalizations.of(context)!.settingsSectionDefaultText,
                    ),
                  ),
                  const FontFamilySettingListItem(),
                  const TextScaleSettingListItem(),
                  const _TextPreview(),
                  const Divider(),
                  ListHeader(
                    title: Text(
                      AppLocalizations.of(
                        context,
                      )!.settingsSectionNotifications,
                    ),
                  ),
                  const NotificationsListItems(),
                  const Divider(),
                  ListHeader(
                    title: Text(
                      AppLocalizations.of(
                        context,
                      )!.settingsSectionDataManagement,
                    ),
                  ),
                  const ClearCachesListItem(),
                  const ResetDirectoryPermissionsListItem(),
                  const ResetPreferencesListItem(),
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

  Widget _constrain(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: child,
    ),
  );
}

class _TextPreview extends StatefulWidget {
  const _TextPreview();

  @override
  State<_TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<_TextPreview> {
  late final TextEditingController _controller;
  InheritedPreferences get _prefs =>
      Preferences.of(context, PrefsAspect.customization);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onTextChanged);
  }

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inited) {
      _controller.text = _prefs.textPreviewString.isEmpty
          ? kDefaultTextPreviewString
          : _prefs.textPreviewString;
      _inited = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTextChanged() async {
    final current = _prefs.textPreviewString;
    if (_controller.text != current) {
      _prefs.setTextPreviewString(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewSettings = ViewSettings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: TextField(
          controller: _controller,
          style: viewSettings.textStyle,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
          maxLines: null,
        ),
      ),
    );
  }
}
