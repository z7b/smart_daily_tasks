import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import 'package:smart_daily_tasks/app/core/helpers/number_extension.dart';

class QuickLogStrip extends StatelessWidget {
  final Function(DateTime) onDaySelected;
  final Set<DateTime> completedDays;
  final DateTime selectedDate; // ✅ Added to track current selection

  const QuickLogStrip({
    super.key,
    required this.onDaySelected,
    required this.completedDays,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    // Generate last 7 days including today
    final days = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    final locale = Get.locale?.languageCode ?? 'en';

    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = days[index];
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isCompleted = completedDays.any(
            (d) => DateUtils.isSameDay(d, date),
          );

          return GestureDetector(
            onTap: () => onDaySelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primary 
                    : (isCompleted 
                        ? AppTheme.primary.withAlpha(40)
                        : (isToday
                            ? AppTheme.primary.withAlpha(20)
                            : Theme.of(context).cardColor)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primary 
                      : (isToday ? AppTheme.primary.withAlpha(100) : Colors.transparent),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E(locale).format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppTheme.primary : Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date).f,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppTheme.primary : Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                  if (isCompleted && !isSelected) ...[
                    const SizedBox(height: 4),
                    Icon(Icons.check_circle, size: 12, color: AppTheme.primary),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
