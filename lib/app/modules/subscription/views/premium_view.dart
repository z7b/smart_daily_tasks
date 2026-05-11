import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/subscription_service.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _scaleController;
  final SubscriptionService _sub = Get.find<SubscriptionService>();
  final _selectedPlan = 'yearly'.obs;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Close button
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.textTheme.bodyMedium?.color),
                    onPressed: () => Get.back(),
                  ),
                ),

                // Crown icon with glow
                _buildCrownIcon(isDark),
                const SizedBox(height: 24),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                  ).createShader(bounds),
                  child: Text(
                    'Life OS Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'premium_subtitle'.tr.isNotEmpty ? 'premium_subtitle'.tr : 'تجربة بلا حدود',
                  style: TextStyle(fontSize: 15, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 32),

                // Features list
                _buildFeatureItem(Icons.block_rounded, 'premium_feature_1_title'.tr, 'premium_feature_1_desc'.tr, isDark),
                _buildFeatureItem(Icons.rocket_launch_rounded, 'premium_feature_2_title'.tr, 'premium_feature_2_desc'.tr, isDark),
                _buildFeatureItem(Icons.palette_rounded, 'premium_feature_3_title'.tr, 'premium_feature_3_desc'.tr, isDark),
                const SizedBox(height: 32),

                // Plan selector
                _buildPlanSelector(isDark),
                const SizedBox(height: 24),

                // Subscribe button
                _buildSubscribeButton(isDark),
                const SizedBox(height: 16),

                // Restore button
                TextButton(
                  onPressed: () => _sub.restorePurchases(),
                  child: Text(
                    'premium_restore'.tr,
                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),

                // Error message
                Obx(() => _sub.purchaseError.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _sub.purchaseError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink()
                ),

                const SizedBox(height: 16),
                // Terms
                Text(
                  'premium_terms'.tr,
                  style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrownIcon(bool isDark) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.workspace_premium_rounded, size: 42, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 20),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(bool isDark) {
    return Obx(() => Row(
      children: [
        Expanded(child: _planCard(
          label: 'premium_yearly'.tr,
          price: '\$5',
          period: 'premium_month_short'.tr,
          savings: 'premium_save_29'.tr,
          isSelected: _selectedPlan.value == 'yearly',
          isDark: isDark,
          onTap: () => _selectedPlan.value = 'yearly',
        )),
        const SizedBox(width: 12),
        Expanded(child: _planCard(
          label: 'premium_monthly'.tr,
          price: '\$7',
          period: 'premium_month_short'.tr,
          isSelected: _selectedPlan.value == 'monthly',
          isDark: isDark,
          onTap: () => _selectedPlan.value = 'monthly',
        )),
      ],
    ));
  }

  Widget _planCard({
    required String label,
    required String price,
    required String period,
    String? savings,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (savings != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(savings, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
            ],
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black54),
            )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppTheme.primary : (isDark ? Colors.white : Colors.black87),
                )),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(period, style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(bool isDark) {
    return Obx(() {
      final loading = _sub.isLoading.value;

      return GestureDetector(
        onTap: loading ? null : _handleSubscribe,
        child: _ShimmerButton(
          controller: _shimmerController,
          isLoading: loading,
        ),
      );
    });
  }

  void _handleSubscribe() {
    final product = _selectedPlan.value == 'yearly' ? _sub.getYearly() : _sub.getMonthly();

    if (product != null) {
      _sub.purchase(product);
    } else {
      // Fallback: products not loaded from store yet
      Get.snackbar(
        'premium_not_available_title'.tr,
        'premium_not_available_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }
}

/// ✅ Lifecycle-safe shimmer button (avoids AnimatedBuilder name conflict)
class _ShimmerButton extends AnimatedWidget {
  final bool isLoading;

  const _ShimmerButton({
    required AnimationController controller,
    required this.isLoading,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final controller = listenable as AnimationController;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: const [Color(0xFF007AFF), Color(0xFF5856D6), Color(0xFF007AFF)],
          stops: [
            0.0,
            controller.value,
            1.0,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(
                'premium_subscribe_now'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
      ),
    );
  }
}
