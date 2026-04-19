import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:smart_daily_tasks/app/data/models/task_model.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';

import 'package:smart_daily_tasks/app/modules/settings/views/settings_view.dart';
import 'package:smart_daily_tasks/app/modules/home/controllers/home_controller.dart';
import 'package:smart_daily_tasks/app/modules/home/widgets/quick_log_strip.dart';
import 'package:smart_daily_tasks/app/modules/home/widgets/productivity_chart.dart';
import 'package:smart_daily_tasks/app/modules/home/widgets/floating_navigation_bar.dart';
import 'package:smart_daily_tasks/app/routes/app_routes.dart';
import 'package:smart_daily_tasks/app/modules/home/views/spaces_view.dart';
import 'package:smart_daily_tasks/app/data/services/health_service.dart';
import 'package:smart_daily_tasks/app/modules/job/controllers/job_controller.dart';
import 'package:smart_daily_tasks/app/core/helpers/number_extension.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          Obx(() {
            switch (controller.currentIndex.value) {
              case 0:
                return _buildDashboard(context);
              case 1:
                return const SpacesView();
              case 2:
                return const SettingsView();
              default:
                return _buildDashboard(context);
            }
          }),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _buildWelcomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 12),
            child: Obx(
              () => QuickLogStrip(
                completedDays: controller.completedDays,
                selectedDate: controller.selectedDate.value,
                onDaySelected: controller.onDateSelected,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildMoodSection(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildSalaryHomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildNextShiftHomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildStepsHomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildMedicationHomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildTaskHomeCard(context),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _buildReadingCard(context),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          sliver: SliverToBoxAdapter(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio:
                  1.2, // ✅ Phase 4: More defensive ratio for large fonts
              children: [
                Obx(
                  () => _buildBentoItem(
                    context,
                    'notes'.tr,
                    '${controller.noteCount.value.f} ${'entries'.tr}',
                    Icons.edit_note,
                    const Color(0xFFFF9500),
                    Routes.NOTES,
                  ),
                ),
                Obx(
                  () => _buildBentoItem(
                    context,
                    'journal'.tr,
                    '${controller.journalCount.value.f} ${'logs'.tr}',
                    Icons.book,
                    const Color(0xFF34C759),
                    Routes.JOURNAL,
                  ),
                ),
                Obx(
                  () => _buildBentoItem(
                    context,
                    'bookmarks'.tr,
                    '${controller.bookmarkCount.value.f} ${'saved'.tr}',
                    Icons.bookmark,
                    const Color(0xFFFF3B30),
                    Routes.BOOKMARKS,
                  ),
                ),
                Obx(
                  () => _buildBentoItem(
                    context,
                    'my_library'.tr,
                    '${controller.bookCount.value.f} ${'books'.tr}',
                    Icons.menu_book,
                    const Color(0xFF5E5CE6),
                    Routes.BOOKS,
                  ),
                ),
                Obx(
                  () => _buildBentoItem(
                    context,
                    'calendar'.tr,
                    '${controller.calendarEventCount.value.f} ${'events'.tr}',
                    Icons.calendar_month,
                    const Color(0xFFBF5AF2),
                    Routes.CALENDAR,
                  ),
                ),

                Obx(
                  () => _buildBentoItem(
                    context,
                    'my_steps'.tr,
                    '${controller.stepsCount.value.f} ${'steps'.tr}',
                    Icons.directions_walk,
                    Colors.tealAccent,
                    Routes.STEPS,
                  ),
                ),
                Obx(
                  () => _buildBentoItem(
                    context,
                    'my_job'.tr,
                    '${controller.daysUntilSalary.value.f} ${'days_left'.tr}',
                    Icons.work_outline,
                    const Color(0xFF5E5CE6),
                    Routes.JOB,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100, // ✅ Slightly taller for double-text
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      controller
                          .greetingKey
                          .value
                          .tr, // ✅ Key greeting (Good Morning)
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  Obx(
                    () => Text(
                      controller
                          .greetingMsg
                          .value
                          .tr, // ✅ Dynamic Message (Dhikr, Smile, etc.)
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Get.toNamed('/assistant'),
              icon: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF5E5CE6),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(BuildContext context) {
    return Obx(() {
      final hasBook = controller.currentBookTitle.value.isNotEmpty;
      if (!hasBook && controller.bookCount.value == 0) return const SizedBox();

      return GestureDetector(
        onTap: () => Get.toNamed(Routes.BOOKS),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF5E5CE6).withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF5E5CE6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'my_library'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (hasBook)
                    Text(
                      '${(controller.currentBookProgress.value.clamp(0.0, 1.0) * 100).toInt().f}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E5CE6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasBook) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.currentBookTitle.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'reading_goal_msg'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E5CE6).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'read_verb'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5E5CE6),
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.currentBookProgress.value.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF5E5CE6).withAlpha(20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF5E5CE6),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ] else ...[
                // Just a placeholder if they have books but no active reading
                const Text(
                  'No active book currently reading',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBentoItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => route.isNotEmpty ? Get.toNamed(route) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Obx(
            () => Text(
              controller.moodEmoji.value,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mood_tracker'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    '${'dominant_mood'.tr}: ${controller.weeklyMoodTrend.value.tr}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_graph,
            color: Theme.of(context).primaryColor.withAlpha(50),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSalaryHomeCard(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final days = controller.daysUntilSalary.value;
      final now = DateTime.now();

      // ✅ Concept M2/C1 Fix: Stability over time. Show Progress in current month cycle.
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final elapsedDays = now.day; // Progress through current calendar month
      final progress = (elapsedDays / daysInMonth).clamp(0.0, 1.0);

      return GestureDetector(
        onTap: () => Get.toNamed(Routes.JOB),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5E5CE6).withAlpha(200),
                const Color(0xFFBF5AF2).withAlpha(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.money_dollar_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'salary_countdown'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${days.f} ${'days_left'.tr}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withAlpha(40),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStepsHomeCard(BuildContext context) {
    final healthService = Get.find<HealthService>();

    return Obx(() {
      final isAuthorized = healthService.isAuthorized.value;
      final isConnecting = healthService.isConnecting.value;

      return GestureDetector(
        onTap: isAuthorized ? () => Get.toNamed(Routes.STEPS) : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.tealAccent.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'steps_today'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (isAuthorized)
                    Text(
                      '${controller.stepsCount.value.f} / ${controller.stepsGoal.value.f}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isAuthorized)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isConnecting
                        ? null
                        : () => controller.connectHealth(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.tealAccent.withAlpha(20),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.tealAccent,
                            ),
                          )
                        : Text(
                            'connect_fit'.tr,
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else
                LinearProgressIndicator(
                  value: controller.stepsProgress.value,
                  backgroundColor: Colors.tealAccent.withAlpha(20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.tealAccent,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNextShiftHomeCard(BuildContext context) {
    if (!Get.isRegistered<JobController>()) return const SizedBox();
    final jobCtrl = Get.find<JobController>();
    return Obx(() {
      try {
        final shiftDetails = jobCtrl.getNextShiftDetails();
        if (shiftDetails == null && jobCtrl.totalMandatedDays.value == 0) return const SizedBox();

        final isActive = shiftDetails?['isActive'] as bool? ?? false;
        final start = shiftDetails?['start'] as DateTime?;
        final end = shiftDetails?['end'] as DateTime?;
        final now = DateTime.now();

        String timeLeftStr = '';
        if (shiftDetails != null) {
          if (isActive) {
            final left = end!.difference(now);
            timeLeftStr = left.inHours > 0
                ? '${left.inHours}h ${left.inMinutes % 60}m'
                : '${left.inMinutes}m';
          } else {
            final wait = start!.difference(now);
            timeLeftStr = wait.inDays > 0
                ? '${wait.inDays.f}${'d'.tr} ${(wait.inHours % 24).f}${'h'.tr}'
                : (wait.inHours > 0
                    ? '${wait.inHours.f}${'h'.tr} ${(wait.inMinutes % 60).f}${'m'.tr}'
                    : '${wait.inMinutes.f}${'m'.tr}');
          }
        }

        final color = const Color(0xFF5E5CE6); // Job Theme (Deep Purple)

        // Attendance Stats for Header
        final presentCount =
            jobCtrl.statsSummary[AttendanceStatus.present] ?? 0;
        final totalDays = jobCtrl.totalMandatedDays.value;

        return GestureDetector(
          onTap: () => Get.toNamed(Routes.JOB),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: color.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Header: Icon, Label, and Counter =====
                Row(
                  children: [
                    Icon(CupertinoIcons.briefcase_fill, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'my_job'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (totalDays > 0)
                      Text(
                        '${presentCount.f} / ${totalDays.f}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== Body: Work Identity & Shift Details =====
                if (shiftDetails != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company & Position
                            Text(
                              '${jobCtrl.profile.value.companyName ?? 'no_company'.tr} • ${jobCtrl.profile.value.jobPosition ?? 'job_position'.tr}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Dynamic Countdown Title
                            Text(
                              isActive
                                  ? '${'ends'.tr}: $timeLeftStr'
                                  : '${'starts'.tr}: $timeLeftStr',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Precise Schedule
                            Text(
                              '${DateFormat.EEEE(Get.locale?.languageCode).format(start!).f} • ${TimeOfDay.fromDateTime(start).format(context).f} - ${TimeOfDay.fromDateTime(end!).format(context).f}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Time Box Overlay
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (isActive ? Colors.green : color)
                                  .withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'active_shift'.tr : 'upcoming_shift'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green : color,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: const Duration(seconds: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // No upcoming shift placeholder
                  const Text(
                    'No active or upcoming shifts scheduled.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],

                // ===== Footer: Attendance Progress Bar =====
                LinearProgressIndicator(
                  value: jobCtrl.attendanceRate.value > 0
                      ? jobCtrl.attendanceRate.value.clamp(0.0, 1.0)
                      : 1.0,
                  backgroundColor: color.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        );
      } catch (_) {
        return const SizedBox();
      }
    });
  }


  Widget _buildMedicationHomeCard(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => Get.toNamed('/medication'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.redAccent.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== الرأس: الأيقونة والعنوان والعداد =====
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.heart_fill,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'my_medications'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.medTakenDoses.value} / ${controller.medExpectedDoses.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== تفاصيل العلاج القادم (Redesigned with Professional Glassmorphism) =====
              if (controller.nextMedicationTime.value.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // النص: الاسم والوقت المتبقي
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                controller.nextMedicationName.value,
                                style: const TextStyle(
                                  fontSize: 17, // Increased from 16
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            if (controller.nextMedicationTimeLeft.value.isNotEmpty)
                              Row(
                                children: [
                                  Icon(CupertinoIcons.timer, size: 12, color: Colors.grey.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${'remaining'.tr}: ${controller.nextMedicationTimeLeft.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // الوقت: محاط بكبسولة زجاجية احترافية
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Text(
                          controller.nextMedicationTime.value,
                          style: const TextStyle(
                            fontSize: 15, // Increased from 13
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2)),
                    ],
                  ),
                ),
              ],

              // ===== شريط التقدم =====
              LinearProgressIndicator(
                value: controller.medExpectedDoses.value > 0
                    ? (controller.medTakenDoses.value /
                              controller.medExpectedDoses.value)
                          .clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: Colors.redAccent.withAlpha(20),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.redAccent,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHomeCard(BuildContext context) {
    const accentColor = Color(0xFF007AFF); // Blue

    return Obx(
      () => GestureDetector(
        onTap: () => Get.toNamed(Routes.TASKS),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: accentColor.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== الرأس: الأيقونة والعنوان والعداد =====
              Row(
                children: [
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tasks'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // ✅ Safety Guard: Prevent "0/0" when all tasks cancelled
                  Builder(
                    builder: (_) {
                      final activeTasks =
                          controller.taskCount.value -
                          controller.cancelledTasksCount.value;
                      return Text(
                        activeTasks > 0
                            ? '${controller.completedTasksCount.value} / $activeTasks'
                            : controller.taskCount.value > 0
                            ? '- / -'
                            : '0',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== تفاصيل المهمة القادمة =====
              if (controller.nextTaskTitle.value.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // النص: الاسم والوقت المتبقي والتاريخ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الأولوية (نقطة ملونة) + الاسم
                          Row(
                            children: [
                              Obx(
                                () => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        controller.nextTaskPriority.value ==
                                            TaskPriority.high
                                        ? Colors.redAccent
                                        : controller.nextTaskPriority.value ==
                                              TaskPriority.medium
                                        ? accentColor
                                        : Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.nextTaskTitle.value,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // الوقت المتبقي
                          if (controller.nextTaskTimeLeft.value.isNotEmpty)
                            Text(
                              '${'remaining'.tr}: ${controller.nextTaskTimeLeft.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),

                          // التاريخ الكامل
                          Text(
                            controller.nextTaskFullDate.value,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // الوقت: مع Shimmer Animation
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            controller.nextTaskEndTime.value.isNotEmpty
                                ? '${controller.nextTaskTime.value} - ${controller.nextTaskEndTime.value}'
                                : controller.nextTaskTime.value,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ===== شريط التقدم =====
              LinearProgressIndicator(
                value: controller.taskCount.value > 0
                    ? ((controller.taskCount.value -
                                  controller.tasksLeftCount.value) /
                              controller.taskCount.value)
                          .clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: accentColor.withAlpha(20),
                valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF007AFF), const Color(0xFF5E5CE6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withAlpha(60),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'dashboard_head'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            'unified_status'.trParams({
                              'percent':
                                  (controller.progressPercentage.value * 100)
                                      .toInt()
                                      .toString(),
                            }),
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 32),

              // Unified Master Progress Bar
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Obx(
                      () => AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutCubic,
                        height: 12,
                        width:
                            constraints.maxWidth *
                            (controller.progressPercentage.value.clamp(0.0, 1.0)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(100),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Subtle Pillar Status Row (Minimalist Balance)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildMiniPillar('mind'.tr, controller.mindProgress)),
                  Expanded(child: Center(child: _buildMiniPillar('body'.tr, controller.bodyProgress))),
                  Expanded(child: Align(alignment: Alignment.centerRight, child: _buildMiniPillar('spirit'.tr, controller.spiritProgress))),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.95, 0.95))
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildMiniPillar(String label, RxDouble progress) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white70,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Obx(
            () => Text(
              '$label: ${(progress.value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
