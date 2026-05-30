import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/medication_model.dart';
import '../../../../core/helpers/number_extension.dart';
import '../../../../widgets/glassy_pin_button.dart';


class MedicationTile extends StatelessWidget {
  final Medication med;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onRecordIntake;
  final VoidCallback onEdit;

  const MedicationTile({
    super.key,
    required this.med,
    required this.index,
    required this.onDelete,
    required this.onRecordIntake,
    required this.onEdit,
  });

  static const Color _themeColor = Color(0xFFFF3B30);

  static const _typeIcons = {
    MedicationType.pill: CupertinoIcons.capsule,
    MedicationType.syrup: CupertinoIcons.drop,
    MedicationType.injection: CupertinoIcons.bandage,
    MedicationType.cream: CupertinoIcons.hand_raised,
    MedicationType.drops: CupertinoIcons.eyedropper,
    MedicationType.other: CupertinoIcons.bandage_fill,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final compliance = med.todayCompliance;
    final complianceColor =
        compliance >= 1.0 ? const Color(0xFF34C759) : _themeColor;

    return Dismissible(
      key: Key('med_${med.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark
              ? theme.cardColor.withValues(alpha: 0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: complianceColor.withValues(alpha: compliance > 0 ? 0.15 : 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 8),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Column(
                children: [
                  // Compliance progress bar at top
                  if (compliance > 0 && compliance < 1.0)
                    LinearProgressIndicator(
                      value: compliance,
                      minHeight: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          complianceColor.withValues(alpha: 0.6)),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type icon with soft glow
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _themeColor.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                  )
                                ],
                              ),
                              child: Icon(
                                _typeIcons[med.type] ?? CupertinoIcons.capsule,
                                color: _themeColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Name + meta info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 19,
                                      letterSpacing: -0.5,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _miniInfoBadge(_getTypeText(med.type),
                                          theme.textTheme.bodySmall?.color),
                                      _miniInfoBadge(
                                          _getInstructionText(med.instruction),
                                          theme.textTheme.bodySmall?.color),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Compliance Ring (Premium Style)
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: compliance,
                                    strokeWidth: 4,
                                    backgroundColor: theme.dividerColor
                                        .withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        complianceColor),
                                  ),
                                  Text(
                                    '${(compliance * 100).toInt().f}%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: complianceColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Dosage & Actions Section (Structured Glass Box)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Reminders Capsule
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.black.withValues(alpha: 0.03),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.alarm_fill,
                                              size: 14, color: _themeColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              med.reminderTimes
                                                  .map((t) => t
                                                      .replaceAll(
                                                          'AM', 'am_short'.tr)
                                                      .replaceAll(
                                                          'PM', 'pm_short'.tr)
                                                      .f)
                                                  .join(' • '),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: theme.textTheme.bodyMedium
                                                    ?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Pin Button
                                  GlassyPinButton(itemType: 'medication', itemId: med.id),
                                  const SizedBox(width: 8),

                                  // Take Dose Button (Dynamic Status)
                                  GestureDetector(
                                    onTap: compliance >= 1.0
                                        ? null
                                        : onRecordIntake,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: compliance >= 1.0
                                            ? const Color(0xFF34C759)
                                                .withValues(alpha: 0.15)
                                            : _themeColor,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: compliance >= 1.0
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: _themeColor.withValues(
                                                      alpha: 0.25),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (compliance >= 1.0)
                                            const Icon(CupertinoIcons.check_mark,
                                                size: 14,
                                                color: Color(0xFF34C759)),
                                          if (compliance >= 1.0)
                                            const SizedBox(width: 6),
                                          Text(
                                            compliance >= 1.0
                                                ? 'done'.tr
                                                : 'take'.tr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: compliance >= 1.0
                                                  ? const Color(0xFF34C759)
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Secondary Info (Dose Count / Status)
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${'doses_remaining'.tr}: ${(med.reminderTimes.length - med.todayDoseCount).f}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Edit button (Clean Minimalist)
                                  GestureDetector(
                                    onTap: onEdit,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _themeColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(CupertinoIcons.pencil,
                                              size: 12, color: _themeColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'edit'.tr,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _themeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Status: Remaining Days (Professional Bottom Badge)
                        if (med.endDate != null && med.remainingDays >= 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    CupertinoIcons.hourglass_bottomhalf_fill,
                                    size: 14,
                                    color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  '${'remaining'.tr}: ${med.remainingDays.f} ${'days'.tr}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeText(MedicationType type) {
    switch (type) {
      case MedicationType.pill:
        return 'pill'.tr;
      case MedicationType.syrup:
        return 'syrup'.tr;
      case MedicationType.injection:
        return 'med_injection'.tr;
      case MedicationType.cream:
        return 'topical'.tr;
      case MedicationType.drops:
        return 'drops'.tr;
      default:
        return 'other'.tr;
    }
  }

  String _getInstructionText(MedicationInstruction ins) {
    switch (ins) {
      case MedicationInstruction.beforeFood:
        return 'before_food'.tr;
      case MedicationInstruction.afterFood:
        return 'after_food'.tr;
      case MedicationInstruction.withFood:
        return 'with_food'.tr;
      case MedicationInstruction.emptyStomach:
        return 'empty_stomach'.tr;
      case MedicationInstruction.beforeSleep:
        return 'before_sleep'.tr;
      default:
        return 'normal'.tr;
    }
  }

  Widget _miniInfoBadge(String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color?.withValues(alpha: 0.1) ?? Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color?.withValues(alpha: 0.8)),
      ),
    );
  }
}
