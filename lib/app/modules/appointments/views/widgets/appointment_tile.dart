import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../../data/models/appointment_model.dart';
import '../../../../core/services/appointment_time_service.dart';

class AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback? onPostpone;

  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.onDelete,
    required this.onComplete,
    this.onPostpone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = appointment.color != null ? Color(appointment.color!) : theme.primaryColor;
    final isCompleted = appointment.status == AppointmentStatus.completed;
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final isInactive = isCompleted || isCancelled;

    final medicalBlue = const Color(0xFF4A90E2);
    final isToday = appointment.scheduledAt.year == DateTime.now().year &&
                    appointment.scheduledAt.month == DateTime.now().month &&
                    appointment.scheduledAt.day == DateTime.now().day;

    return Dismissible(
      key: Key(appointment.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('delete'.tr),
            content: Text('confirm_delete_appointment'.tr),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('delete'.tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) => onDelete(),
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isInactive 
                  ? theme.dividerColor.withValues(alpha: 0.1) 
                  : (isToday ? medicalBlue.withValues(alpha: 0.3) : color.withValues(alpha: 0.15)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isToday ? medicalBlue : color).withValues(alpha: isDark ? 0.05 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Medical Side Indicator (Gradient)
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isInactive ? theme.disabledColor : (isToday ? medicalBlue : color),
                        isInactive ? theme.disabledColor.withValues(alpha: 0.5) : (isToday ? medicalBlue.withValues(alpha: 0.7) : color.withValues(alpha: 0.7)),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge Row
                        Row(
                          children: [
                            _buildStatusBadge(context, appointment, isToday),
                            const Spacer(),
                            if (!isInactive) ...[
                              if (onPostpone != null)
                                _CircleActionButton(
                                  icon: CupertinoIcons.clock,
                                  onPressed: onPostpone!,
                                  color: Colors.orange,
                                ),
                              const SizedBox(width: 8),
                              _CircleActionButton(
                                icon: CupertinoIcons.checkmark,
                                onPressed: onComplete,
                                color: medicalBlue,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Doctor and Patient info
                        if (appointment.patientName.isNotEmpty) ...[
                          Text(
                            '${'patient'.tr}: ${appointment.patientName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: medicalBlue.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        
                        Text(
                          appointment.doctorName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isInactive ? theme.disabledColor : theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        
                        if (appointment.clinicName?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(CupertinoIcons.building_2_fill, size: 14, color: theme.disabledColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  appointment.clinicName!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.disabledColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 16),

                        // Time Badge
                        Builder(
                          builder: (context) {
                            final timeService = Get.find<AppointmentTimeService>();
                            final badgeColor = timeService.getBadgeColor(appointment.scheduledAt, appointment.status, theme);
                            final smartLabel = timeService.getSmartTimeLabel(appointment.scheduledAt, appointment.status);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.1), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.time_solid, size: 14, color: badgeColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    smartLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                  if (appointment.alarmEnabled) ...[
                                    const SizedBox(width: 8),
                                    Icon(CupertinoIcons.alarm_fill, size: 12, color: badgeColor),
                                  ],
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Appointment appt, bool isToday) {
    String label = 'upcoming'.tr;
    Color color = const Color(0xFF4A90E2);
    IconData icon = CupertinoIcons.calendar;

    if (appt.status == AppointmentStatus.completed) {
      label = 'completed'.tr;
      color = Colors.green;
      icon = CupertinoIcons.checkmark_seal_fill;
    } else if (appt.status == AppointmentStatus.cancelled) {
      label = 'cancelled'.tr;
      color = Colors.red;
      icon = CupertinoIcons.xmark_circle_fill;
    } else if (isToday) {
      label = 'today'.tr;
      color = const Color(0xFF4A90E2);
      icon = CupertinoIcons.star_fill;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _CircleActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
