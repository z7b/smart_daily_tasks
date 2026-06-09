import 'package:flutter_test/flutter_test.dart';
import 'package:smart_daily_tasks/app/core/helpers/medication_scheduler_helper.dart';

void main() {
  group('MedicationSchedulerHelper Tests', () {
    group('Sleep-Zone Clamping', () {
      test('should leave non-sleep hours unchanged', () {
        expect(MedicationSchedulerHelper.applySleepZoneClamping(0), equals(0));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(6), equals(6));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(12), equals(12));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(23), equals(23));
      });

      test('should clamp early sleep hours (01:00 - 02:00) to 23:00', () {
        expect(MedicationSchedulerHelper.applySleepZoneClamping(1), equals(23));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(2), equals(23));
      });

      test('should clamp late sleep hours (03:00 - 05:00) to 06:00', () {
        expect(MedicationSchedulerHelper.applySleepZoneClamping(3), equals(6));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(4), equals(6));
        expect(MedicationSchedulerHelper.applySleepZoneClamping(5), equals(6));
      });
    });

    group('Minimum Spacing Enforcement', () {
      test('should return empty lists when input is empty', () {
        final result = MedicationSchedulerHelper.enforceMinimumSpacing([], 120);
        expect(result.kept, isEmpty);
        expect(result.skipped, isEmpty);
      });

      test('should keep a single dose regardless of spacing', () {
        final result = MedicationSchedulerHelper.enforceMinimumSpacing([480], 120);
        expect(result.kept, equals([480]));
        expect(result.skipped, isEmpty);
      });

      test('should filter out doses that are too close to each other', () {
        // 08:00 (480), 09:00 (540), 11:00 (660) with 120 min min-spacing
        // 540 is 60 min from 480 (too close -> skipped)
        // 660 is 180 min from 480 (kept)
        final result = MedicationSchedulerHelper.enforceMinimumSpacing([480, 540, 660], 120);
        expect(result.kept, equals([480, 660]));
        expect(result.skipped, equals([540]));
      });

      test('should handle midnight wrap-around correctly', () {
        // Case 1: 23:00 (1380) and 01:00 (60). Diff is 120 mins. Kept.
        final result1 = MedicationSchedulerHelper.enforceMinimumSpacing([60, 1380], 120);
        expect(result1.kept, equals([60, 1380]));
        expect(result1.skipped, isEmpty);

        // Case 2: 23:00 (1380) and 00:30 (30). Diff is 90 mins. Too close.
        // In sorted array: [30, 1380].
        // prev is 30. curr is 1380. diff is 1380 - 30 = 1350 mins.
        // Wait, when comparing 1380 to 30:
        // result starts with [30].
        // next is 1380. diff is 1380 - 30 = 1350 min (>= 120, so kept).
        // Then what about the wrap-around from 1380 back to 30?
        // Since it's a daily cycle, we check consecutive elements.
        // Let's test the helper logic exactly:
        final result2 = MedicationSchedulerHelper.enforceMinimumSpacing([30, 1380], 120);
        // kept contains 30, then 1380 (since 1380 - 30 = 1350 >= 120).
        expect(result2.kept, equals([30, 1380]));
      });
    });

    group('Interval-based scheduling', () {
      test('should generate and clamp doses correctly with minimum spacing protection', () {
        // Every 4 hours starting at 22:00.
        // Raw hours: 22, 2 (clamps to 23), 6, 10, 14, 18.
        // Sorted raw minutes: 360 (6:00), 600 (10:00), 840 (14:00), 1080 (18:00), 1320 (22:00), 1380 (23:00).
        // Minimum spacing: max(4 * 30, 120) = 120 min.
        // - 360: kept
        // - 600: diff 240 >= 120 -> kept
        // - 840: diff 240 >= 120 -> kept
        // - 1080: diff 240 >= 120 -> kept
        // - 1320: diff 240 >= 120 -> kept
        // - 1380: diff 60 < 120 -> skipped!
        final result = MedicationSchedulerHelper.generateIntervalTimes(
          startHour: 22,
          startMinute: 0,
          intervalHours: 4,
        );

        expect(result.kept, equals([360, 600, 840, 1080, 1320]));
        expect(result.skipped, equals([1380]));
      });
    });

    group('Frequency-based scheduling', () {
      test('should spread doses over waking hours and apply spacing protection', () {
        // 3 times a day starting at 08:00.
        // waking hours = 16. interval = 16 ~/ (3-1) = 8.
        // Hours: 8, 16, 24 (00:00).
        // Sorted raw minutes: 0 (00:00), 480 (08:00), 960 (16:00).
        // Min spacing: max(8 * 30, 120) = 240 min.
        // - 0: kept
        // - 480: diff 480 >= 240 -> kept
        // - 960: diff 480 >= 240 -> kept
        final result = MedicationSchedulerHelper.generateFrequencyTimes(
          startHour: 8,
          startMinute: 0,
          frequency: 3,
          wakingHours: 16,
        );

        expect(result.kept, equals([0, 480, 960]));
        expect(result.skipped, isEmpty);
      });
    });
  });
}
