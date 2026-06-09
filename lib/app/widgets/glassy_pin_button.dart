
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../core/services/pin_service.dart';

class GlassyPinButton extends StatelessWidget {
  final String itemType;
  final int itemId;
  final double size;

  const GlassyPinButton({
    super.key,
    required this.itemType,
    required this.itemId,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PinService>()) {
      return const SizedBox.shrink();
    }
    
    final pinService = Get.find<PinService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isPinned = pinService.isPinned(itemType, itemId);
      
      return GestureDetector(
        onTap: () {
          pinService.togglePin(itemType, itemId);
          if (!isPinned) {
            Get.snackbar(
              'تم التثبيت',
              'تم تثبيت العنصر في الصبورة بنجاح',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black54,
              colorText: Colors.white,
              margin: const EdgeInsets.all(8),
              duration: const Duration(seconds: 2),
            );
          }
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPinned 
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05)),
            gradient: isPinned
                ? SweepGradient(
                    colors: [
                      const Color(0xFF90CAF9).withValues(alpha: 0.8), // Blue
                      const Color(0xFFA5D6A7).withValues(alpha: 0.8), // Green
                      const Color(0xFFFFEB3B).withValues(alpha: 0.8), // Yellow
                      const Color(0xFFFFCC80).withValues(alpha: 0.8), // Orange
                      const Color(0xFFE1BEE7).withValues(alpha: 0.8), // Purple
                      const Color(0xFF90CAF9).withValues(alpha: 0.8), // Blue
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPinned 
                  ? Colors.white.withValues(alpha: 0.5)
                  : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1)),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
              size: size * 0.5,
              color: isPinned 
                  ? Colors.white 
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      );
    });
  }
}
