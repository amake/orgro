import 'package:flutter/material.dart';
import 'package:orgro/src/preferences.dart';

class RemoteImagePermissionsBanner extends StatelessWidget {
  const RemoteImagePermissionsBanner({
    required this.visible,
    required this.onResult,
    Key? key,
  }) : super(key: key);

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
              content: const Text(
                'This document contains remote images. Would you like to load them?',
              ),
              leading: const Icon(Icons.photo),
              actions: [
                _BannerButton(
                  text: 'Always',
                  onPressed: () =>
                      onResult(RemoteImagesPolicy.allow, persist: true),
                ),
                _BannerButton(
                  text: 'Never',
                  onPressed: () =>
                      onResult(RemoteImagesPolicy.deny, persist: true),
                ),
                _BannerButton(
                  text: 'Just once',
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
    Key? key,
  }) : super(key: key);

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
              content: const Text(
                'This document contains relative links. Would you like to grant access?',
              ),
              leading: const Icon(Icons.photo),
              actions: [
                _BannerButton(
                  text: 'Not now',
                  onPressed: onDismiss,
                ),
                _BannerButton(
                  text: 'Never',
                  onPressed: onForbid,
                ),
                _BannerButton(
                  text: 'Grant access',
                  onPressed: onAllow,
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({required this.text, required this.onPressed, Key? key})
      : super(key: key);

  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(primary: Theme.of(context).accentColor),
      onPressed: onPressed,
      child: Text(text.toUpperCase()),
    );
  }
}
