import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _channel = MethodChannel('com.madlonkay.orgro/app_purchase');

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
const kLastPaidVersion = 212;

const _orgroUnlockProductId = 'orgro_unlock_1';

const _trialPeriodDays = 7;

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
  var _entitlements = EntitlementsData(loaded: false);

  @override
  void initState() {
    super.initState();
    if (!kFreemium) return;

    debugPrint('AMK initializing UserEntitlements');
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
    Object? error;
    try {
      final info = await _channel.invokeMapMethod<String, dynamic>(
        'getAppPurchaseInfo',
        {'refresh': refresh},
      );
      debugPrint('App purchase info: $info');
      originalAppVersion = info!['originalAppVersion'] as String;
      final timestamp = info['originalPurchaseDate'] as double;
      originalPurchaseDate = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
        isUtc: true,
      );
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      setState(() {
        _entitlements = _entitlements.copyWith(
          loaded: true,
          originalPurchaseDate: originalPurchaseDate,
          originalAppVersion: originalAppVersion,
          error: error,
        );
      });
    }
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    debugPrint('AMK purchase update: $purchaseDetailsList');
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
        'AMK handling purchase: ${purchaseDetails.productID}, ${purchaseDetails.purchaseID}, ${purchaseDetails.status}, ${purchaseDetails.transactionDate}',
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
              iapUnlock: true,
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
  const EntitlementsData({
    required this.loaded,
    this.originalPurchaseDate,
    this.originalAppVersion,
    this.iapUnlock,
    this.error,
  });

  final bool loaded;
  final DateTime? originalPurchaseDate;
  final String? originalAppVersion;
  final bool? iapUnlock;
  final Object? error;

  bool get hasError => error != null;
  bool get sandboxed => Platform.isIOS && originalAppVersion == '1.0';
  bool get legacyUnlock {
    if (originalAppVersion == null) return false;
    final parsed = int.tryParse(originalAppVersion!);
    if (parsed == null) {
      // iOS sandbox will have '1.0' for the version, which isn't an int so we
      // pass through here.
      return false;
    }
    return parsed <= kLastPaidVersion;
  }

  bool get unlocked => legacyUnlock == true || iapUnlock == true;
  bool get inTrial =>
      hasError ||
      sandboxed ||
      !unlocked &&
          originalPurchaseDate != null &&
          DateTime.now().difference(originalPurchaseDate!).inDays <
              _trialPeriodDays;
  DateTime? get trialEnd => inTrial && originalPurchaseDate != null
      ? originalPurchaseDate!.add(Duration(days: _trialPeriodDays))
      : null;

  @override
  bool operator ==(Object other) =>
      other is EntitlementsData &&
      other.loaded == loaded &&
      other.originalPurchaseDate == originalPurchaseDate &&
      other.originalAppVersion == originalAppVersion &&
      other.iapUnlock == iapUnlock &&
      other.error == error;

  @override
  int get hashCode => Object.hash(
    loaded,
    originalPurchaseDate,
    originalAppVersion,
    iapUnlock,
    error,
  );

  EntitlementsData copyWith({
    bool? loaded,
    DateTime? originalPurchaseDate,
    String? originalAppVersion,
    bool? iapUnlock,
    Object? error,
  }) => EntitlementsData(
    loaded: loaded ?? this.loaded,
    originalPurchaseDate: originalPurchaseDate ?? this.originalPurchaseDate,
    originalAppVersion: originalAppVersion ?? this.originalAppVersion,
    iapUnlock: iapUnlock ?? this.iapUnlock,
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
              Text('• Unlocked: ${entitlements.unlocked}'),
              Text('• Sandboxed: ${entitlements.sandboxed}'),
              Text('• Legacy unlock: ${entitlements.legacyUnlock}'),
              Text('• IAP unlock: ${entitlements.iapUnlock}'),
              Text('• Purchased version: ${entitlements.originalAppVersion}'),
              Text('• Purchase date: ${entitlements.originalPurchaseDate}'),
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
    return Column(
      children: [
        if (!entitlements.loaded)
          ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(AppLocalizations.of(context)!.entitlementsLoadingItem),
          ),
        if (entitlements.inTrial)
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(
              AppLocalizations.of(context)!.entitlementsFreeTrialItem(
                entitlements.trialEnd ?? DateTime.now(),
              ),
            ),
            onLongPress: onLongPress,
          ),
        if (!entitlements.unlocked) ...[
          if (!entitlements.inTrial)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(
                AppLocalizations.of(context)!.entitlementsTrialExpiredItem,
              ),
              onLongPress: onLongPress,
            ),
          ListTile(
            enabled: purchaseAvailable == true,
            title: Text(
              AppLocalizations.of(context)!.entitlementsPurchaseItemTitle,
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.entitlementsPurchaseItemSubtitle,
            ),
            onTap: buyProduct,
          ),
          ListTile(
            enabled: purchaseAvailable == true,
            title: Text(
              AppLocalizations.of(context)!.entitlementsRestorePurchasesItem,
            ),
            onTap: restorePurchases,
            onLongPress: onLongPress,
          ),
        ] else if (entitlements.legacyUnlock == true)
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
        else if (entitlements.iapUnlock == true)
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              AppLocalizations.of(context)!.entitlementsPurchasedItem,
            ),
            onLongPress: onLongPress,
          ),
      ],
    );
  }
}

