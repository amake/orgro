import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteImagePermissionsBanner extends StatelessWidget {
  const RemoteImagePermissionsBanner({
    required this.visible,
    required this.onResult,
    super.key,
  });

  final Function(RemoteImagesPolicy, {bool persist}) onResult;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: visible
          ? MaterialBanner(
              content: Text(
                AppLocalizations.of(context)!.bannerBodyRemoteImages,
              ),
              leading: const Icon(Icons.photo),
              actions: [
                _BannerButton(
                  text:
                      AppLocalizations.of(context)!.bannerBodyActionShowAlways,
                  onPressed: () =>
                      onResult(RemoteImagesPolicy.allow, persist: true),
                ),
                _BannerButton(
                  text: AppLocalizations.of(context)!.bannerBodyActionShowNever,
                  onPressed: () =>
                      onResult(RemoteImagesPolicy.deny, persist: true),
                ),
                _BannerButton(
                  text: AppLocalizations.of(context)!.bannerBodyActionShowOnce,
                  onPressed: () =>
                      onResult(RemoteImagesPolicy.allow, persist: false),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class DirectoryPermissionsBanner extends StatelessWidget {
  const DirectoryPermissionsBanner({
    required this.visible,
    required this.onDismiss,
    required this.onForbid,
    required this.onAllow,
    super.key,
  });

  final VoidCallback onDismiss;
  final VoidCallback onForbid;
  final VoidCallback onAllow;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: visible
          ? MaterialBanner(
              content: Text(
                AppLocalizations.of(context)!.bannerBodyRelativeLinks,
              ),
              leading: const Icon(Icons.photo),
              actions: [
                _BannerButton(
                  text:
                      AppLocalizations.of(context)!.bannerBodyActionGrantNotNow,
                  onPressed: onDismiss,
                ),
                _BannerButton(
                  text:
                      AppLocalizations.of(context)!.bannerBodyActionGrantNever,
                  onPressed: onForbid,
                ),
                _BannerButton(
                  text: AppLocalizations.of(context)!.bannerBodyActionGrantNow,
                  onPressed: onAllow,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class SavePermissionsBanner extends StatelessWidget {
  const SavePermissionsBanner({
    required this.visible,
    required this.onResult,
    super.key,
  });

  final Function(SaveChangesPolicy, {required bool persist}) onResult;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: visible
          ? MaterialBanner(
              content: OrgText(
                AppLocalizations.of(context)!.bannerBodySaveDocumentOrg,
                onLinkTap: (link) => launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              leading: const Icon(Icons.save),
              actions: [
                _BannerButton(
                  text:
                      AppLocalizations.of(context)!.bannerBodyActionSaveAlways,
                  onPressed: () =>
                      onResult(SaveChangesPolicy.allow, persist: true),
                ),
                _BannerButton(
                  text: AppLocalizations.of(context)!.bannerBodyActionSaveNever,
                  onPressed: () =>
                      onResult(SaveChangesPolicy.deny, persist: true),
                ),
                _BannerButton(
                  text: AppLocalizations.of(context)!.bannerBodyActionSaveOnce,
                  onPressed: () =>
                      onResult(SaveChangesPolicy.allow, persist: false),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({required this.text, required this.onPressed});

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary),
      onPressed: onPressed,
      child: Text(text.toUpperCase()),
    );
  }
}
