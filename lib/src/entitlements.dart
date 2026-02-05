import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/app_purchase.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

const kWalledGarden = bool.fromEnvironment(
  'ORGRO_WALLED_GARDEN',
  defaultValue: false,
);

// Google Play doesn't have a good way to record legacy purchases, so it will
// stay paid up front.
final kFreemium = kWalledGarden && Platform.isIOS;

// The last app version that was paid (non-freemium). This is the version code
// (not the version "name") because that's what iOS's AppTransaction API
// returns: CFBundleVersion which is $(FLUTTER_BUILD_NUMBER).
const kLastPaidVersion = 214;

const _orgroUnlockProductId = 'orgro_unlock_1';

const _trialPeriod = Duration(days: 7);

class UserEntitlements extends StatefulWidget {
  static InheritedEntitlements? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedEntitlements>();

  const UserEntitlements({required this.child, super.key});

  final Widget child;

  @override
  State<UserEntitlements> createState() => _UserEntitlementsState();
}

class _UserEntitlementsState extends State<UserEntitlements> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  var _entitlements = EntitlementsData.empty();

  @override
  void initState() {
    super.initState();
    if (!kFreemium) return;

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (Object e, StackTrace s) {
        logError(e, s);
        if (mounted) showErrorSnackBar(context, e);
      },
    );
    _checkLegacyPurchase(false).onError(logError);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  Future<void> _checkLegacyPurchase(bool refresh) async {
    String? originalAppVersion;
    DateTime? originalPurchaseDate;
    String? environment;
    Object? error;
    AppPurchaseInfo? info;
    AppPurchaseInfoSource? source;
    try {
      (source, info) = await getAppPurchaseInfo(refresh);
      originalAppVersion = info['originalAppVersion'] as String;
      final timestamp = info['originalPurchaseTimestamp'] as double;
      originalPurchaseDate = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
        isUtc: true,
      );
      environment = info['environment'] as String;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      final newEntitlements = _entitlements.copyWith(
        loaded: true,
        originalPurchaseDate: originalPurchaseDate,
        originalAppVersion: originalAppVersion,
        appPurchaseInfoSource: source,
        environment: environment,
        error: error,
      );
      setState(() => _entitlements = newEntitlements);
      if (error == null &&
          source == .native &&
          newEntitlements.legacyPurchase) {
        await cacheAppPurchaseInfo(info!);
      }
    }
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    debugPrint('Purchase update: $purchaseDetailsList');
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
        'Handling purchase: ${purchaseDetails.productID}, ${purchaseDetails.purchaseID}, '
        '${purchaseDetails.status}, ${purchaseDetails.transactionDate}',
      );
      if (purchaseDetails.status == .pending) {
        // TODO(aaron): Show some UI indicating purchase is pending?
      } else {
        if (purchaseDetails.status == .error) {
          logError(purchaseDetails.error, StackTrace.current);
          if (mounted) showErrorSnackBar(context, purchaseDetails.error!);
        } else if (purchaseDetails.status == .purchased ||
            purchaseDetails.status == .restored &&
                purchaseDetails.productID == _orgroUnlockProductId) {
          // We don't have a backend to verify purchases
          setState(() {
            _entitlements = _entitlements.copyWith(
              loaded: true,
              inAppPurchase: true,
            );
          });
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kFreemium) {
      return widget.child;
    }
    return InheritedEntitlements(
      entitlements: _entitlements,
      reload: _checkLegacyPurchase,
      child: widget.child,
    );
  }
}

class InheritedEntitlements extends InheritedWidget {
  const InheritedEntitlements({
    super.key,
    required super.child,
    required this.entitlements,
    required this.reload,
  });

  final EntitlementsData entitlements;
  final Future<void> Function(bool) reload;

  @override
  bool updateShouldNotify(covariant InheritedEntitlements oldWidget) =>
      entitlements != oldWidget.entitlements;
}

class EntitlementsData {
  factory EntitlementsData.empty() => const EntitlementsData(loaded: false);

  const EntitlementsData({
    required this.loaded,
    this.originalPurchaseDate,
    this.originalAppVersion,
    this.appPurchaseInfoSource,
    this.environment,
    this.inAppPurchase,
    this.error,
  });

  final bool loaded;
  final DateTime? originalPurchaseDate;
  final String? originalAppVersion;
  final AppPurchaseInfoSource? appPurchaseInfoSource;
  final String? environment;
  final bool? inAppPurchase;
  final Object? error;

  bool get hasError => error != null;
  bool get sandboxed => environment == 'Sandbox';
  bool get legacyPurchase {
    if (originalAppVersion == null) return false;
    final parsed = int.tryParse(originalAppVersion!);
    if (parsed == null) {
      // iOS sandbox will have '1.0' for the version, which isn't an int so we
      // pass through here.
      return false;
    }
    return parsed <= kLastPaidVersion;
  }

