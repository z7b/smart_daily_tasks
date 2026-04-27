import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/appointment_model.dart';

class AppointmentTimeService extends GetxService {
  /// Returns a smart localized label for the remaining time
  String getSmartTimeLabel(DateTime scheduledAt, AppointmentStatus status) {
    if (status == AppointmentStatus.completed) {
      return 'appointment_completed_label'.tr;
    }
    if (status == AppointmentStatus.cancelled) {
      return 'appointment_cancelled_label'.tr;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

    final diffDays = appointmentDate.difference(today).inDays;

    if (diffDays < 0) {
      return 'ended_ago'.trParams({'time': '${diffDays.abs()} ${'days'.tr}'});
    } else if (diffDays == 0) {
      final diffHours = scheduledAt.difference(now).inHours;
      final diffMinutes = scheduledAt.difference(now).inMinutes;

      if (diffMinutes < 0) {
        return 'appointment_passed_today'.tr; // e.g. "Passed earlier today"
      } else if (diffMinutes == 0) {
        return 'appointment_now'.tr; // e.g. "Now"
      } else if (diffHours == 0) {
        return 'in_minutes'.trParams({'minutes': diffMinutes.toString()});
      } else {
        return 'today_in_hours'.trParams({'hours': diffHours.toString()});
      }
    } else if (diffDays == 1) {
      final timeFormatted = DateFormat.jm(Get.locale?.languageCode ?? 'en').format(scheduledAt);
      return 'tomorrow_at'.trParams({'time': timeFormatted});
    } else {
      return 'remaining_days'.trParams({'days': diffDays.toString()});
    }
  }

  /// Returns the appropriate badge color based on proximity and status
  Color getBadgeColor(DateTime scheduledAt, AppointmentStatus status, ThemeData theme) {
    if (status == AppointmentStatus.completed) return Colors.green;
    if (status == AppointmentStatus.cancelled) return theme.disabledColor;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

    final diffDays = appointmentDate.difference(today).inDays;

    final medicalBlue = const Color(0xFF4A90E2);
    final softOrange = const Color(0xFFFF9F0A);
    final softTeal = const Color(0xFF5AC8FA);

    if (diffDays < 0) {
      return theme.disabledColor.withValues(alpha: 0.6); // Past
    } else if (diffDays == 0) {
      return medicalBlue; // Today
    } else if (diffDays == 1) {
      return softOrange; // Tomorrow (Close)
    } else {
      return softTeal; // Future (Calm)
    }
  }
}
