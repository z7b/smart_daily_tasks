import 'dart:math';
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
  late final AnimationController _bgController;
  late final AnimationController _pulseController;
  late final AnimationController _featureController;
  final SubscriptionService _sub = Get.find<SubscriptionService>();
  final _selectedPlan = 'yearly'.obs;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _featureController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scaleController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated gradient background ──
          _AnimatedGradientBg(controller: _bgController, isDark: isDark),

          // ── Floating particles ──
          ..._buildParticles(isDark),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Close button
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      child: _buildCloseButton(isDark),
                    ),

                    const SizedBox(height: 8),

                    // Crown icon with animated rings
                    _buildCrownIcon(isDark),
                    const SizedBox(height: 28),

                    // Title with gradient shader
                    _buildTitle(),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'premium_subtitle'.tr.isNotEmpty ? 'premium_subtitle'.tr : 'تجربة بلا حدود',
                      style: TextStyle(
                        fontSize: 15,
                        color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Features list with staggered animation
                    _buildAnimatedFeature(0, Icons.block_rounded, 'premium_feature_1_title'.tr, 'premium_feature_1_desc'.tr, isDark, const Color(0xFFFF6B6B)),
                    _buildAnimatedFeature(1, Icons.rocket_launch_rounded, 'premium_feature_2_title'.tr, 'premium_feature_2_desc'.tr, isDark, const Color(0xFF4ECDC4)),
                    _buildAnimatedFeature(2, Icons.palette_rounded, 'premium_feature_3_title'.tr, 'premium_feature_3_desc'.tr, isDark, const Color(0xFFFFBE0B)),
                    const SizedBox(height: 32),

                    // Plan selector
                    _buildPlanSelector(isDark),
                    const SizedBox(height: 28),

                    // Subscribe button
                    _buildSubscribeButton(isDark),
                    const SizedBox(height: 16),

                    // Restore button
                    TextButton(
                      onPressed: () => _sub.restorePurchases(),
                      child: Text(
                        'premium_restore'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Error message
                    Obx(() => _sub.purchaseError.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _sub.purchaseError.value,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink()
                    ),

                    const SizedBox(height: 16),
                    // Terms
                    Text(
                      'premium_terms'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Close Button ──
  Widget _buildCloseButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 20),
        onPressed: () => Get.back(),
      ),
    );
  }

  // ── Crown Icon with Pulsing Rings ──
  Widget _buildCrownIcon(bool isDark) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer animated ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                final opacity = 0.15 - (_pulseController.value * 0.1);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: opacity.clamp(0.0, 1.0)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Inner animated ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main crown circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                    blurRadius: 50,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 42, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title ──
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFFFFD700), Color(0xFFFFA500)],
            stops: [
              0.0,
              _shimmerController.value - 0.1,
              _shimmerController.value,
              1.0,
            ].map((s) => s.clamp(0.0, 1.0)).toList(),
          ).createShader(bounds),
          child: child!,
        );
      },
      child: const Text(
        'Rattib Pro',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // ── Feature Item with staggered entrance ──
  Widget _buildAnimatedFeature(int index, IconData icon, String title, String subtitle, bool isDark, Color accentColor) {
    final delay = index * 0.2;
    final start = delay;
    final end = (delay + 0.6).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _featureController,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(
          ((_featureController.value - start) / (end - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: _buildFeatureItem(icon, title, subtitle, isDark, accentColor),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, bool isDark, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.06 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.15), accentColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor.withValues(alpha: 0.8), accentColor],
                ),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan Selector ──
  Widget _buildPlanSelector(bool isDark) {
    return Obx(() => Row(
      children: [
        Expanded(child: _planCard(
          label: 'premium_yearly'.tr,
          price: _sub.getYearlyMonthlyEquivalent(),
          period: 'premium_month_short'.tr,
          savings: 'premium_save_29'.tr,
          isSelected: _selectedPlan.value == 'yearly',
          isDark: isDark,
          onTap: () => _selectedPlan.value = 'yearly',
          badgeColor: const Color(0xFF34C759),
        )),
        const SizedBox(width: 12),
        Expanded(child: _planCard(
          label: 'premium_monthly'.tr,
          price: _sub.getMonthlyPrice(),
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
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    AppTheme.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.06)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.6)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (savings != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor ?? const Color(0xFF34C759), (badgeColor ?? const Color(0xFF34C759)).withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (badgeColor ?? const Color(0xFF34C759)).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  savings,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black54),
            )),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Subscribe Button ──
  Widget _buildSubscribeButton(bool isDark) {
    return Obx(() {
      final loading = _sub.isLoading.value;
      final alreadyPremium = _sub.isPremium.value;

      // If already premium, show a confirmation state
      if (alreadyPremium) {
        return Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF34C759), Color(0xFF30D158)],
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'premium_active'.tr.isNotEmpty ? 'premium_active'.tr : 'You are Premium ✨',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

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

  // ── Floating Particles ──
  List<Widget> _buildParticles(bool isDark) {
    final random = Random(42); // Seeded for deterministic layout
    return List.generate(8, (i) {
      final size = 3.0 + random.nextDouble() * 4;
      final left = random.nextDouble();
      final top = random.nextDouble();
      final delay = random.nextDouble();

      return Positioned(
        left: MediaQuery.of(context).size.width * left,
        top: MediaQuery.of(context).size.height * top,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = ((_pulseController.value + delay) % 1.0);
            final opacity = (0.15 + t * 0.2).clamp(0.0, 0.35);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -8 * sin(t * pi * 2)),
                child: child,
              ),
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Animated Gradient Background ──
class _AnimatedGradientBg extends AnimatedWidget {
  final bool isDark;

  const _AnimatedGradientBg({
    required AnimationController controller,
    required this.isDark,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final controller = listenable as AnimationController;
    final angle = controller.value * 2 * pi;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment(cos(angle), sin(angle)),
                end: Alignment(-cos(angle), -sin(angle)),
                colors: const [
                  Color(0xFF0A0A1A),
                  Color(0xFF0D1B2A),
                  Color(0xFF1B0A28),
                  Color(0xFF0A0A1A),
                ],
              )
            : LinearGradient(
                begin: Alignment(cos(angle), sin(angle)),
                end: Alignment(-cos(angle), -sin(angle)),
                colors: const [
                  Color(0xFFF8F9FF),
                  Color(0xFFF0F0FF),
                  Color(0xFFFFF8F0),
                  Color(0xFFF8F9FF),
                ],
              ),
      ),
    );
  }
}

/// ✅ Enhanced shimmer button with glow
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
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: const [
            Color(0xFF007AFF),
            Color(0xFF5856D6),
            Color(0xFF007AFF),
            Color(0xFF34AADC),
          ],
          stops: [
            0.0,
            (controller.value - 0.1).clamp(0.0, 1.0),
            controller.value,
            1.0,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: const Color(0xFF5856D6).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'premium_subscribe_now'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