  bool get purchased => legacyPurchase == true || inAppPurchase == true;
  bool get inTrial {
    if (purchased) return false; // Already purchased
    if (hasError) return true; // Avoid locking out on error
    if (sandboxed) return true; // Always in trial in sandbox (if not purchased)
    return originalPurchaseDate != null &&
        DateTime.now().isBefore(originalPurchaseDate!.add(_trialPeriod));
  }

  bool get locked => kFreemium && loaded && !purchased && !inTrial;

  DateTime? get trialEnd => originalPurchaseDate != null
      ? tz.TZDateTime.from(originalPurchaseDate!, tz.local).add(_trialPeriod)
      : null;

  @override
  bool operator ==(Object other) =>
      other is EntitlementsData &&
      other.loaded == loaded &&
      other.originalPurchaseDate == originalPurchaseDate &&
      other.originalAppVersion == originalAppVersion &&
      other.appPurchaseInfoSource == appPurchaseInfoSource &&
      other.environment == environment &&
      other.inAppPurchase == inAppPurchase &&
      other.error == error;

  @override
  int get hashCode => Object.hash(
    loaded,
    originalPurchaseDate,
    originalAppVersion,
    appPurchaseInfoSource,
    environment,
    inAppPurchase,
    error,
  );

  EntitlementsData copyWith({
    bool? loaded,
    DateTime? originalPurchaseDate,
    String? originalAppVersion,
    AppPurchaseInfoSource? appPurchaseInfoSource,
    String? environment,
    bool? inAppPurchase,
    Object? error,
  }) => EntitlementsData(
    loaded: loaded ?? this.loaded,
    originalPurchaseDate: originalPurchaseDate ?? this.originalPurchaseDate,
    originalAppVersion: originalAppVersion ?? this.originalAppVersion,
    appPurchaseInfoSource: appPurchaseInfoSource ?? this.appPurchaseInfoSource,
    environment: environment ?? this.environment,
    inAppPurchase: inAppPurchase ?? this.inAppPurchase,
    error: error ?? this.error,
  );
}

class EntitlementsSettingListItems extends StatefulWidget {
  EntitlementsSettingListItems({super.key})
    : assert(kFreemium, 'Only use this in freemium builds.');

  @override
  State<EntitlementsSettingListItems> createState() =>
      _EntitlementsSettingListItemsState();
}

class _EntitlementsSettingListItemsState
    extends State<EntitlementsSettingListItems>
    with PurchaseHelper {
  void _showDebugInfo(EntitlementsData entitlements) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Purchase info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Loaded: ${entitlements.loaded}'),
              Text('• Purchased: ${entitlements.purchased}'),
              Text('• Environment: ${entitlements.environment}'),
              Text('• Legacy purchase: ${entitlements.legacyPurchase}'),
              Text('• IAP: ${entitlements.inAppPurchase}'),
              Text('• Purchased version: ${entitlements.originalAppVersion}'),
              Text('• Purchase date: ${entitlements.originalPurchaseDate}'),
              Text(
                '• App purchase info source: ${entitlements.appPurchaseInfoSource}',
              ),
              Text('• In trial: ${entitlements.inTrial}'),
              Text('• Trial end: ${entitlements.trialEnd}'),
              Text('• Error: ${entitlements.error}'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = UserEntitlements.of(context)!.entitlements;
    final developerMode = Preferences.of(
      context,
      PrefsAspect.customization,
    ).developerMode;
    final onLongPress = developerMode
        ? () => _showDebugInfo(entitlements)
        : null;
    if (!entitlements.loaded) {
      return ListTile(
        leading: const CircularProgressIndicator(),
        title: Text(AppLocalizations.of(context)!.entitlementsLoadingItem),
        onLongPress: onLongPress,
      );
    }
    return Column(
      children: [
        if (entitlements.inTrial)
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(
              AppLocalizations.of(context)!.entitlementsFreeTrialItem(
                    entitlements.trialEnd ?? DateTime.now(),
                  ) +
                  (entitlements.sandboxed ? ' (sandbox)' : ''),
            ),
            onLongPress: onLongPress,
          ),
        if (!entitlements.purchased) ...[
          if (!entitlements.inTrial)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                AppLocalizations.of(context)!.entitlementsTrialExpiredItem,
              ),
              onLongPress: onLongPress,
            ),
          ListTile(
            enabled: purchaseAvailable,
            title: Text(
              AppLocalizations.of(
                context,
              )!.entitlementsPurchaseItemTitle(productDetails?.price ?? '-'),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.entitlementsPurchaseItemSubtitle,
            ),
            onTap: () => buyProduct().onError(_onError),
          ),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.entitlementsRestorePurchasesItem,
            ),
            onTap: () => restorePurchases().onError(_onError),
            onLongPress: onLongPress,
          ),
        ] else if (entitlements.legacyPurchase == true)
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(
              AppLocalizations.of(context)!.entitlementsPurchasedItem,
            ),
            subtitle: Text(
              AppLocalizations.of(
                context,
              )!.entitlementsLegacyPurchaseItemSubtitle,
            ),
            onLongPress: onLongPress,
          )
        else if (entitlements.inAppPurchase == true)
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              AppLocalizations.of(context)!.entitlementsPurchasedItem,
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.entitlementsPurchasedItemSubtitle,
            ),
            onLongPress: onLongPress,
          ),
      ],
    );
  }
}

