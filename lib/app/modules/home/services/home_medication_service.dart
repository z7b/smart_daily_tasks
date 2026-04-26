import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/medication_repository.dart';
import '../../../core/extensions/date_time_extensions.dart';
import '../../../core/helpers/number_extension.dart';

class MedicationDailyStats {
  final int taken;
  final int expected;
  final String nextTime;
  final String nextName;
  final String nextTimeLeft;

  MedicationDailyStats({
    required this.taken,
    required this.expected,
    required this.nextTime,
    required this.nextName,
    required this.nextTimeLeft,
  });
}

class HomeMedicationService extends GetxService {
  final MedicationRepository _repository;
  HomeMedicationService(this._repository);

  Future<MedicationDailyStats> getDailyStats(DateTime viewDate) async {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final normalizedView = DateTime(viewDate.year, viewDate.month, viewDate.day);
    
    // Only fetch active medications for this specific date
    final activeMeds = await _repository.getActiveMedicationsForDate(viewDate);
    
    int expected = 0;
    int taken = 0;

    // Calculate Adherence
    if (!normalizedView.isAfter(todayNormalized)) {
      for (var med in activeMeds) {
        final int expectedForThisMed = med.reminderTimes.length;
        int takenForThisMed = 0;
        for (var intake in med.intakeHistory) {
          if (intake.isSameDay(viewDate)) {
            takenForThisMed++;
          }
        }
        expected += expectedForThisMed;
        taken += takenForThisMed > expectedForThisMed ? expectedForThisMed : takenForThisMed;
      }
    }

    // Calculate Next Dose (Only relevant if viewDate is Today or Future)
    String nextTime = '';
    String nextName = '';
    String nextTimeLeft = '';

    if (viewDate.isSameDay(now) || viewDate.isAfter(now)) {
      DateTime? nextDoseDateTime;
      final locale = Get.locale?.languageCode ?? 'en';
      final todayStart = DateTime(now.year, now.month, now.day);

      // We need ALL active meds regardless of the specific view date, to find the absolute next global dose.
      // Wait, if we want the absolute next dose across all time, we might need all active meds.
      // We will use a slightly expanded window or just query all active meds for this part.
      // To prevent OOM, we can just use the already fetched activeMeds for viewDate as an approximation for today's meds.
      final allMedsForNextDose = await _repository.getActiveMedicationsForDate(now);

      for (var med in allMedsForNextDose) {
        final medStartN = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
        final medEndN = med.endDate != null ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day) : null;
        
        DateTime? candidateDate;

        if (!todayStart.isBefore(medStartN) && (medEndN == null || !todayStart.isAfter(medEndN))) {
          final sortedTimes = List<String>.from(med.reminderTimes);
          sortedTimes.sort((a, b) {
            final tA = _parseRobustTime(a) ?? DateTime(1970, 1, 1, 0, 0);
            final tB = _parseRobustTime(b) ?? DateTime(1970, 1, 1, 0, 0);
            if (tA.hour != tB.hour) return tA.hour.compareTo(tB.hour);
            return tA.minute.compareTo(tB.minute);
          });

          final todayIntakeCount = med.todayDoseCount;
          for (int i = 0; i < sortedTimes.length; i++) {
            if (i < todayIntakeCount) continue;
            final timeStr = sortedTimes[i];
            final time = _parseRobustTime(timeStr);
            if (time == null) continue;
            final scheduledDate = DateTime(todayStart.year, todayStart.month, todayStart.day, time.hour, time.minute);
            if (scheduledDate.isBefore(now)) continue;
            
            candidateDate = scheduledDate;
            break; 
          }
        }

        if (candidateDate == null && med.reminderTimes.isNotEmpty) {
          final firstTimeActionable = List<String>.from(med.reminderTimes);
          firstTimeActionable.sort((a, b) {
            final tA = _parseRobustTime(a) ?? DateTime(1970, 1, 1, 0, 0);
            final tB = _parseRobustTime(b) ?? DateTime(1970, 1, 1, 0, 0);
            if (tA.hour != tB.hour) return tA.hour.compareTo(tB.hour);
            return tA.minute.compareTo(tB.minute);
          });
          final bestTime = _parseRobustTime(firstTimeActionable.first)!;

          DateTime tomorrow = todayStart.add(const Duration(days: 1));
          DateTime targetDay = medStartN.isAfter(tomorrow) ? medStartN : tomorrow;

          if (medEndN == null || !targetDay.isAfter(medEndN)) {
            candidateDate = DateTime(targetDay.year, targetDay.month, targetDay.day, bestTime.hour, bestTime.minute);
          }
        }

        if (candidateDate != null) {
          if (nextDoseDateTime == null || candidateDate.isBefore(nextDoseDateTime)) {
            nextDoseDateTime = candidateDate;
            nextName = med.name;
          }
        }
      }
      
      if (nextDoseDateTime != null) {
        nextTime = DateFormat.jm(locale).format(nextDoseDateTime).f;
        final diff = nextDoseDateTime.difference(now);
        
        if (diff.isNegative) {
          nextTimeLeft = 'dose_missed'.tr;
        } else {
          if (diff.inDays >= 1) {
            if (diff.inDays == 1) {
              nextTimeLeft = 'tomorrow'.tr;
            } else if (diff.inDays < 7) {
              nextTimeLeft = 'in_x_days'.trParams({'days': diff.inDays.toString()});
            } else {
              nextTimeLeft = DateFormat('d MMMM', locale).format(nextDoseDateTime).f;
            }
          } else {
            final hours = diff.inHours;
            final minutes = (diff.inMinutes % 60).abs();
            if (hours > 0) {
              nextTimeLeft = '${hours.f}${'hours_abbr'.tr} ${minutes.f}${'minutes_abbr'.tr}';
            } else {
              nextTimeLeft = '${minutes.f}${'minutes_abbr'.tr}';
            }
          }
        }
      }
    }

    return MedicationDailyStats(
      taken: taken,
      expected: expected,
      nextTime: nextTime,
      nextName: nextName,
      nextTimeLeft: nextTimeLeft,
    );
  }

  DateTime? _parseRobustTime(String timeStr) {
    try {
      const english = ['0','1','2','3','4','5','6','7','8','9'];
      const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      String normalized = timeStr.trim();
      for (int i = 0; i < english.length; i++) {
        normalized = normalized.replaceAll(arabic[i], english[i]);
      }
      normalized = normalized
          .replaceAll('صباحاً', 'AM')
          .replaceAll('مساءً', 'PM')
          .replaceAll('في الصباح', 'AM')
          .replaceAll('في المساء', 'PM')
          .replaceAll('ص', 'AM')
          .replaceAll('م', 'PM')
          .replaceAll('am', 'AM')
          .replaceAll('pm', 'PM');
          
      return DateFormat.jm().parse(normalized);
    } catch (e) {
      try {
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeStr);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          if (h >= 0 && h < 24 && m >= 0 && m < 60) {
            return DateTime(1970, 1, 1, h, m);
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
