import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/bottom_sheet_helper.dart';
import '../../../data/models/calendar_event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/medication_model.dart';
import '../controllers/calendar_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../core/helpers/number_extension.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: AppTheme.primary, size: 28),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'calendar'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
                  onPressed: () => _showAddEventSheet(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildCalendar(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: _buildEventsList(context),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final settings = Get.find<SettingsController>();
      // ✅ Expert Fix: Explicitly mapping all supported days to StartingDayOfWeek
      StartingDayOfWeek startDay;
      switch (settings.firstDayOfWeek.value) {
        case 'monday':
          startDay = StartingDayOfWeek.monday;
          break;
        case 'saturday':
          startDay = StartingDayOfWeek.saturday;
          break;
        case 'sunday':
        default:
          startDay = StartingDayOfWeek.sunday;
          break;
      }

      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: controller.focusedDay.value,
          selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
          calendarFormat: controller.calendarFormat.value,
          startingDayOfWeek: startDay,
          onDaySelected: controller.onDaySelected,
          onFormatChanged: controller.onFormatChanged,
          eventLoader: controller.getEventsForDay,
          locale: Get.locale?.languageCode,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return Center(
                child: Text(
                  NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.3)),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              return Center(
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      NumberFormat.decimalPattern(Get.locale?.languageCode).format(day.day).f,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(CupertinoIcons.chevron_left, color: theme.textTheme.bodyLarge?.color, size: 20),
            rightChevronIcon: Icon(CupertinoIcons.chevron_right, color: theme.textTheme.bodyLarge?.color, size: 20),
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
            weekendTextStyle: const TextStyle(color: Color(0xFFFF3B30)),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold),
            weekendStyle: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold),
          ),
        ),
      );
    });
  }

  Widget _buildEventsList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverToBoxAdapter(
          child: Center(child: CupertinoActivityIndicator(radius: 16)),
        );
      }

      if (controller.selectedEvents.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  CupertinoIcons.calendar_badge_minus,
                  size: 60,
                  color: theme.dividerColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'no_tasks_today'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ).animate().fadeIn(),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = controller.selectedEvents[index];
            return _buildUnifiedCard(item, index, context);
          },
          childCount: controller.selectedEvents.length,
        ),
      );
    });
  }

  Widget _buildUnifiedCard(dynamic item, int index, BuildContext context) {
    if (item is CalendarEvent) return _buildEventCard(item, index, context);
    if (item is Task) return _buildTaskCard(item, index, context);
    if (item is Medication) return _buildMedicationCard(item, index, context);
    return const SizedBox.shrink();
  }

  Widget _buildEventCard(CalendarEvent event, int index, BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(event.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteEvent(event.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: event.startTime != null ? AppTheme.primary : const Color(0xFFBF5AF2),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, size: 14, color: AppTheme.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRange(event),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideY(begin: 0.1);
  }

  Widget _buildTaskCard(Task task, int index, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: task.status == TaskStatus.completed ? Colors.green.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () => Get.toNamed('/tasks'),
        leading: Icon(
          task.status == TaskStatus.completed ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
          color: task.status == TaskStatus.completed ? Colors.green : AppTheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
            color: task.status == TaskStatus.completed ? theme.dividerColor : theme.textTheme.titleLarge?.color,
          ),
        ),
        subtitle: Text('task'.tr, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1);
  }

  Widget _buildMedicationCard(Medication med, int index, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: () => Get.toNamed('/medication'),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(CupertinoIcons.capsule_fill, color: Colors.red, size: 20),
        ),
        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('medication'.tr, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
        trailing: CircularProgressIndicator(
          value: med.todayCompliance,
          strokeWidth: 3,
          backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale();
  }

  String _formatTimeRange(CalendarEvent event) {
    if (event.startTime == null) return 'all_day'.tr;
    final locale = Get.locale?.languageCode;
    final startStr = DateFormat.jm(locale).format(event.startTime!);
    
    if (event.endTime == null) return startStr.f;
    return '${startStr.f} - ${DateFormat.jm(locale).format(event.endTime!).f}';
  }

  void _showAddEventSheet(BuildContext context) {
    // Clear old data when opening sheet
    controller.titleController.clear();
    controller.descriptionController.clear();
    
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String? errorMessage;

    BottomSheetHelper.showSafeBottomSheet(
      builder: (context, setState) {
        final theme = Theme.of(context);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'new_event'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title Field
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: errorMessage != null 
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : theme.dividerColor.withValues(alpha: 0.05)
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller.titleController,
                  focusNode: controller.titleFocusNode,
                  autofocus: true,
                  onChanged: (_) {
                    if (errorMessage != null) setState(() => errorMessage = null);
                  },
                  onSubmitted: (_) => FocusScope.of(context).requestFocus(controller.descriptionFocusNode),
                  decoration: InputDecoration(
                    hintText: 'title_hint'.tr,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              
              // Description Field
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller.descriptionController,
                  focusNode: controller.descriptionFocusNode,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'notes_hint'.tr,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
              const SizedBox(height: 24),

              // Time Selectors
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(CupertinoIcons.time, color: AppTheme.primary),
                      title: Text('start_time'.tr),
                      trailing: Text(
                        startTime?.format(context) ?? 'none'.tr,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setState(() => startTime = time);
                      },
                    ),
                    Divider(height: 1, indent: 56, color: theme.dividerColor.withValues(alpha: 0.05)),
                    ListTile(
                      leading: const Icon(CupertinoIcons.time_solid, color: AppTheme.primary),
                      title: Text('end_time'.tr),
                      trailing: Text(
                        endTime?.format(context) ?? 'none'.tr,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                        if (time != null) setState(() => endTime = time);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  return ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (controller.titleController.text.trim().isEmpty) {
                              setState(() => errorMessage = 'title_required'.tr);
                              return;
                            }
                            controller.addCalendarEvent(
                              title: controller.titleController.text.trim(),
                              description: controller.descriptionController.text.trim(),
                              startTime: startTime,
                              endTime: endTime,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                    child: isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'add_event'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
