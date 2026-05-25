import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class FloatingNavigationBar extends StatelessWidget {
  const FloatingNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: true,
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    0,
                    Icons.push_pin_rounded,
                    Icons.push_pin_outlined,
                    'keep'.tr,
                    const Color(0xFF90CAF9),
                    activeGradient: const LinearGradient(
                      colors: [
                        Color(0xFF90CAF9),
                        Color(0xFFA5D6A7),
                        Color(0xFFFFEB3B),
                        Color(0xFFFFCC80),
                        Color(0xFFE1BEE7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  _buildNavItem(
                    1,
                    Icons.home_rounded,
                    Icons.home_outlined,
                    'home'.tr,
                    const Color(0xFF007AFF),
                  ),
                  _buildNavItem(
                    2,
                    Icons.space_dashboard_rounded,
                    Icons.space_dashboard_outlined,
                    'spaces'.tr,
                    const Color(0xFF007AFF),
                  ),
                  _buildNavItem(
                    3,
                    Icons.settings_rounded,
                    Icons.settings_outlined,
                    'settings'.tr,
                    const Color(0xFF007AFF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    Color activeColor, {
    Gradient? activeGradient,
  }) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final color =
          isSelected ? activeColor : Colors.grey.withValues(alpha: 0.6);
      final currentIcon = isSelected ? activeIcon : inactiveIcon;

      Widget content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(currentIcon, color: isSelected && activeGradient != null ? Colors.white : color, size: 24),
          if (isSelected) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected && activeGradient != null ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      );

      if (isSelected && activeGradient != null) {
        content = ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => activeGradient.createShader(bounds),
          child: content,
        );
      }

      Gradient? bgGradient;
      if (isSelected && activeGradient != null && activeGradient is LinearGradient) {
        bgGradient = LinearGradient(
          colors: activeGradient.colors.map((c) => c.withValues(alpha: 0.15)).toList(),
          begin: activeGradient.begin,
          end: activeGradient.end,
        );
      }

      return GestureDetector(
        onTap: () => controller.changePage(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected && bgGradient == null
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: content,
        ),
      );
    });
  }
}
