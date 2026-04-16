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
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.primary, size: 22),
                  onPressed: () => Get.back(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'my_job'.tr,
                    style: TextStyle(
                      color: theme.textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.settings_solid,
                        color: AppTheme.primary, size: 22),
                    onPressed: () => Get.toNamed(Routes.JOB_SETTINGS),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Salary countdown card ──
              SliverToBoxAdapter(
                child: _buildSalaryCard(context),
              ),

              // ── Today attendance card ──
              SliverToBoxAdapter(
                child: _buildAttendanceActionCard(context),
              ),

              // ── Performance/Consistency Score ──
              SliverToBoxAdapter(
                child: _buildConsistencyScore(context),
              ),

              // ── Analytics header + chart ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
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
                      Text('attendance_analytics'.tr,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      _buildStatBadge(
                        '${(controller.attendanceRate.value * 100).toInt()}%',
                        AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

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
                  child: Text('previous_days'.tr,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // ── History list ──
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = controller.monthlyStats[index];
                    return _buildHistoryItem(context, log, index);
                  },
                  childCount: controller.monthlyStats.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
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
            (i) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.cardColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 1200.ms,
                      color: theme.dividerColor.withAlpha(40),
                    )),
      ),
    );
  }

  // ─── Salary card ─────────────────────────────────────────────
  Widget _buildSalaryCard(BuildContext context) {
    final days = controller.daysUntilSalary.value;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final progress =
        ((daysInMonth - days).clamp(0, daysInMonth) / daysInMonth);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('salary_countdown'.tr,
                      style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    '$days ${'days_left'.tr}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.money_dollar,
                    color: Colors.white, size: 26),
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
                    borderRadius: BorderRadius.circular(5)),
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
                          color: Colors.white.withAlpha(100), blurRadius: 8)
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
              Text(
                '${'day'.trParams({'day': controller.profile.value.salaryDay.toString()})} ${'salary_target'.tr}',
                style: TextStyle(
                    color: Colors.white.withAlpha(180), fontSize: 11),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
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
                    color: theme.dividerColor.withAlpha(12), width: 1),
              ),
              child: Row(
                children: [
                  _buildStatusIcon(today?.status),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('today_status'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          today == null
                              ? 'not_logged_yet'.tr
                              : (today.status.name.tr +
                                  (today.checkInTime != null
                                      ? ' (${TimeOfDay.fromDateTime(today.checkInTime!).format(context)})'
                                      : '')),
                          style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (today == null)
                    GestureDetector(
                      onTap: () => _showQuickLogDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('check_in'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  else if (today.status == AttendanceStatus.present && today.checkOutTime == null)
                    GestureDetector(
                      onTap: () {
                        controller.logAttendance(AttendanceStatus.present, isCheckOut: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500), // Orange for active shift / checking out
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('check_out'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 1))
                  else
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF34C759), size: 28),
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
                    color: theme.dividerColor.withAlpha(12), width: 1),
              ),
              child: const Icon(CupertinoIcons.calendar_badge_plus,
                  color: AppTheme.primary, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 350.ms);
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
      decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
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
                '${(score * 100).toInt()}',
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: AppTheme.primary
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('consistency_rate'.tr, 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
          const SizedBox(width: 16),
          _buildStatBadge(
            'performance_score'.tr,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  // ─── Enhanced Analytics Section ───────────────────────────────
  Widget _buildEnhancedCharts(BuildContext context) {
    return Column(
      children: [
        _buildPieDistribution(context),
        const SizedBox(height: 16),
        _buildWeeklyFrequencyChart(context),
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
          Text('attendance_distribution'.tr, 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                      sections: statusColors.entries.where((e) => summary.containsKey(e.key)).map((entry) {
                        final count = summary[entry.key] ?? 0;
                        return PieChartSectionData(
                          color: entry.value,
                          value: count.toDouble(),
                          title: count > 0 ? '$count' : '',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: statusColors.entries.where((e) => summary.containsKey(e.key)).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(entry.key.name.tr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyFrequencyChart(BuildContext context) {
    final theme = Theme.of(context);
    final stats = controller.weeklyChartData;
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < stats.length) {
                    final date = stats[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat.E(Get.locale?.languageCode).format(date),
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(stats.length, (index) {
            final log = stats[index];
            final isPresent = log.status == AttendanceStatus.present;
            final color = isPresent ? AppTheme.primary : const Color(0xFFFF3B30).withAlpha(100);
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: isPresent ? 1 : 0.4,
                  color: color,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
                  DateFormat.yMMMMd(Get.locale?.languageCode).format(log.date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(log.status.name.tr,
                    style: TextStyle(
                        color: theme.textTheme.bodySmall?.color, fontSize: 12)),
              ],
            ),
          ),
          if (log.checkInTime != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                TimeOfDay.fromDateTime(log.checkInTime!).format(context),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary),
              ),
            ),
        ],
      ),
    ).animate(delay: (50 * index).ms).fadeIn(duration: 250.ms);
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('log_attendance'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
                          color: Theme.of(context).dividerColor.withAlpha(12)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusIcon(status),
                        const SizedBox(height: 6),
                        Text(status.name.tr,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
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
            Text(DateFormat.yMMMMd(Get.locale?.languageCode).format(picked),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 16)),
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
                        'logged_for_day'.trParams(
                            {'date': DateFormat.yMd(Get.locale?.languageCode).format(picked)}));
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: color.withAlpha(18), borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
