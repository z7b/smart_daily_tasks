import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
import '../../core/helpers/result.dart';
import '../models/medication_model.dart';

class MedicationRepository {
  final Isar _isar;

  MedicationRepository(this._isar) {
    talker.info('💊 MedicationRepository initialized');
  }

  Stream<List<Medication>> watchAllMedications() {
    return _isar.medications.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Future<List<Medication>> getAllMedications() async {
    return await _isar.medications.where().sortByCreatedAtDesc().findAll();
  }

  Future<Result<void>> addMedication(Medication medication) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.put(medication);
      });
      talker.info('✅ Medication added: ${medication.name}');
      return Result.successVoid();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error adding medication');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> updateMedication(Medication medication) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.put(medication);
      });
      talker.info('✅ Medication updated: ${medication.name}');
      return Result.successVoid();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error updating medication');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> deleteMedication(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.delete(id);
      });
      talker.info('🗑️ Medication deleted: ID $id');
      return Result.successVoid();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error deleting medication');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> toggleMedicationStatus(int id) async {
    try {
      await _isar.writeTxn(() async {
        final med = await _isar.medications.get(id);
        if (med != null) {
          med.isActive = !med.isActive;
          await _isar.medications.put(med);
        }
      });
      return Result.successVoid();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error toggling medication status');
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> logIntake(int id) async {
    try {
      await _isar.writeTxn(() async {
        final med = await _isar.medications.get(id);
        if (med != null) {
          final history = List<DateTime>.from(med.intakeHistory);
          history.add(DateTime.now());
          med.intakeHistory = history;
          await _isar.medications.put(med);
        }
      });
      talker.info('🕒 Medication intake logged for ID $id');
      return Result.successVoid();
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error logging medication intake');
      return Result.failure(e.toString());
    }
  }

  // Get active medications for a specific date (Harmony Sync)
  Future<List<Medication>> getActiveMedicationsForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final nextDay = normalizedDate.add(const Duration(days: 1));
    
    return await _isar.medications
        .filter()
        .isActiveEqualTo(true)
        .and()
        .startDateLessThan(nextDay) // started on or before this day
        .and()
        .group((q) => q
            .endDateIsNull() // no end date (perpetual)
            .or()
            .endDateGreaterThan(normalizedDate) // ends after this day's midnight
        )
        .findAll();
  }
}
