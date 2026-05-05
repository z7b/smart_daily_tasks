import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/job_controller.dart';
import '../../../data/models/attendance_log_model.dart';
import '../../../routes/app_routes.dart';
import '../../../core/helpers/number_extension.dart';

class JobView extends GetView<JobController> {
  const JobView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildSkeleton(theme);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── iOS Large Title AppBar ──
              SliverAppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                  onPressed: () => Get.back(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'my_job'.tr,
                          style: TextStyle(
                            color: theme.textTheme.titleLarge?.color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.isEmployed) ...[
                        const SizedBox(width: 8),
                        // ✅ Glassy Job Title Badge Restored
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(40),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              (controller.profile.value.jobTitle ??
                                      'unnamed_job'.tr)
                                  .tr,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 20), // Padding from right edge
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.settings_solid,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    onPressed: () => Get.toNamed(Routes.JOB_SETTINGS),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              if (controller.isNotConfigured)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNotConfiguredState(context),
                )
              else if (controller.isUnemployed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildUnemployedState(context),
                )
              else ...[
                // ── Salary countdown card ──
              SliverToBoxAdapter(child: _buildSalaryCard(context)),

              // ── Today attendance card ──
              SliverToBoxAdapter(child: _buildAttendanceActionCard(context)),

              // ── Performance/Consistency Score ──
              SliverToBoxAdapter(child: _buildConsistencyScore(context)),

              // ── Period Selection ──
              SliverToBoxAdapter(child: _buildPeriodSelector(context)),

              // ── Analytics header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'attendance_analytics'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      _buildStatBadge(
                        '${NumberFormat.decimalPattern(Get.locale?.languageCode).format((controller.attendanceRate.value * 100).toInt()).f}%',
                        AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Metric Overview Grid ──
              SliverToBoxAdapter(child: _buildMetricOverview(context)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildEnhancedCharts(context),
                ),
              ),

