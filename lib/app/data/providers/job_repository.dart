import 'package:isar/isar.dart';
import '../models/work_profile_model.dart';
import '../models/attendance_log_model.dart';
import '../../core/helpers/log_helper.dart';

class JobRepository {
  final Isar _isar;

  JobRepository(this._isar);

  /// Get the singleton WorkProfile, creating a default one if it doesn't exist
  Future<WorkProfile> getWorkProfile() async {
    final profile = await _isar.workProfiles.get(0);
    if (profile == null) {
      final defaultProfile = WorkProfile();
      await _isar.writeTxn(() => _isar.workProfiles.put(defaultProfile));
      return defaultProfile;
    }
    return profile;
  }

  /// Update the WorkProfile settings with validation
  Future<void> updateWorkProfile(WorkProfile profile) async {
    // Governance: Validate critical fields
    if (profile.salaryDay < 1 || profile.salaryDay > 31) {
      talker.warning('🔴 Invalid salary day: ${profile.salaryDay}');
      return;
    }
    if (profile.startMinutes < 0 || profile.startMinutes >= 1440) {
      talker.warning('🔴 Invalid start time: ${profile.startMinutes} minutes');
      return;
    }
    if (profile.endMinutes < 0 || profile.endMinutes >= 1440) {
      talker.warning('🔴 Invalid end time: ${profile.endMinutes} minutes');
      return;
    }
    await _isar.writeTxn(() => _isar.workProfiles.put(profile));
  }

  /// Log daily attendance (Atomic to prevent duplicate indexing anomalies)
  Future<void> logAttendance(AttendanceLog log) async {
    await _isar.writeTxn(() async {
      final startOfDay = DateTime(log.date.year, log.date.month, log.date.day);
      final existing = await _isar.attendanceLogs.filter().dateEqualTo(startOfDay).findFirst();
      
      if (existing != null) {
        log.id = existing.id; // Override to prevent duplicate record insertion exception
      }
      
      await _isar.attendanceLogs.put(log);
    });
  }

  /// Get attendance log for a specific date
  Future<AttendanceLog?> getLogForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return await _isar.attendanceLogs.filter().dateEqualTo(startOfDay).findFirst();
  }

  /// Get attendance history for a range (e.g., Monthly/Yearly)
  Future<List<AttendanceLog>> getLogsInRange(DateTime start, DateTime end) async {
    // ✅ Concept D2 Fix: Reverse range recovery
    if (start.isAfter(end)) {
       final temp = start;
       start = end;
       end = temp;
    }
    final normalStart = DateTime(start.year, start.month, start.day);
    final normalEnd = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    return await _isar.attendanceLogs
        .filter()
        .dateBetween(normalStart, normalEnd, includeLower: true, includeUpper: false)
        .sortByDateDesc()
        .findAll();
  }

  /// Get statistical summary for a period
  Future<Map<AttendanceStatus, int>> getStatsSummary(DateTime start, DateTime end) async {
    final logs = await getLogsInRange(start, end);
    final stats = <AttendanceStatus, int>{};
    
    // ✅ Concept P2 Fix: Division guard logic (returns empty map if no logs exist)
    if (logs.isEmpty) return stats;

    for (var status in AttendanceStatus.values) {
      stats[status] = logs.where((l) => l.status == status).length;
    }
    
    return stats;
  }
}
