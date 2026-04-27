import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/appointments_controller.dart';
import '../controllers/appointment_form_controller.dart';
import 'widgets/appointment_tile.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/appointment_model.dart';

class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final medicalBlue = const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'doctor_appointments'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: medicalBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(CupertinoIcons.add, size: 24),
                  onPressed: () => Get.toNamed(Routes.ADD_APPOINTMENT),
                  color: medicalBlue,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('upcoming'.tr, theme, medicalBlue),
                  Obx(() {
                    if (controller.upcomingAppointments.isEmpty) {
                      return _buildEmptyState('no_appointments'.tr, theme, medicalBlue);
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.upcomingAppointments.length,
                      itemBuilder: (context, index) {
                        final appt = controller.upcomingAppointments[index];
                        return AppointmentTile(
                          appointment: appt,
                          onTap: () => _navigateToEdit(appt),
                          onDelete: () => controller.deleteAppointment(appt.id),
                          onComplete: () => controller.markAsCompleted(appt.id),
                          onPostpone: () => _showPostponeSheet(context, appt),
                        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
                      },
                    );
                  }),
                  const SizedBox(height: 40),
                  Obx(() {
                    if (controller.pastAppointments.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('past'.tr, theme, medicalBlue),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.pastAppointments.length,
                          itemBuilder: (context, index) {
                            final appt = controller.pastAppointments[index];
                            return AppointmentTile(
                              appointment: appt,
                              onTap: () {},
                              onDelete: () => controller.deleteAppointment(appt.id),
                              onComplete: () {},
                            ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ H-1: Navigate to edit an existing appointment
  void _navigateToEdit(Appointment appt) {
    Get.toNamed(Routes.ADD_APPOINTMENT);
    // Load appointment data into form controller after navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.isRegistered<AppointmentFormController>()) {
        Get.find<AppointmentFormController>().loadAppointment(appt);
      }
    });
  }

  /// ✅ H-2: Show postpone bottom sheet
  void _showPostponeSheet(BuildContext context, Appointment appt) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'postpone_appointment'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'postpone_by'.tr,
                style: TextStyle(color: theme.disabledColor),
              ),
              const SizedBox(height: 20),
              _buildPostponeOption(
                context,
                icon: CupertinoIcons.clock,
                label: '1 ${'hour'.tr}',
                onTap: () {
                  Get.back();
                  Get.find<AppointmentsController>().postponeAppointment(appt.id, const Duration(hours: 1));
                },
              ),
              _buildPostponeOption(
                context,
                icon: CupertinoIcons.sun_max,
                label: 'one_day'.tr,
                onTap: () {
                  Get.back();
                  Get.find<AppointmentsController>().postponeAppointment(appt.id, const Duration(days: 1));
                },
              ),
              _buildPostponeOption(
                context,
                icon: CupertinoIcons.calendar,
                label: 'one_week'.tr,
                onTap: () {
                  Get.back();
                  Get.find<AppointmentsController>().postponeAppointment(appt.id, const Duration(days: 7));
                },
              ),
              _buildPostponeOption(
                context,
                icon: CupertinoIcons.pencil,
                label: 'custom'.tr,
                onTap: () async {
                  Get.back();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: appt.scheduledAt.add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    final diff = date.difference(appt.scheduledAt);
                    Get.find<AppointmentsController>().postponeAppointment(appt.id, diff);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostponeOption(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, Color medicalBlue) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: medicalBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: medicalBlue.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme, Color medicalBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: medicalBlue.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: medicalBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_minus, 
              size: 48, 
              color: medicalBlue.withValues(alpha: 0.4)
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.disabledColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