mixin PurchaseHelper<T extends StatefulWidget> on State<T> {
  ProductDetails? productDetails;
  bool get purchaseAvailable => productDetails != null;

  @override
  void initState() {
    super.initState();
    _initStore().onError((e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    });
  }

  Future<void> _initStore() async {
    if (purchaseAvailable) return;

    if (!(await InAppPurchase.instance.isAvailable())) {
      debugPrint('Store not available');
      return;
    }
    final response = await InAppPurchase.instance.queryProductDetails({
      _orgroUnlockProductId,
    });
    if (response.error != null) {
      debugPrint('Error querying products: ${response.error}');
      logError(response.error!, StackTrace.current);
      if (mounted) showErrorSnackBar(context, response.error!);
      return;
    }
    if (response.productDetails.isEmpty) {
      debugPrint('No products found');
      return;
    }
    debugPrint(
      'Products found: ${response.productDetails.map((e) => e.title)}',
    );
    setState(() {
      productDetails = response.productDetails.first;
    });
  }

  Future<void> buyProduct() async {
    final purchaseParam = PurchaseParam(productDetails: productDetails!);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    final entitlements = UserEntitlements.of(context)!;
    await Future.wait([
      InAppPurchase.instance.restorePurchases(),
      entitlements.reload(true),
    ]);
  }
}

class DonateSettingListItem extends StatelessWidget {
  const DonateSettingListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.favorite),
      title: Text(AppLocalizations.of(context)!.donateItemTitle),
      subtitle: Text(AppLocalizations.of(context)!.donateItemSubtitle),
      onTap: visitDonateLink,
    );
  }
}

void visitDonateLink() => launchUrl(
  Uri.parse('https://orgro.org/donate/'),
  mode: LaunchMode.externalApplication,
);

class LockedBarrier extends StatelessWidget {
  const LockedBarrier({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kFreemium) return child;

    final entitlements = UserEntitlements.of(context)!.entitlements;
    if (entitlements.locked) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          showDialog<void>(
            context: context,
            builder: (context) => LockedDialog(),
          );
        },
        child: child,
      );
    }

    return child;
  }
}

class LockedDialog extends StatefulWidget {
  LockedDialog({super.key})
    : assert(kFreemium, 'Only use this in freemium builds.');

  @override
  State<LockedDialog> createState() => _LockedDialogState();
}

class _LockedDialogState extends State<LockedDialog> with PurchaseHelper {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: Text(AppLocalizations.of(context)!.entitlementsLockedDialogTitle),
      content: Text(
        AppLocalizations.of(context)!.entitlementsLockedDialogMessage,
      ),
      actions: [
        DialogButton(
          onPressed: purchaseAvailable
              ? () => buyProduct().then(_close, onError: _onError)
              : null,
          text: AppLocalizations.of(context)!
              .entitlementsLockedDialogActionPurchase(
                productDetails?.price ?? '-',
              ),
        ),
        DialogButton(
          onPressed: purchaseAvailable
              ? () => restorePurchases().then(_close, onError: _onError)
              : null,
          text: AppLocalizations.of(
            context,
          )!.entitlementsLockedDialogActionRestore,
        ),
        DialogButton(
          onPressed: visitUnlockLink,
          text: AppLocalizations.of(
            context,
          )!.entitlementsLockedDialogActionMoreInfo,
        ),
      ],
    );
  }

  void _close(_) {
    if (mounted) Navigator.pop(context);
  }
}

void visitUnlockLink() => launchUrl(
  Uri.parse('https://orgro.org/unlock/'),
  mode: LaunchMode.externalApplication,
);

extension _ErrorUtils<T extends StatefulWidget> on State<T> {
  Future<void> _onError(Object e, StackTrace s) async {
    logError(e, s);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialogTitleError),
        content: Text(e.toString()),
      ),
    );
  }
}
