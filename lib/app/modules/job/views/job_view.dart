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
      appBar: AppBar(
        title: Text('my_job'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings_solid),
            onPressed: () => Get.toNamed(Routes.JOB_SETTINGS),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Salary Countdown Card
            SliverToBoxAdapter(
              child: _buildSalaryCard(context),
            ),

            // Today's Clock-in Card
            SliverToBoxAdapter(
              child: _buildAttendanceActionCard(context),
            ),

            // Statistical Summary (Horizontal)
            SliverToBoxAdapter(
              child: _buildSummarySection(context),
            ),

            // Statistics Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('attendance_analytics'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildStatBadge(
                      (controller.attendanceRate.value * 100).toInt().toString() + '%',
                      AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Weekly Chart
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _buildWeeklyChart(context),
              ),
            ),

            // Detailed History
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text('previous_days'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final log = controller.monthlyStats[index];
                  return _buildHistoryItem(context, log);
                },
                childCount: controller.monthlyStats.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      }),
    );
  }

  Widget _buildSalaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final days = controller.daysUntilSalary.value;
    
    // Accurate progress based on month length
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final progress = ((daysInMonth - days).clamp(0, daysInMonth) / daysInMonth);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withBlue(255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withAlpha(50),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
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
                  Text('salary_countdown'.tr, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    '$days ${'days_left'.tr}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.money_dollar, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(6)),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Colors.white.withAlpha(100), blurRadius: 10)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'day'.trParams({'day': controller.profile.value.salaryDay.toString()}) + ' ' + 'salary_target'.tr,
                style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildAttendanceActionCard(BuildContext context) {
    final theme = Theme.of(context);
    final today = controller.todayLog.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor.withAlpha(10)),
              ),
              child: Row(
                children: [
                  _buildStatusIcon(today?.status),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('today_status'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          today == null ? 'not_logged_yet'.tr : (today.status.name.tr + (today.checkInTime != null ? ' (${DateFormat.Hm().format(today.checkInTime!)})' : '')),
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (today == null)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () => _showQuickLogDialog(context),
                      child: Text('log'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                  else
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.dividerColor.withAlpha(10)),
            ),
            child: IconButton(
              icon: const Icon(CupertinoIcons.calendar_badge_plus, color: AppTheme.primary),
              onPressed: () => _showManualLogPicker(context),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusIcon(AttendanceStatus? status) {
    Color color = Colors.grey;
    IconData icon = CupertinoIcons.clock;

    switch (status) {
      case AttendanceStatus.present:
        color = Colors.green;
        icon = CupertinoIcons.person_crop_circle_fill_badge_checkmark;
        break;
      case AttendanceStatus.absent:
        color = Colors.red;
        icon = CupertinoIcons.person_crop_circle_fill_badge_xmark;
        break;
      case AttendanceStatus.sick:
        color = Colors.orange;
        icon = CupertinoIcons.bandage_fill;
        break;
      case AttendanceStatus.leave:
        color = Colors.blue;
        icon = CupertinoIcons.airplane;
        break;
      case AttendanceStatus.holiday:
        color = Colors.purple;
        icon = CupertinoIcons.sun_max_fill;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final theme = Theme.of(context);
    final stats = controller.weeklyStats;
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < stats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(DateFormat.E().format(stats[value.toInt()].date).substring(0, 1), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(stats.length, (index) {
            final log = stats[stats.length - 1 - index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: log.status == AttendanceStatus.present ? 1 : 0.2,
                  color: log.status == AttendanceStatus.present ? Colors.green : Colors.red,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final summary = controller.statsSummary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildSummaryItem(context, 'present_total'.trParams({'count': (summary[AttendanceStatus.present] ?? 0).toString()}), AttendanceStatus.present),
          const SizedBox(width: 12),
          _buildSummaryItem(context, 'absent_total'.trParams({'count': (summary[AttendanceStatus.absent] ?? 0).toString()}), AttendanceStatus.absent),
          const SizedBox(width: 12),
          _buildSummaryItem(context, 'sick_total'.trParams({'count': (summary[AttendanceStatus.sick] ?? 0).toString()}), AttendanceStatus.sick),
          const SizedBox(width: 12),
          _buildSummaryItem(context, 'leave_total'.trParams({'count': (summary[AttendanceStatus.leave] ?? 0).toString()}), AttendanceStatus.leave),
          const SizedBox(width: 12),
          _buildSummaryItem(context, 'holiday_total'.trParams({'count': (summary[AttendanceStatus.holiday] ?? 0).toString()}), AttendanceStatus.holiday),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, AttendanceStatus status) {
     Color color = Colors.grey;
     switch (status) {
       case AttendanceStatus.present: color = Colors.green; break;
       case AttendanceStatus.absent: color = Colors.red; break;
       case AttendanceStatus.sick: color = Colors.orange; break;
       case AttendanceStatus.leave: color = Colors.blue; break;
       case AttendanceStatus.holiday: color = Colors.purple; break;
     }

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: color.withAlpha(15),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: color.withAlpha(30)),
       ),
       child: Row(
         children: [
           Icon(Icons.circle, color: color, size: 8),
           const SizedBox(width: 8),
           Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
         ],
       ),
     );
  }

  Widget _buildHistoryItem(BuildContext context, AttendanceLog log) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatusIcon(log.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat.yMMMMd().format(log.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(log.status.name.tr, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
              ],
            ),
          ),
          if (log.checkInTime != null)
            Text(DateFormat.Hm().format(log.checkInTime!), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('log_attendance'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: AttendanceStatus.values.map((status) {
                return GestureDetector(
                  onTap: () {
                    controller.logAttendance(status);
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(10)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatusIcon(status),
                        const SizedBox(height: 8),
                        Text(status.name.tr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showManualLogPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat.yMMMMd().format(picked), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 24),
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
                      Get.snackbar('success'.tr, 'logged_for_day'.trParams({'date': DateFormat.yMd().format(picked)}));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context) {
    // Legacy - No longer used, handled by dedicated JobSettingsView
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
