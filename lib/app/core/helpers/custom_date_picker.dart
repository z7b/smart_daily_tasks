import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'number_extension.dart';

class CustomDatePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    DateTime selectedDay = initialDate;
    DateTime focusedDay = initialDate;

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('select_date'.tr, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
          content: SizedBox(
            width: 320,
            height: 380,
            child: StatefulBuilder(
              builder: (context, setState) {
                return TableCalendar(
                  firstDay: firstDate,
                  lastDay: lastDate,
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (sDay, fDay) {
                    setState(() {
                      selectedDay = sDay;
                      focusedDay = fDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold),
                    leftChevronIcon: Icon(Icons.chevron_left, color: theme.textTheme.bodyLarge?.color),
                    rightChevronIcon: Icon(Icons.chevron_right, color: theme.textTheme.bodyLarge?.color),
                  ),
                  locale: Get.locale?.languageCode,
                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, day) {
                      final text = DateFormat.yMMMM(Get.locale?.languageCode).format(day);
                      return Center(
                        child: Text(
                          text.f,
                          style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Text(
                          NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3)),
                        ),
                      );
                    },
                  ),
                );
              }
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('cancel'.tr, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Get.back(result: selectedDay),
              child: Text('confirm'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }
}

