import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/steps_controller.dart';

class StepsView extends GetView<StepsController> {
  const StepsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_steps'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.slider_horizontal_3),
            onPressed: () => _showGoalSettings(context),
            tooltip: 'set_step_goal'.tr,
          ),
          IconButton(
            icon: Icon(CupertinoIcons.refresh_circled),
            onPressed: () => controller.syncData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.stepsToday.value == 0) {
          return Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.syncData(),
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // Sensor Integration Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _buildSensorStatusCard(context),
                ),
              ),

              // Today's Giant Gauge
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: _buildMainProgressCard(context),
                ),
              ),

              // Activity Chart Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('yearly_activity'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('weekly_avg'.tr, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: _buildHistoricalChart(context),
                ),
              ),

              // Historical List
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('entries'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: Icon(CupertinoIcons.add_circled, size: 18),
                        label: Text('add_manually'.tr),
                        onPressed: () => _showManualEntryDialog(context),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: _buildHistoricalList(context),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainProgressCard(BuildContext context) {
    final theme = Theme.of(context);
    final progress = controller.progress;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(isDark ? 10 : 30),
            blurRadius: 40,
            spreadRadius: -10,
            offset: Offset(0, 15),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background circle
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 20,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.dividerColor.withAlpha(isDark ? 5 : 20)),
                ),
              ),
              // Main Progress
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 20,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeCap: StrokeCap.round,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: Duration(seconds: 3), color: Colors.white24),
              // Inner Center Info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.flame_fill, color: Colors.orange, size: 28),
                  ),
                  SizedBox(height: 12),
                  Text(
                    NumberFormat('#,###').format(controller.stepsToday.value),
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  Text(
                    '${'step_goal'.tr}: ${NumberFormat('#,###').format(controller.dailyGoal.value)}',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildDetailChip(
                  context,
                  CupertinoIcons.checkmark_seal_fill,
                  'goal_reached'.tr,
                  '${(progress * 100).toInt()}%',
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildDetailChip(
                  context,
                  CupertinoIcons.arrow_right_circle_fill,
                  'remaining'.tr,
                  controller.stepsToday.value >= controller.dailyGoal.value 
                      ? '+${controller.stepsToday.value - controller.dailyGoal.value}' 
                      : '${controller.dailyGoal.value - controller.stepsToday.value}',
                  AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  Widget _buildSensorStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isAuthorized = controller.isHealthAuthorized.value;
      
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Container(
          key: ValueKey('sensor_card_$isAuthorized'),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isAuthorized ? Colors.green : Colors.orange).withAlpha(10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: (isAuthorized ? Colors.green : Colors.orange).withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(
                isAuthorized ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill,
                color: isAuthorized ? Colors.green : Colors.orange,
              ).animate(target: isAuthorized ? 1 : 0).shimmer(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuthorized 
                        ? 'sensors_connected'.tr 
                        : (controller.isLoading.value ? 'syncing'.tr : 'sensors_disconnected'.tr),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      isAuthorized 
                        ? 'syncing_with_device'.tr 
                        : (controller.isLoading.value ? 'please_wait'.tr : 'connect_to_sync'.tr),
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.value)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: isAuthorized ? Colors.green : Colors.orange),
                ).animate().rotate(),
              if (!isAuthorized && !controller.isLoading.value)
                TextButton(
                  onPressed: () => controller.requestHealthPermission(),
                  child: Text('connect'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                ).animate().fadeIn().scale(),
            ],
          ),
        ).animate().slideX(begin: isAuthorized ? 0 : 0.05, duration: Duration(milliseconds: 400)),
      );
    });
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.dividerColor.withAlpha(5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Widget _buildHistoricalChart(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ Phase 3: Display chronologically left-to-right
    final logs = controller.weeklyLogs.reversed.toList();
    if (logs.isEmpty) return SizedBox.shrink();

    return Container(
      height: 240,
      padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withAlpha(10)),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < logs.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        DateFormat.E(Get.locale?.languageCode).format(logs[value.toInt()].date),
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(logs.length, (index) {
            final log = logs[index];
            final isAchieved = log.steps >= log.goal;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: log.steps.toDouble(),
                  color: isAchieved ? Colors.green.withAlpha(200) : AppTheme.primary.withAlpha(180),
                  width: 14,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: log.goal.toDouble(),
                    color: theme.dividerColor.withAlpha(10),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400));
  }

  Widget _buildHistoricalList(BuildContext context) {
    final theme = Theme.of(context);
    final logs = controller.monthlyLogs;

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('no_sync_data'.tr, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isAchieved = log.steps >= log.goal;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withAlpha(10)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isAchieved ? Colors.green : Colors.orange).withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isAchieved ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.flame,
                  color: isAchieved ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMd(Get.locale?.languageCode).format(log.date),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(log.steps)} ${'steps_today'.tr}',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(log.progress.clamp(0.0, 1.0) * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isAchieved ? Colors.green : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  if (isAchieved)
                    Icon(CupertinoIcons.capslock_fill, color: Colors.green, size: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalSettings(BuildContext context) {
    final theme = Theme.of(context);
    final popularGoals = [5000, 8000, 10000, 12000, 15000, 20000];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('set_step_goal'.tr, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: Icon(CupertinoIcons.xmark_circle_fill), onPressed: () => Get.back()),
              ],
            ),
            SizedBox(height: 8),
            Text('step_goal_desc'.tr, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            SizedBox(height: 32),
            Text('or_enter_custom'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.dailyGoalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '10000',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                  child: IconButton(
                    icon: Icon(CupertinoIcons.checkmark, color: Colors.white),
                    onPressed: () {
                      final val = int.tryParse(controller.dailyGoalController.text);
                      if (val != null && val > 0) {
                        controller.updateGoal(val);
                        Get.back();
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final theme = Theme.of(context);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('add_manual_steps'.tr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('add_manual_steps_desc'.tr, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              SizedBox(height: 24),
              TextField(
                controller: controller.manualStepsController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '500',
                  prefixIcon: Icon(Icons.directions_walk),
                  filled: true,
                  fillColor: theme.dividerColor.withAlpha(5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
                   SizedBox(width: 8),
                   ElevatedButton(
                     onPressed: () => controller.addManualSteps(),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primary,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: Text('save'.tr),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
