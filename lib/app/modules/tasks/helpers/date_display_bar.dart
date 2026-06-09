import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/number_extension.dart';

/// ✅ نظام شريط عرض التاريخ الكامل (اليوم - غداً - تاريخ - إلغاء الفلترة)
class DateDisplayBar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onClear;
  final bool isFiltered;
  final TextStyle? dateTextStyle;
  final Color? backgroundColor;

  const DateDisplayBar({
    super.key,
    required this.selectedDate,
    required this.onClear,
    this.isFiltered = true,
    this.dateTextStyle,
    this.backgroundColor,
  });

  /// ✅ الدالة الرئيسية: حساب اسم اليوم بالعربية والإنجليزية
  String _getDateDisplayText() {
    final now = DateTime.now().normalize;
    final selected = selectedDate.normalize;
    
    // اليوم
    if (selected.isAtSameMomentAs(now)) {
      return 'today'.tr; // اليوم
    }
    
    // غداً
    final tomorrow = now.add(const Duration(days: 1));
    if (selected.isAtSameMomentAs(tomorrow)) {
      return 'tomorrow'.tr; // غداً
    }
    
    // أمس
    final yesterday = now.subtract(const Duration(days: 1));
    if (selected.isAtSameMomentAs(yesterday)) {
      return 'yesterday'.tr; // أمس
    }
    
    // بعد غد
    final dayAfterTomorrow = now.add(const Duration(days: 2));
    if (selected.isAtSameMomentAs(dayAfterTomorrow)) {
      return 'day_after_tomorrow'.tr; // بعد غد
    }
    
    // أسبوع ماضي أو قادم - عرض اسم اليوم مع التاريخ
    final locale = Get.locale?.languageCode ?? 'en';
    final dayName = DateFormat.EEEE(locale).format(selected).f; // اسم اليوم
    final date = DateFormat.Md(locale).format(selected).f; // التاريخ
    
    return '$dayName • $date';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = _getDateDisplayText();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // ✅ أيقونة التاريخ
          Icon(
            CupertinoIcons.calendar,
            size: 18,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 12),
          
          // ✅ نص التاريخ
          Expanded(
            child: Text(
              displayText,
              style: dateTextStyle ?? TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // ✅ زر الإلغاء (X)
          if (isFiltered)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 18,
                  color: theme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ✅ تمديد DateTime للمقارنة السهلة
extension DateTimeExtensions on DateTime {
  DateTime get normalize => DateTime(year, month, day);
}
