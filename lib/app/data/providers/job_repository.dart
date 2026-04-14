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

  /// Update the WorkProfile settings
  Future<void> updateWorkProfile(WorkProfile profile) async {
    await _isar.writeTxn(() => _isar.workProfiles.put(profile));
  }

  /// Log daily attendance
  Future<void> logAttendance(AttendanceLog log) async {
    await _isar.writeTxn(() => _isar.attendanceLogs.put(log));
  }

  /// Get attendance log for a specific date
  Future<AttendanceLog?> getLogForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return await _isar.attendanceLogs.filter().dateEqualTo(startOfDay).findFirst();
  }

  /// Get attendance history for a range (e.g., Monthly/Yearly)
  Future<List<AttendanceLog>> getLogsInRange(DateTime start, DateTime end) async {
    return await _isar.attendanceLogs
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Get statistical summary for a period
  Future<Map<AttendanceStatus, int>> getStatsSummary(DateTime start, DateTime end) async {
    final logs = await getLogsInRange(start, end);
    final stats = <AttendanceStatus, int>{};
    
    for (var status in AttendanceStatus.values) {
      stats[status] = logs.where((l) => l.status == status).length;
    }
    
    return stats;
  }
}
