import 'dart:math';

extension DateTimeExtensions on DateTime {
  /// Returns true if this date is the same year, month, and day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns true if this date is within the range [start] and [end] (inclusive).
  bool isBetween(DateTime start, DateTime end) {
    return (isAfter(start) || isSameDay(start)) &&
        (isBefore(end) || isSameDay(end));
  }

  /// Returns a normalized date (time set to 00:00:00).
  DateTime get normalized => DateTime(year, month, day);

  /// Safely calculates the number of days in the month for this date.
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  /// Safely calculates the next occurrence of a specific day of the month.
  /// Handles months with fewer days (e.g., if dayOfMonth is 31 and next month is Feb).
  DateTime nextOccurrenceOfMonthDay(int dayOfMonth) {
    // Clamp to valid day range
    final clampedDay = dayOfMonth.clamp(1, 31);

    // Try current month first if not already passed
    DateTime candidate = DateTime(year, month, min(clampedDay, daysInMonth));

    if (!normalized.isBefore(candidate)) {
      // Move to next month (current day is same or after candidate)
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }

      int daysInNext = DateTime(nextYear, nextMonth + 1, 0).day;
      candidate = DateTime(nextYear, nextMonth, min(clampedDay, daysInNext));
    }

    return candidate;
  }
}
