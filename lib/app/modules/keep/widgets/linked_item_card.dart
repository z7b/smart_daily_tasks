import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../data/models/keep_note_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/book_model.dart';

import '../../tasks/controllers/task_list_controller.dart';
import '../../tasks/views/widgets/task_tile.dart';
import '../../../data/providers/task_repository.dart';

import '../../medication/controllers/medication_controller.dart';
import '../../medication/views/widgets/medication_tile.dart';
import '../../../data/providers/medication_repository.dart';

import '../../appointments/controllers/appointments_controller.dart';
import '../../appointments/views/widgets/appointment_tile.dart';
import '../../../data/providers/appointment_repository.dart';

import '../../books/controllers/book_controller.dart';
import '../../books/views/widgets/book_tile.dart';

import '../controllers/keep_controller.dart';

class LinkedItemCard extends StatelessWidget {
  final KeepNote note;
  final int index;

  const LinkedItemCard({
    super.key,
    required this.note,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final type = note.linkedItemType;
    final id = note.linkedItemId;
    if (type == null || id == null) {
      return const SizedBox.shrink();
    }

    final isar = Get.find<Isar>();

    // Ensure controllers are registered before rendering tiles
    _ensureControllers();

    Widget child;

    // Determine what to render based on type
    switch (type) {
      case 'task':
        final task = isar.tasks.getSync(id);
        if (task == null) return _buildDeletedItem(context);
        final taskCtrl = Get.find<TaskListController>();
        child = _buildScaledTile(
          TaskTile(
            task: task,
            isBoardMode: true,
            onTap: () => Get.toNamed('/tasks'),
            onCompleted: (val) {
               taskCtrl.markTaskCompleted(task);
            },
            onEdit: () {},
            onCancel: () {},
            onDelete: () {
              taskCtrl.deleteTask(task);
              Get.find<KeepController>().deleteNote(note.id);
            },
          ),
        );
        break;

      case 'medication':
        final med = isar.medications.getSync(id);
        if (med == null) return _buildDeletedItem(context);
        final medCtrl = Get.find<MedicationController>();
        child = GestureDetector(
          onTap: () => Get.toNamed('/medication'),
          child: _buildScaledTile(
            MedicationTile(
              med: med,
              index: index,
              isBoardMode: true,
              onDelete: () {
                medCtrl.deleteMedication(med);
                Get.find<KeepController>().deleteNote(note.id);
              },
              onRecordIntake: () => medCtrl.recordIntake(med),
              onEdit: () {}, 
            ),
          ),
        );
        break;

      case 'appointment':
        final appt = isar.appointments.getSync(id);
        if (appt == null) return _buildDeletedItem(context);
        final apptCtrl = Get.find<AppointmentsController>();
        child = _buildScaledTile(
          AppointmentTile(
            appointment: appt,
            isBoardMode: true,
            onTap: () => Get.toNamed('/appointments'),
            onComplete: () {
              apptCtrl.markAsCompleted(appt.id);
            },
            onDelete: () {
              apptCtrl.deleteAppointment(appt.id);
              Get.find<KeepController>().deleteNote(note.id);
            },
          ),
        );
        break;

      case 'book':
        final book = isar.books.getSync(id);
        if (book == null) return _buildDeletedItem(context);
        final bookCtrl = Get.find<BookController>();
        child = GestureDetector(
          onTap: () => Get.toNamed('/books'),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: BookTile(
              book: book,
              index: index,
              onDelete: () {
                bookCtrl.deleteBook(book);
                Get.find<KeepController>().deleteNote(note.id);
              },
              onEdit: () {}, 
              onRead: () => Get.toNamed('/books'), 
              onStatusChange: (status) {
                if (status) {
                  bookCtrl.markAsCompleted(book);
                }
              },
            ),
          ),
        );
        break;

      default:
        child = const SizedBox.shrink();
    }

    final ctrl = Get.find<KeepController>();

    return Obx(() {
      final isSelected = ctrl.selectedNoteIds.contains(note.id);
      final isSelection = ctrl.isSelectionMode;

      return GestureDetector(
        onTap: () {
          if (isSelection) {
            ctrl.toggleSelection(note.id);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.blueAccent, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
          ),
          child: AbsorbPointer(
            absorbing: isSelection,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (note.isPinned)
                  Positioned(
                    top: 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildPinWidget(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPinWidget() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildScaledTile(Widget tile) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 320, // Reduced simulated width to increase visual scale (makes it larger)
        child: tile,
      ),
    );
  }

  void _ensureControllers() {
    final isar = Get.find<Isar>();
    if (!Get.isRegistered<TaskListController>()) {
      Get.lazyPut(() => TaskListController(Get.put(TaskRepository(isar))));
    }
    if (!Get.isRegistered<MedicationController>()) {
      Get.put(MedicationRepository(isar));
      Get.lazyPut(() => MedicationController());
    }
    if (!Get.isRegistered<AppointmentsController>()) {
      Get.put(AppointmentRepository(isar));
      Get.lazyPut(() => AppointmentsController());
    }
    if (!Get.isRegistered<BookController>()) {
      Get.lazyPut(() => BookController());
    }
  }

  Widget _buildDeletedItem(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'item_deleted_or_missing'.tr,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
               Get.find<KeepController>().deleteNote(note.id);
            },
          )
        ],
      ),
    );
  }
}
