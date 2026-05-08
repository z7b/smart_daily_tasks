import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../helpers/log_helper.dart';

/// ✅ Subscription Service — Manages In-App Purchase lifecycle
/// Handles: product fetch, purchase flow, validation, restore, and state.
class SubscriptionService extends GetxService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final _storage = GetStorage();

  // Product IDs (must match Google Play Console)
  static const String monthlyId = 'lifeos_premium_monthly';
  static const String yearlyId = 'lifeos_premium_yearly';
  static const Set<String> _productIds = {monthlyId, yearlyId};

  // Reactive State
  final isPremium = false.obs;
  final isLoading = false.obs;
  final products = <ProductDetails>[].obs;
  final purchaseError = ''.obs;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    // Load cached premium state for instant UI
    isPremium.value = _storage.read<bool>('is_premium') ?? false;

    final available = await _iap.isAvailable();
    if (!available) {
      talker.warning('⚠️ In-App Purchase not available on this device');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        talker.error('🔴 Purchase stream error: $error');
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      final response = await _iap.queryProductDetails(_productIds);

      if (response.error != null) {
        talker.error('🔴 Product query error: ${response.error}');
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        talker.warning('⚠️ Products not found: ${response.notFoundIDs}');
      }

      products.assignAll(response.productDetails);
      talker.info('✅ Loaded ${products.length} subscription products');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Failed to load products');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get product by ID, sorted for display
  ProductDetails? getMonthly() =>
      products.cast<ProductDetails?>().firstWhere((p) => p?.id == monthlyId, orElse: () => null);

  ProductDetails? getYearly() =>
      products.cast<ProductDetails?>().firstWhere((p) => p?.id == yearlyId, orElse: () => null);

  /// Purchase a subscription
  Future<void> purchase(ProductDetails product) async {
    try {
      purchaseError.value = '';
      isLoading.value = true;

      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Purchase initiation failed');
      purchaseError.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      purchaseError.value = '';
      await _iap.restorePurchases();
      talker.info('🔄 Restore purchases initiated');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Restore purchases failed');
      purchaseError.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Handle purchase stream updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      talker.info('📦 Purchase update: ${purchase.productID} → ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          isLoading.value = true;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndActivate(purchase);
          break;

        case PurchaseStatus.error:
          isLoading.value = false;
          purchaseError.value = purchase.error?.message ?? 'Purchase failed';
          talker.error('🔴 Purchase error: ${purchase.error}');
          break;

        case PurchaseStatus.canceled:
          isLoading.value = false;
          talker.info('❌ Purchase cancelled by user');
          break;
      }

      // Complete pending purchases (required by Google Play)
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify and activate premium
  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    // Note: Add server-side verification for production in the future.
    // For now, trust the local store receipt.
    _activatePremium();
    isLoading.value = false;
    talker.info('✅ Premium activated via ${purchase.productID}');
  }

  void _activatePremium() {
    isPremium.value = true;
    _storage.write('is_premium', true);
  }

  // void _deactivatePremium() {
  //   isPremium.value = false;
  //   _storage.write('is_premium', false);
  // }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