              // ── History header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                  child: Text(
                    'previous_days'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ── History list ──
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final log = controller.monthlyStats[index];
                  return _buildHistoryItem(context, log, index);
                }, childCount: controller.monthlyStats.length),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ], // End of employed state slivers
            ],
          );
        }),
      ),
    );
  }

  // ─── Setup / Unemployed States ────────────────────────────────
  Widget _buildNotConfiguredState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.briefcase_fill, size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text('setup_job_title'.tr, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'setup_job_desc'.tr, 
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.toNamed(Routes.JOB_SETTINGS),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('i_have_job'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => controller.setUnemployed(),
            child: Text('i_am_unemployed'.tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnemployedState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.bed_double_fill, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text('unemployed'.tr, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'unemployed_desc'.tr, 
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => Get.toNamed(Routes.JOB_SETTINGS),
            icon: const Icon(CupertinoIcons.add_circled, color: AppTheme.primary),
            label: Text('switch_to_employed'.tr, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Skeleton loader ─────────────────────────────────────────
  Widget _buildSkeleton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          4,
          (i) =>
              Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.cardColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: const Duration(milliseconds: 1200),
                    color: theme.dividerColor.withAlpha(40),
                  ),
        ),
      ),
    );
  }

  // ─── Salary card ─────────────────────────────────────────────
  Widget _buildSalaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final days = controller.daysUntilSalary.value;
    final progress = controller
        .salaryProgress
        .value; // ✅ Phase 3: Accurate cross-month calculation

    return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 10),
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
                          'salary_countdown'.tr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withAlpha(200),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${NumberFormat.decimalPattern(Get.locale?.languageCode).format(days).f} ${'days_left'.tr}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha(100),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'day'.trParams({'day': controller.profile.value.salaryDay.toString().f})} ${'salary_target'.tr}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern(Get.locale?.languageCode).format((progress * 100).toInt()).f}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  // ─── Attendance action card ───────────────────────────────────
  Widget _buildAttendanceActionCard(BuildContext context) {
    final theme = Theme.of(context);
    final today = controller.todayLog.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerColor.withAlpha(12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusIcon(today?.status),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'today_status'.tr,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              today == null
                                  ? 'not_logged_yet'.tr
                                  : (today.status.name.tr +
                                        (today.checkInTime != null
                                            ? ' (${TimeOfDay.fromDateTime(today.checkInTime!).format(context)})'
                                            : '')),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (today != null &&
                          !(today.status == AttendanceStatus.present &&
                              today.checkOutTime == null))
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Color(0xFF34C759),
                          size: 28,
                        ),
                    ],
                  ),
                  if (today == null ||
                      (today.status == AttendanceStatus.present &&
                          today.checkOutTime == null)) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          if (today == null) {
                            _showQuickLogDialog(context);
                          } else {
                            controller.logAttendance(
                              AttendanceStatus.present,
                              isCheckOut: true,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: today == null
                                ? AppTheme.primary
                                : const Color(0xFFFF9500),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            today == null ? 'check_in'.tr : 'check_out'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(),
                  ],
                  if (today?.status == AttendanceStatus.present &&
                      today?.checkOutTime == null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Obx(
                        () => Text(
                          '${'expected_check_out'.tr}: ${controller.expectedCheckOut.value.f}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showManualLogPicker(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerColor.withAlpha(12),
                  width: 1,
                ),
              ),
              child: const Icon(
                CupertinoIcons.calendar_badge_plus,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 350),
    );
  }

  // ─── Status icon ─────────────────────────────────────────────
  Widget _buildStatusIcon(AttendanceStatus? status) {
    Color color = Colors.grey;
    IconData icon = CupertinoIcons.clock;
    switch (status) {
      case AttendanceStatus.present:
        color = const Color(0xFF34C759);
        icon = CupertinoIcons.person_crop_circle_fill_badge_checkmark;
        break;
      case AttendanceStatus.absent:
        color = const Color(0xFFFF3B30);
        icon = CupertinoIcons.person_crop_circle_fill_badge_xmark;
        break;
      case AttendanceStatus.sick:
        color = const Color(0xFFFF9500);
        icon = CupertinoIcons.bandage_fill;
        break;
      case AttendanceStatus.leave:
        color = const Color(0xFF007AFF);
        icon = CupertinoIcons.airplane;
        break;
      case AttendanceStatus.holiday:
        color = const Color(0xFFAF52DE);
        icon = CupertinoIcons.sun_max_fill;
        break;
      default:
        break;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // ─── Consistency Score Card ──────────────────────────────────
  Widget _buildConsistencyScore(BuildContext context) {
    final theme = Theme.of(context);
    final score = controller.consistencyRate.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withAlpha(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withAlpha(40),
                  AppTheme.primary.withAlpha(10),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                NumberFormat.decimalPattern(
                  Get.locale?.languageCode,
                ).format((score * 100).toInt()).f,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'consistency_rate'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: theme.dividerColor.withAlpha(10),
                    color: AppTheme.primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: _buildStatBadge('performance_score'.tr, Colors.grey)),
        ],
      ),
    );
  }

  // ─── Period Selector ──────────────────────────────────────────
  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withAlpha(12)),
        ),
        child: Row(
          children: JobAnalyticsPeriod.values.map((period) {
            final isSelected = controller.selectedPeriod.value == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setPeriod(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    period.name.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Metric Overview ──────────────────────────────────────────
  Widget _buildMetricOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ), // Slightly reduced padding for safety
      child: Column(
        children: [
          Row(
            children: [
              _buildMetricCard(
                context,
                'total_duty_days'.tr,
                NumberFormat.decimalPattern(
                  Get.locale?.languageCode,
                ).format(controller.totalMandatedDays.value).f,
                CupertinoIcons.calendar,
                AppTheme.primary,
              ),
              const SizedBox(width: 10), // Reduced from 12
              _buildMetricCard(
                context,
                'avg_check_in'.tr,
                controller.avgCheckInTime.value.f,
                CupertinoIcons.clock,
                const Color(0xFF5AC8FA),
                subtitle: _buildVarianceBadge(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricCard(
                context,
                'total_work_hours'.tr,
                _formatDuration(controller.totalWorkMinutes.value),
                CupertinoIcons.timer,
                const Color(0xFFAF52DE),
              ),
              const SizedBox(width: 10), // Reduced from 12
              _buildMetricCard(
                context,
                'work_balance'.tr,
                '${controller.workBalanceMinutes.value >= 0 ? '+' : ''}${NumberFormat.decimalPattern(Get.locale?.languageCode).format(controller.workBalanceMinutes.value.abs() ~/ 60).f}${'hours_abbr'.tr} ${NumberFormat.decimalPattern(Get.locale?.languageCode).format(controller.workBalanceMinutes.value.abs() % 60).f}${'minutes_abbr'.tr}',
                CupertinoIcons.graph_square_fill,
                controller.workBalanceMinutes.value >= 0
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
                subtitle: Text(
                  '${'target_hours'.tr}: ${NumberFormat.decimalPattern(Get.locale?.languageCode).format(controller.profile.value.officialWorkHours).f}${'hours_abbr'.tr}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    Widget? subtitle,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minHeight: 85,
        ), // Ensure enough height for 2 lines
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withAlpha(12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 9.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  // ignore: use_null_aware_elements
                  if (subtitle != null) subtitle,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceBadge(BuildContext context) {
    final variance = controller.avgVarianceMinutes.value;
    if (variance == 0) return const SizedBox.shrink();

    final isLate = variance > 0;
    final color = isLate ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final label = isLate ? 'late'.tr : 'early'.tr;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isLate
                ? CupertinoIcons.arrow_up_right
                : CupertinoIcons.arrow_down_left,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${NumberFormat.decimalPattern(Get.locale?.languageCode).format(variance.abs()).f}${'minutes_abbr'.tr} $label',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final locale = Get.locale?.languageCode;
    final hStr = NumberFormat.decimalPattern(locale).format(hours).f;
    final mStr = NumberFormat.decimalPattern(locale).format(minutes).f;

    if (hours > 0) {
      return '$hStr${'hours_abbr'.tr} $mStr${'minutes_abbr'.tr}';
    }
    return '$mStr${'minutes_abbr'.tr}';
  }

  // ─── Enhanced Analytics Section ───────────────────────────────
  Widget _buildEnhancedCharts(BuildContext context) {
    return Column(
      children: [
        _buildTrendChart(
          context,
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        _buildPieDistribution(
          context,
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
      ],
    );
  }

  Widget _buildPieDistribution(BuildContext context) {
    final theme = Theme.of(context);
    final summary = controller.statsSummary;
    if (summary.isEmpty) return const SizedBox.shrink();

    final statusColors = {
      AttendanceStatus.present: const Color(0xFF34C759),
      AttendanceStatus.absent: const Color(0xFFFF3B30),
      AttendanceStatus.sick: const Color(0xFFFF9500),
      AttendanceStatus.leave: const Color(0xFF007AFF),
      AttendanceStatus.holiday: const Color(0xFFAF52DE),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'attendance_distribution'.tr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: statusColors.entries
                          .where((e) => summary.containsKey(e.key))
                          .map((entry) {
                            final count = summary[entry.key] ?? 0;
                            return PieChartSectionData(
                              color: entry.value,
                              value: count.toDouble(),
                              title: count > 0 ? count.f : '',
                              radius: 50,
                              titleStyle: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: statusColors.entries
                        .where((e) => summary.containsKey(e.key))
                        .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key.name.tr,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final theme = Theme.of(context);
    final period = controller.selectedPeriod.value;
    final data = controller.aggregatedChartData;

    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 290, // ✅ Increased for better clearance
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ), // ✅ Optimized padding
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'period_insights'.tr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              if (period == JobAnalyticsPeriod.yearly) ...[
                _buildYearPicker(context),
                const SizedBox(width: 4),
              ],
              _buildStatBadge(period.name.tr, AppTheme.primary),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildAggregatedBarChart(context, data, period)),
          const SizedBox(height: 12),
          // ── Smart Insight Panel ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.dividerColor.withAlpha(5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.lightbulb_fill,
                  color: Color(0xFFFFCC00),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.performanceInsight.value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      onSelected: (year) => controller.setYear(year),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        final years = controller.availableYears.isNotEmpty
            ? controller.availableYears
            : [DateTime.now().year];
        return years.map((year) {
          final isSelected = year == controller.selectedYear.value;
          return PopupMenuItem<int>(
            value: year,
            child: Row(
              children: [
                Text(
                  '$year',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : null,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 26, // ✅ Fixed Height
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withAlpha(40), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${controller.selectedYear.value}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              CupertinoIcons.chevron_down,
              size: 8,
              color: AppTheme.primary.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAggregatedBarChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
    JobAnalyticsPeriod period,
  ) {
    final theme = Theme.of(context);

    // Adjust bar width based on density
    double barWidth = 14;
    if (period == JobAnalyticsPeriod.monthly) barWidth = 32;
    if (period == JobAnalyticsPeriod.yearly) barWidth = 12;

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42, // ✅ Increased for tilt clearance
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }

                final isYearly = period == JobAnalyticsPeriod.yearly;
                return SideTitleWidget(
                  space: 4,
                  meta: meta,
                  child: Transform.rotate(
                    angle: isYearly ? -0.7 : 0, // ✅ Tilt for 12-month density
                    child: Text(
                      data[index]['label'],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: isYearly ? 8 : 9,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (index) {
          final val = data[index]['value'] as double;
          final color = val > 0.7
              ? AppTheme.primary
              : (val > 0.4 ? const Color(0xFFFF9500) : const Color(0xFFFF3B30));

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val.clamp(0.05, 1.0), // Min visible height
                color: color,
                width: barWidth,
                borderRadius: BorderRadius.circular(
                  period == JobAnalyticsPeriod.monthly ? 8 : 4,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 1,
                  color: theme.dividerColor.withAlpha(5),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── History item ─────────────────────────────────────────────
  Widget _buildHistoryItem(BuildContext context, AttendanceLog log, int index) {
    final theme = Theme.of(context);
    return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _buildStatusIcon(log.status),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMd(
                        Get.locale?.languageCode,
                      ).format(log.date).f,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      log.status.name.tr,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (log.checkInTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    TimeOfDay.fromDateTime(log.checkInTime!).format(context).f,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: const Duration(milliseconds: 250));
  }

  // ─── Quick log dialog ────────────────────────────────────────
  void _showQuickLogDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'log_attendance'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: AttendanceStatus.values.map((status) {
                return GestureDetector(
                  onTap: () {
                    controller.logAttendance(status);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusIcon(status),
                        const SizedBox(height: 6),
                        Text(
                          status.name.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Manual log picker ────────────────────────────────────────
  void _showManualLogPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.yMMMMd(Get.locale?.languageCode).format(picked).f,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AttendanceStatus.values.map((status) {
                return ChoiceChip(
                  label: Text(status.name.tr),
                  selected: false,
                  onSelected: (val) {
                    controller.logAttendance(status, date: picked);
                    Get.back();
                    Get.snackbar(
                      'success'.tr,
                      'logged_for_day'.trParams({
                        'date': DateFormat.yMd(
                          Get.locale?.languageCode,
                        ).format(picked).f,
                      }),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Stat badge ───────────────────────────────────────────────
  Widget _buildStatBadge(String label, Color color) {
    return Container(
      height: 26, // ✅ Identical Fixed Height
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
