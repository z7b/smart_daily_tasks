import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_daily_tasks/app/core/helpers/number_extension.dart';

class TimeFormatHelper {
  /// Formats the time using 12-hour format with localized AM/PM
  static String formatTime(DateTime time) {
    final timeStr = DateFormat.jm('en').format(time).f;
    return timeStr
        .replaceAll('AM', 'am_short'.tr)
        .replaceAll('PM', 'pm_short'.tr);
  }

  /// Formats a TimeOfDay using 12-hour format with localized AM/PM
  static String formatTimeOfDay(dynamic time) {
    // We use dynamic to avoid importing material just for TimeOfDay if not needed,
    // but typically it's fine. We'll assume time has .hour and .minute.
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return formatTime(dt);
  }
}