mixin PurchaseHelper<T extends StatefulWidget> on State<T> {
  bool? purchaseAvailable;
  late ProductDetails productDetails;

  @override
  void initState() {
    super.initState();
    _initStore().onError((e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    });
  }

  Future<void> _initStore() async {
    debugPrint('AMK trying to init store');
    if (purchaseAvailable != null) {
      debugPrint('AMK store already initialized');
      return;
    }
    if (!(await InAppPurchase.instance.isAvailable())) {
      debugPrint('AMK store not available');
      setState(() => purchaseAvailable = false);
      return;
    }
    final response = await InAppPurchase.instance.queryProductDetails({
      _orgroUnlockProductId,
    });
    if (response.error != null) {
      debugPrint('AMK error querying products: ${response.error}');
      logError(response.error!, StackTrace.current);
      if (mounted) showErrorSnackBar(context, response.error!);
      return;
    }
    if (response.productDetails.isEmpty) {
      debugPrint('No products found');
      return;
    }
    debugPrint('AMK products found: ${response.productDetails}');
    setState(() {
      purchaseAvailable = true;
      productDetails = response.productDetails.first;
    });
  }

  void buyProduct() async {
    try {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  void restorePurchases() async {
    final entitlements = UserEntitlements.of(context)!;
    try {
      await InAppPurchase.instance.restorePurchases();
      await entitlements.reload(true);
    } catch (e, s) {
      logError(e, s);
      if (mounted) showErrorSnackBar(context, e);
    }
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

    // TODO(aaron): Remove this when going freemium
    final developerMode = Preferences.of(
      context,
      PrefsAspect.customization,
    ).developerMode;
    if (!developerMode) return child;

    final entitlements = UserEntitlements.of(context)!.entitlements;
    if (entitlements.unlocked || entitlements.inTrial) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        showDialog<void>(
          context: context,
          builder: (context) => const LockedDialog(),
        );
      },
      child: child,
    );
  }
}

class LockedDialog extends StatefulWidget {
  const LockedDialog({super.key});

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
          onPressed: purchaseAvailable == true ? buyProduct : null,
          text: AppLocalizations.of(
            context,
          )!.entitlementsLockedDialogActionPurchase,
        ),
        DialogButton(
          onPressed: purchaseAvailable == true ? restorePurchases : null,
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
}

void visitUnlockLink() => launchUrl(
  Uri.parse('https://orgro.org/unlock/'),
  mode: LaunchMode.externalApplication,
);
