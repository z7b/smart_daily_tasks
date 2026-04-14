import 'package:isar/isar.dart';
import '../../core/helpers/log_helper.dart';
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

  Future<void> addMedication(Medication medication) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.put(medication);
      });
      talker.info('✅ Medication added: ${medication.name}');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error adding medication');
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.put(medication);
      });
      talker.info('✅ Medication updated: ${medication.name}');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error updating medication');
      rethrow;
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.medications.delete(id);
      });
      talker.info('🗑️ Medication deleted: ID $id');
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error deleting medication');
      rethrow;
    }
  }

  Future<void> toggleMedicationStatus(int id) async {
    try {
      await _isar.writeTxn(() async {
        final med = await _isar.medications.get(id);
        if (med != null) {
          med.isActive = !med.isActive;
          await _isar.medications.put(med);
        }
      });
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error toggling medication status');
    }
  }

  Future<void> logIntake(int id) async {
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
    } catch (e, stack) {
      talker.handle(e, stack, '🔴 Error logging medication intake');
    }
  }

  // Get active medications for a specific date (Harmony Sync)
  Future<List<Medication>> getActiveMedicationsForDate(DateTime date) async {
    return await _isar.medications
        .filter()
        .isActiveEqualTo(true)
        .and()
        .startDateLessThan(date.add(const Duration(days: 1)))
        .findAll();
  }
}
