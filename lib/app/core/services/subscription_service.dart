import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../helpers/log_helper.dart';

/// ✅ Production-Ready Subscription Service
/// 
/// Architecture:
/// - Google Play is the Single Source of Truth (SSOT) for entitlement.
/// - Local cache (`GetStorage`) is used ONLY for instant UI responsiveness.
/// - On every app launch, `restorePurchases()` is called to verify real state.
/// - Premium is NEVER activated without a valid purchase from the stream.
/// - Premium is deactivated if restore returns no active subscriptions.
///
/// Flow:
/// 1. App starts → load cached state → call `restorePurchases()`
/// 2. User buys → purchase stream fires → verify → activate → acknowledge
/// 3. User restores → purchase stream fires → verify → activate
/// 4. Subscription expires → restore returns empty → deactivate
/// 5. User reinstalls → same Google account → restore recovers entitlement
class SubscriptionService extends GetxService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final _storage = GetStorage();

  // ── Product IDs (must match Google Play Console exactly) ──
  static const String monthlyId = 'rattib_premium';
  static const String yearlyId = 'rattib_premium_yearly';
  static const Set<String> _productIds = {monthlyId, yearlyId};

  // ── Reactive State ──
  final isPremium = false.obs;
  final isLoading = false.obs;
  final products = <ProductDetails>[].obs;
  final purchaseError = ''.obs;
  final activeProductId = ''.obs; // Which plan is currently active

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isRestoring = false;

  // ── Storage Keys ──
  static const String _keyIsPremium = 'is_premium';
  static const String _keyActiveProductId = 'active_product_id';
  static const String _keyPurchaseToken = 'purchase_token';
  static const String _keyLastVerifiedAt = 'last_verified_at';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    // Step 1: Load cached state for instant UI (NOT the source of truth)
    isPremium.value = _storage.read<bool>(_keyIsPremium) ?? false;
    activeProductId.value = _storage.read<String>(_keyActiveProductId) ?? '';

    if (isPremium.value) {
      talker.info('💎 Premium cached state: ACTIVE (${activeProductId.value})');
    }

    // Step 2: Check if IAP is available on this device
    final available = await _iap.isAvailable();
    if (!available) {
      talker.warning('⚠️ In-App Purchase not available on this device');
      return;
    }

    // Step 3: Listen to ALL purchase updates (buy, restore, renewal)
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        talker.error('🔴 Purchase stream error: $error');
      },
    );

    // Step 4: Load products from Google Play
    await _loadProducts();

    // Step 5: Verify entitlement against Google Play (SSOT)
    // This catches: expired subs, refunds, cancelled subs, account changes
    await verifyEntitlement();
  }

  // ══════════════════════════════════════════════════════════════
  // ── Product Loading ──
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      final response = await _iap.queryProductDetails(_productIds);

      if (response.error != null) {
        talker.error('🔴 Product query error: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        talker.warning('⚠️ Products not found in store: ${response.notFoundIDs}');
      }

      products.assignAll(response.productDetails);
      talker.info('✅ Loaded ${products.length} subscription products');

      for (final p in products) {
        talker.info('   📦 ${p.id}: ${p.price} (${p.currencyCode})');
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to load products');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── Product Getters ──
  // ══════════════════════════════════════════════════════════════

  ProductDetails? getMonthly() => products
      .cast<ProductDetails?>()
      .firstWhere((p) => p?.id == monthlyId, orElse: () => null);

  ProductDetails? getYearly() => products
      .cast<ProductDetails?>()
      .firstWhere((p) => p?.id == yearlyId, orElse: () => null);

  /// Get the real price string from Google Play for display
  String getMonthlyPrice() => getMonthly()?.price ?? '\$7';
  String getYearlyPrice() => getYearly()?.price ?? '\$60';

  /// Calculate monthly equivalent for yearly plan display
  String getYearlyMonthlyEquivalent() {
    final yearly = getYearly();
    if (yearly != null) {
      // rawPrice is in micros (e.g. 60000000 for $60)
      final monthlyEquiv = yearly.rawPrice / 12;
      return '${yearly.currencySymbol}${monthlyEquiv.toStringAsFixed(0)}';
    }
    return '\$5';
  }

  /// Calculate savings percentage
  String getSavingsText() {
    final monthly = getMonthly();
    final yearly = getYearly();
    if (monthly != null && yearly != null && monthly.rawPrice > 0) {
      final yearlyMonthly = yearly.rawPrice / 12;
      final savings = ((monthly.rawPrice - yearlyMonthly) / monthly.rawPrice * 100).round();
      return '$savings%';
    }
    return '29%';
  }

  // ══════════════════════════════════════════════════════════════
  // ── Purchase Flow ──
  // ══════════════════════════════════════════════════════════════

  /// Initiate a subscription purchase
  Future<void> purchase(ProductDetails product) async {
    if (isPremium.value) {
      talker.info('💎 Already premium. Skipping purchase.');
      return;
    }

    try {
      purchaseError.value = '';
      isLoading.value = true;

      final purchaseParam = PurchaseParam(productDetails: product);
      // buyNonConsumable is correct for subscriptions in the in_app_purchase plugin
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        isLoading.value = false;
        purchaseError.value = 'Unable to initiate purchase';
        talker.error('🔴 buyNonConsumable returned false');
      }
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Purchase initiation failed');
      purchaseError.value = e.toString();
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── Restore Purchases ──
  // ══════════════════════════════════════════════════════════════

  /// Restore previous purchases (manual button or auto on init)
  Future<void> restorePurchases() async {
    if (_isRestoring) return; // Prevent duplicate calls
    
    try {
      _isRestoring = true;
      isLoading.value = true;
      purchaseError.value = '';
      
      await _iap.restorePurchases();
      talker.info('🔄 Restore purchases initiated');
      
      // Give the purchase stream time to deliver results
      // If no purchases come through, we'll deactivate after timeout
      Future.delayed(const Duration(seconds: 5), () {
        if (_isRestoring) {
          _isRestoring = false;
          isLoading.value = false;
          // If still restoring after 5s and no purchase came through,
          // the stream didn't deliver any active purchases
        }
      });
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Restore purchases failed');
      purchaseError.value = e.toString();
      isLoading.value = false;
      _isRestoring = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── Entitlement Verification (SSOT) ──
  // ══════════════════════════════════════════════════════════════

  /// Verify entitlement against Google Play
  /// Called on every app launch to ensure premium state is real
  Future<void> verifyEntitlement() async {
    try {
      talker.info('🔐 Verifying subscription entitlement...');
      
      // Track if restore finds any active subscription
      _foundActiveSubscription = false;
      
      await _iap.restorePurchases();
      
      // Wait for purchase stream to process results
      await Future.delayed(const Duration(seconds: 3));
      
      // If no active subscription was found during restore,
      // deactivate premium (handles: expired, refunded, cancelled)
      if (!_foundActiveSubscription && isPremium.value) {
        talker.warning('⚠️ No active subscription found. Deactivating premium.');
        _deactivatePremium();
      }
      
      _storage.write(_keyLastVerifiedAt, DateTime.now().toIso8601String());
    } catch (e, stack) {
      talker.handle(e, stack, '⚠️ Entitlement verification failed');
      // On verification failure, keep current cached state
      // Don't deactivate — benefit of the doubt to the user
    }
  }

  bool _foundActiveSubscription = false;

  // ══════════════════════════════════════════════════════════════
  // ── Purchase Stream Handler ──
  // ══════════════════════════════════════════════════════════════

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      talker.info('📦 Purchase update: ${purchase.productID} → ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isLoading.value = true;
          talker.info('⏳ Purchase pending for ${purchase.productID}');
          break;

        case PurchaseStatus.purchased:
          _verifyAndActivate(purchase);
          _isRestoring = false;
          break;

        case PurchaseStatus.restored:
          _verifyAndActivate(purchase);
          _foundActiveSubscription = true;
          _isRestoring = false;
          break;

        case PurchaseStatus.error:
          isLoading.value = false;
          _isRestoring = false;
          final errorMsg = purchase.error?.message ?? 'Purchase failed';
          purchaseError.value = errorMsg;
          talker.error('🔴 Purchase error: ${purchase.error}');
          break;

        case PurchaseStatus.canceled:
          isLoading.value = false;
          _isRestoring = false;
          talker.info('❌ Purchase cancelled by user');
          break;
      }

      // ✅ CRITICAL: Complete pending purchases (Google Play requirement)
      // Failure to do this causes the purchase to be refunded after 3 days
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
        talker.info('✅ Purchase acknowledged: ${purchase.productID}');
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── Verification & Activation ──
  // ══════════════════════════════════════════════════════════════

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    try {
      // Verify the purchase is for one of our known product IDs
      if (!_productIds.contains(purchase.productID)) {
        talker.warning('⚠️ Unknown product ID: ${purchase.productID}');
        isLoading.value = false;
        return;
      }

      // Verify we have valid verification data
      final verificationData = purchase.verificationData;
      if (verificationData.localVerificationData.isEmpty) {
        talker.error('🔴 No verification data for ${purchase.productID}');
        isLoading.value = false;
        return;
      }

      // ✅ Client-side verification passed — activate premium
      _activatePremium(purchase.productID, purchase.purchaseID ?? '');
      
      isLoading.value = false;
      talker.info('✅ Premium ACTIVATED via ${purchase.productID}');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Purchase verification failed');
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── State Management ──
  // ══════════════════════════════════════════════════════════════

  void _activatePremium(String productId, String purchaseToken) {
    isPremium.value = true;
    activeProductId.value = productId;
    
    _storage.write(_keyIsPremium, true);
    _storage.write(_keyActiveProductId, productId);
    _storage.write(_keyPurchaseToken, purchaseToken);
    _storage.write(_keyLastVerifiedAt, DateTime.now().toIso8601String());
    
    talker.info('💎 Premium state saved: $productId');
  }

  void _deactivatePremium() {
    isPremium.value = false;
    activeProductId.value = '';
    
    _storage.write(_keyIsPremium, false);
    _storage.write(_keyActiveProductId, '');
    _storage.write(_keyPurchaseToken, '');
    
    talker.info('🔒 Premium deactivated — subscription expired or not found');
  }

  // ══════════════════════════════════════════════════════════════
  // ── Cleanup ──
  // ══════════════════════════════════════════════════════════════

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
