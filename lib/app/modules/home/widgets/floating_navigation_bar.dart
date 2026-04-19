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
        padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.5) 
                  : Colors.white.withValues(alpha: 0.7),
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
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, 'home'.tr),
                _buildNavItem(1, Icons.space_dashboard_rounded, 'spaces'.tr),
                _buildNavItem(2, Icons.settings_rounded, 'settings'.tr),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final controller = Get.find<HomeController>();
    
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final color = isSelected 
          ? const Color(0xFF007AFF)
          : Colors.grey.withValues(alpha: 0.6);
          
      return GestureDetector(
        onTap: () => controller.changePage(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 20 : 12, 
            vertical: 12
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF007AFF).withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ]
            ],
          ),
        ),
      );
    });
  }
}
