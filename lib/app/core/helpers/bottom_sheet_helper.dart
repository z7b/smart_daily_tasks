import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomSheetHelper {
  static Future<T?> showSafeBottomSheet<T>({
    required Widget Function(BuildContext context, StateSetter setState) builder,
    bool isScrollControlled = true,
    Color backgroundColor = Colors.transparent,
    double maxHeightRatio = 0.9,
  }) async {
    // 1. الانتظار لاستقرار الواجهة
    await Future.delayed(const Duration(milliseconds: 100));

    // 2. استخدام السياق (Context) الآمن
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return null;

    // 3. بناء النافذة
    return await showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      builder: (bottomCtx) {
        // 4. استخدام StatefulBuilder للتحديث المعزول
        return StatefulBuilder(
          builder: (sbCtx, setState) {
            final isDark = Theme.of(bottomCtx).brightness == Brightness.dark;

            // 5. الانضغاط الديناميكي مع الكيبورد والمساحة الآمنة السفلية
            final bottomPadding = MediaQuery.of(bottomCtx).padding.bottom;
            final keyboardInset = MediaQuery.of(bottomCtx).viewInsets.bottom;

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: keyboardInset > 0 ? keyboardInset : bottomPadding,
              ),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                // 6. منع تجاوز الشاشة
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(bottomCtx).size.height * maxHeightRatio,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: builder(sbCtx, setState),
              ),
            );
          },
        );
      },
    );
  }
}
