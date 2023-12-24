import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class _NicelyTimedBanner extends StatefulWidget {
  const _NicelyTimedBanner({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_NicelyTimedBanner> createState() => _NicelyTimedBannerState();
}

class _NicelyTimedBannerState extends State<_NicelyTimedBanner> {
  bool _ready = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation != null && animation.status != AnimationStatus.completed) {
      _ready = false;
      animation.addStatusListener(_onRouteAnimationStatusChanged);
    }
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _ready = true);
      final route = ModalRoute.of(context);
      route!.animation?.removeStatusListener(_onRouteAnimationStatusChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) =>
          SizeTransition(sizeFactor: animation, child: child),
      child: _ready && widget.visible ? widget.child : const SizedBox.shrink(),
    );
  }
}

class RemoteImagePermissionsBanner extends StatelessWidget {
  const RemoteImagePermissionsBanner({
    required this.visible,
    required this.onResult,
    super.key,
  });

  final void Function(RemoteImagesPolicy, {bool persist}) onResult;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return _NicelyTimedBanner(
      visible: visible,
      child: MaterialBanner(
        content: Text(
          AppLocalizations.of(context)!.bannerBodyRemoteImages,
        ),
        leading: const Icon(Icons.photo),
        actions: [
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionShowAlways,
            onPressed: () => onResult(RemoteImagesPolicy.allow, persist: true),
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionShowNever,
            onPressed: () => onResult(RemoteImagesPolicy.deny, persist: true),
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionShowOnce,
            onPressed: () => onResult(RemoteImagesPolicy.allow, persist: false),
          ),
        ],
      ),
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
    return _NicelyTimedBanner(
      visible: visible,
      child: MaterialBanner(
        content: Text(
          AppLocalizations.of(context)!.bannerBodyRelativeLinks,
        ),
        leading: const Icon(Icons.photo),
        actions: [
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionGrantNotNow,
            onPressed: onDismiss,
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionGrantNever,
            onPressed: onForbid,
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionGrantNow,
            onPressed: onAllow,
          ),
        ],
      ),
    );
  }
}

class SavePermissionsBanner extends StatelessWidget {
  const SavePermissionsBanner({
    required this.visible,
    required this.onResult,
    super.key,
  });

  final void Function(SaveChangesPolicy, {required bool persist}) onResult;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return _NicelyTimedBanner(
      visible: visible,
      child: MaterialBanner(
        content: OrgText(
          AppLocalizations.of(context)!.bannerBodySaveDocumentOrg,
          onLinkTap: (link) => launchUrl(
            Uri.parse(link.location),
            mode: LaunchMode.externalApplication,
          ),
        ),
        leading: const Icon(Icons.save),
        actions: [
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionSaveAlways,
            onPressed: () => onResult(SaveChangesPolicy.allow, persist: true),
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionSaveNever,
            onPressed: () => onResult(SaveChangesPolicy.deny, persist: true),
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionSaveOnce,
            onPressed: () => onResult(SaveChangesPolicy.allow, persist: false),
          ),
        ],
      ),
    );
  }
}

class DecryptContentBanner extends StatelessWidget {
  const DecryptContentBanner({
    required this.visible,
    required this.onAccept,
    required this.onDeny,
    super.key,
  });

  final VoidCallback onAccept;
  final void Function(DecryptPolicy, {required bool persist}) onDeny;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return _NicelyTimedBanner(
      visible: visible,
      child: MaterialBanner(
        content: Text(AppLocalizations.of(context)!.bannerBodyDecryptContent),
        leading: const Icon(Icons.lock),
        actions: [
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionDecryptNow,
            onPressed: onAccept,
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionDecryptNever,
            onPressed: () => onDeny(DecryptPolicy.deny, persist: true),
          ),
          _BannerButton(
            text: AppLocalizations.of(context)!.bannerBodyActionDecryptNotNow,
            onPressed: () => onDeny(DecryptPolicy.deny, persist: false),
          ),
        ],
      ),
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
