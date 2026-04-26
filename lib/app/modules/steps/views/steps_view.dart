import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/steps_controller.dart';
import '../../../core/helpers/number_extension.dart';
import '../../../data/models/achievement_model.dart';

// --- Dynamic Colors for Light/Dark Mode ---
Color get _bg =>
    Get.isDarkMode ? Color(0xFF000000) : Color(0xFFF2F4F7);
Color get _cardBg => Get.isDarkMode ? Color(0xFF1C1C1E) : Colors.white;
Color get _text => Get.isDarkMode ? Colors.white : Color(0xFF111827);
Color get _muted =>
    Get.isDarkMode ? Color(0xFFA1A1AA) : Color(0xFF6B7280);
Color get _faint =>
    Get.isDarkMode ? Color(0xFF52525B) : Color(0xFF9CA3AF);
const _purple = Color(0xFF7C3AED);
const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF22C55E);
const _greenDeep = Color(0xFF16A34A);
const _orange = Color(0xFFF97316);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

class StepsView extends GetView<StepsController> {
  const StepsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.stepsToday.value == 0) {
              return Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => controller.syncData(),
              color: _purple,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    SizedBox(height: 12),
                    _missingBiometricsBanner(context),
                    _mainCard(context),
                    SizedBox(height: 12),
                    _buildTimeFilter(context),
                    SizedBox(height: 12),
                    _buildNewWeeklyChart(context),
                    SizedBox(height: 12),
                    _buildWeeklySummary(context),
                    SizedBox(height: 12),
                    _buildStatsGrid(context),
                    SizedBox(height: 12),
                    _buildMotivationCard(context),
                    SizedBox(height: 12),
                    _challenges(),
                    SizedBox(height: 12),
                    _badges(context),
                    SizedBox(height: 12),
                    _todayActivity(),
                    SizedBox(height: 12),
                    _tipCard(),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _card(Widget child, {EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Get.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }



  // --- UI Components ---

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back_ios_new, size: 24, color: _text),
          ),
          Spacer(),
          Text(
            'my_steps'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  controller.calculateSmartGoal(30, 70, 'active');
                  Get.snackbar(
                    'smart_suggestion'.tr,
                    'goal_updated_smartly'.tr,
                    backgroundColor: _cardBg,
                    colorText: _text,
                  );
                },
                child: Icon(
                  CupertinoIcons.lightbulb_fill,
                  size: 26,
                  color: _amber,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16),
          InkWell(
            onTap: () => _showBiometricsDialog(context),
            child: Icon(Icons.settings, size: 26, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _missingBiometricsBanner(BuildContext context) {
    if (controller.userHeight.value != null &&
        controller.userWeight.value != null) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.1),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'enter_biometrics_desc'.tr,
              style: TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showBiometricsDialog(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'enter'.tr,
              style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBiometricsDialog(BuildContext context) {
    String selectedGender = controller.userGender.value ?? 'male';

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 
                  MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'update_biometrics'.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'biometrics_help_desc'.tr,
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  SizedBox(height: 24),

                  // Gender Selection
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => selectedGender = 'male'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedGender == 'male'
                                  ? _blue.withValues(alpha: 0.1)
                                  : _bg,
                              border: Border.all(
                                color: selectedGender == 'male'
                                    ? _blue
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'male'.tr,
                              style: TextStyle(
                                color: selectedGender == 'male' ? _blue : _text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedGender = 'female'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedGender == 'female'
                                  ? _purple.withValues(alpha: 0.1)
                                  : _bg,
                              border: Border.all(
                                color: selectedGender == 'female'
                                    ? _purple
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'female'.tr,
                              style: TextStyle(
                                color: selectedGender == 'female'
                                    ? _purple
                                    : _text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: controller.heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'height_cm'.tr,
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  TextField(
                    controller: controller.weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'weight_kg'.tr,
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () {
                      final h = double.tryParse(controller.heightCtrl.text);
                      final w = double.tryParse(controller.weightCtrl.text);
                      if (h != null && w != null) {
                        controller.saveBiometrics(
                          height: h,
                          weight: w,
                          gender: selectedGender,
                        );
                        Get.back();
                         Get.snackbar(
                           'saved'.tr,
                           'biometrics_saved_success'.tr,
                           backgroundColor: _cardBg,
                           colorText: _text,
                         );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'save_data'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showEditGoalDialog(BuildContext context) {
    controller.dailyGoalController.text = controller.dailyGoal.value.toString();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'edit_daily_step_goal'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextField(
              controller: controller.dailyGoalController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'daily_goal_steps'.tr,
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final newGoal =
                    int.tryParse(controller.dailyGoalController.text);
                if (newGoal != null && newGoal > 0) {
                  controller.updateDailyGoal(newGoal);
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'save_new_goal'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _mainCard(BuildContext context) {
    final progress = controller.progress;
    final steps = controller.stepsToday.value;
    final goal = controller.dailyGoal.value;
    final stepsLeft = (goal - steps).clamp(0, 999999);
    final progressPct = (progress * 100).toInt();

    // Motivation Logic
    String messageText = 'steps_left_msg'.trParams({'count': stepsLeft.toString()});
    Color progressColor = _green;
    if (progress >= 1.0) {
      messageText = 'goal_achieved_msg'.tr;
    } else if (progress >= 0.8) {
      messageText = 'almost_there_msg'.tr;
      progressColor = _orange;
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'consecutive_days'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          controller.currentStreak.value.f,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🔥', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final letters = ['S', 'F', 'T', 'W', 'T', 'M', 'S'];
                        // ✅ Fix: Show actual streak, no misleading placeholder
                        final filled =
                            i < controller.currentStreak.value.clamp(0, 7);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: filled
                                    ? Color(0xFFFFEDD5)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: filled
                                      ? _orange
                                      : Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: filled
                                  ? Icon(
                                      Icons.check,
                                      size: 12,
                                      color: _orange,
                                    )
                                  : null,
                            ),
                            SizedBox(height: 2),
                            Text(
                              letters[i],
                              style: TextStyle(
                                fontSize: 9,
                                color: _muted,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'of_goal'.trParams({'percent': progressPct.toString()}),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: progressColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: Color(0xFFE6E8EC),
                              valueColor: AlwaysStoppedAnimation(progressColor),
                            ),
                          ),
                          SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              messageText,
                              style: TextStyle(
                                fontSize: 10,
                                color: _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            'completion_percentage'.trParams({'percent': progressPct.toString()}),
                            style: TextStyle(fontSize: 10, color: _muted),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🎖️', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _RingPainter(progress: progress.clamp(0.0, 1.0)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 28,
                          color: _purple,
                        ),
                        SizedBox(height: 2),
                        Text(
                          steps.f,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _text,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'steps_of'.trParams({'goal': goal.f}),
                              style: TextStyle(fontSize: 10, color: _muted),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showEditGoalDialog(context),
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.edit, size: 10, color: _purple),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'of_goal'.trParams({'percent': progressPct.toString()}),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (controller.isHealthAuthorized.value == false && !controller.healthPromptDismissed.value)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => controller.requestHealthPermission(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amber.withValues(alpha: 0.1),
                        foregroundColor: _amber,
                        elevation: 0,
                        side: BorderSide(color: _amber.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.health_and_safety_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'connect_health_data'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 16, color: _amber.withValues(alpha: 0.6)),
                      onPressed: () => controller.dismissHealthPrompt(),
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(4),
      child: CupertinoSlidingSegmentedControl<String>(
        backgroundColor: Colors.transparent,
        thumbColor: _blue,
        groupValue: controller.selectedTimeFilter.value,
        onValueChanged: (val) {
          if (val != null) controller.setTimeFilter(val);
        },
        children: {
          'weekly': _buildTabSegment('weekly'.tr, 'weekly'),
          'monthly': _buildTabSegment('monthly'.tr, 'monthly'),
          'yearly': _buildTabSegment('yearly'.tr, 'yearly'),
        },
      ),
    );
  }

  Widget _buildTabSegment(String title, String key) {
    final isSelected = controller.selectedTimeFilter.value == key;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : _muted,
        ),
      ),
    );
  }

  Widget _buildNewWeeklyChart(BuildContext context) {
    final data = controller.getAggregatedChartData().reversed.toList();
    if (data.isEmpty) return SizedBox.shrink();

    final goalY = controller.dailyGoal.value.toDouble();
    double maxY = goalY * 1.5;
    double maxVal = 0;
    for (var d in data) {
      if (d['value'] > maxY) maxY = (d['value'] as int).toDouble() * 1.2;
      if (d['value'] > maxVal) maxVal = (d['value'] as int).toDouble();
    }

    return _card(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 22, color: _blue),
              SizedBox(width: 8),
              Text(
                controller.selectedTimeFilter.value == 'weekly' ? 'activity_week'.tr : 
                (controller.selectedTimeFilter.value == 'monthly' ? 'activity_month'.tr : 'activity_year'.tr),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              Spacer(),
              if (controller.selectedTimeFilter.value == 'yearly') ...[
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      Container(
                        color: _cardBg,
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('select_year'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text)),
                              ),
                              ...controller.availableYears.map((year) => ListTile(
                                title: Text('$year', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: _text)),
                                onTap: () {
                                  controller.setYear(year);
                                  Get.back();
                                },
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _purple.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text('${controller.selectedYear.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _purple)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: _purple),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY.clamp(10000, 200000),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY.toInt();
                      final avg = controller.getDailyAverage;
                      final percent = avg > 0 ? ((val - avg) / avg * 100).round() : 0;
                      final sign = percent >= 0 ? '+' : '';
                      return BarTooltipItem(
                        'steps_count_nl'.trParams({'count': val.f}),
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'percent_from_avg'.trParams({'sign': sign, 'percent': percent.toString()}),
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Color(0xFFEEF0F3), 
                    strokeWidth: 1, 
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goalY,
                      color: _orange.withValues(alpha: 0.8),
                      strokeWidth: 2,
                      dashArray: [8, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 4, bottom: 4),
                        style: TextStyle(fontSize: 10, color: _orange, fontWeight: FontWeight.bold),
                        labelResolver: (line) => 'your_goal'.trParams({'goal': goalY.toInt().f}),
                      ),
                    ),
                  ],
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) {
                        if (v == goalY) {
                          return Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text('your_goal'.trParams({'goal': goalY.toInt().f}), style: TextStyle(fontSize: 9, color: _faint, height: 1.2), textAlign: TextAlign.center),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 5000,
                      getTitlesWidget: (v, meta) {
                        if (v == 0) return Padding(padding: EdgeInsets.only(left: 4), child: Text('0', style: TextStyle(fontSize: 10, color: _muted)));
                        return Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('${(v / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 10, color: _muted)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: controller.selectedTimeFilter.value == 'yearly' ? 36 : 28,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) return SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          angle: controller.selectedTimeFilter.value == 'yearly' ? -0.5 : 0,
                          space: 8,
                          child: Text(
                            data[i]['label'], 
                            style: TextStyle(
                              fontSize: controller.selectedTimeFilter.value == 'yearly' ? 9 : 11, 
                              color: _muted, 
                              fontWeight: FontWeight.w600
                            )
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (i) {
                  final val = (data[i]['value'] as int).toDouble();
                  final isMax = val == maxVal && val > 0;
                  
                  return BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: isMax ? [0] : [],
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        gradient: isMax ? null : LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFFCA5A5)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        color: isMax ? _blue : null,
                        width: 14,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context) {
    final avg = controller.getDailyAverage;
    final best = controller.getBestPeriod;
    final worst = controller.getWorstPeriod;

    Widget summaryColumn(Map<String, dynamic> data, Color valueColor) {
      return Expanded(
        child: Column(
          children: [
            Text(data['label'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text)),
            SizedBox(height: 2),
            if (data['sublabel'].toString().isNotEmpty)
              Text(
                data['sublabel'], 
                style: TextStyle(
                  fontSize: 10, 
                  color: _faint.withAlpha(150),
                  fontWeight: FontWeight.w500
                )
              ),
            SizedBox(height: 4),
            Text(data['title'], style: TextStyle(fontSize: 11, color: _muted)),
            SizedBox(height: 6),
            Text((data['value'] as int).f, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      );
    }

    return _card(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.selectedTimeFilter.value == 'weekly' ? 'summary_week'.tr : 
            (controller.selectedTimeFilter.value == 'monthly' ? 'summary_month'.tr : 'summary_year'.tr),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryColumn(worst, _red),
              Container(width: 1, height: 60, color: _bg),
              summaryColumn(best, _blue),
              Container(width: 1, height: 60, color: _bg),
              Expanded(
                child: Column(
                  children: [
                    Text('daily_avg'.tr, style: TextStyle(fontSize: 11, color: _muted)),
                    SizedBox(height: 8),
                    Text(avg.f, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text)),
                    Text('step_unit'.tr, style: TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final activeTime = controller.activeTimeToday.value;
    final calories = controller.caloriesToday.value;
    final distance = controller.distanceToday.value;
    final steps = controller.stepsToday.value;

    final Color glowColor = const Color(0xFF22D3EE);

    Widget premiumStatCard(IconData icon, Color color, String value, String unit, String insight, Color insightColor) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _bg, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              insight,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: insightColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: premiumStatCard(
                CupertinoIcons.flame_fill,
                const Color(0xFFF87171),
                calories.toInt().f,
                'calorie_unit'.tr,
                calories > 500 ? 'burn_excellent'.tr : 'keep_burning'.tr,
                calories > 500 ? Colors.orange : _muted,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: premiumStatCard(
                CupertinoIcons.location_solid,
                const Color(0xFF60A5FA),
                distance.fd(2),
                'km'.tr,
                distance > 5 ? 'great_distance'.tr : 'move_more'.tr,
                distance > 5 ? _blue : _muted,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: premiumStatCard(
                CupertinoIcons.bolt_fill,
                glowColor,
                steps.f,
                'step_unit'.tr,
                steps >= controller.dailyGoal.value ? 'goal_reached_check'.tr : 'close_to_goal'.tr,
                steps >= controller.dailyGoal.value ? _greenDeep : _muted,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: premiumStatCard(
                CupertinoIcons.timer_fill,
                const Color(0xFF34D399),
                activeTime.f,
                'minute_unit'.tr,
                activeTime > 30 ? 'very_healthy_activity'.tr : 'little_left'.tr,
                activeTime > 30 ? _greenDeep : _muted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    final remaining = (controller.dailyGoal.value - controller.stepsToday.value).clamp(0, 999999);
    final progress = controller.progress;
    
    String title = '';
    String subtitle = '';
    String emoji = '';
    
    if (progress >= 1.0) {
      title = 'real_champion'.tr;
      subtitle = 'goal_crushed'.tr;
      emoji = '🎉';
    } else if (progress >= 0.8) {
      title = 'almost_there_fire'.tr;
      subtitle = 'steps_to_top'.trParams({'remaining': remaining.f});
      emoji = '🏃‍♂️';
    } else if (progress >= 0.5) {
      title = 'halfway_there_flash'.tr;
      subtitle = 'باقي ${remaining.f} خطوة، لا تستسلم الآن.';
      emoji = '🚶‍♂️';
    } else if (progress > 0.0) {
      title = 'بداية موفقة! 🌟';
      subtitle = 'باقي ${remaining.f} خطوة للوصول للهدف.';
      emoji = '👟';
    } else {
      title = 'يوم جديد، طاقة جديدة! 🌅';
      subtitle = 'حان الوقت للخطوة الأولى نحو هدفك.';
      emoji = '🛌';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          Text(emoji, style: TextStyle(fontSize: 40)),
        ],
      ),
    );
  }

  Widget _challenges() {
    Widget tile(
      String title,
      String subtitle,
      double progress,
      String label,
      Color badgeColor, {
      String? percent,
    }) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Color(0xFFE6E8EC),
                  valueColor: AlwaysStoppedAnimation(_greenDeep),
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  if (percent != null)
                    Text(
                      percent,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _greenDeep,
                      ),
                    ),
                  Spacer(),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _card(
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.flag, size: 12, color: Colors.white),
              ),
              SizedBox(width: 6),
              Text(
                'التحديات الجارية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              Spacer(),
              Text(
                '3 أيام متبقية',
                style: TextStyle(
                  fontSize: 11,
                  color: _greenDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              tile(
                'تحدي 70K',
                'أكمل 70 ألف خطوة',
                4600 / 70000,
                '4,600 / 70,000',
                _purple,
              ),
              SizedBox(width: 8),
              tile(
                'تحدي يومي',
                'أكمل ${controller.dailyGoal.value.f} خطوة',
                controller.progress,
                '${controller.stepsToday.value.f} / ${controller.dailyGoal.value.f}',
                _amber,
                percent: '${(controller.progress * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badges(BuildContext context) {
    Widget tile(
      String badge,
      Color color,
      IconData icon,
      String title,
      double progress,
      String label, {
      bool isExpanded = true,
      String? subtitle,
    }) {
      final content = Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.85), color],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: _faint),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Color(0xFFE6E8EC),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: _faint)),
        ],
      );

      return isExpanded ? Expanded(child: content) : content;
    }

    // Smart selection logic for dashboard badges (interactive & dynamic)
    final inProgress = controller.achievements
        .where((a) => !a.isUnlocked && a.progress > 0)
        .toList();
    inProgress.sort(
      (a, b) => b.progress.compareTo(a.progress),
    ); // Highest progress first

    final locked = controller.achievements
        .where((a) => !a.isUnlocked && a.progress == 0)
        .toList();
    final unlocked = controller.achievements
        .where((a) => a.isUnlocked)
        .toList();

    final top3 = <StepAchievement>[];
    top3.addAll(inProgress);
    if (top3.length < 3) top3.addAll(locked.take(3 - top3.length));
    if (top3.length < 3) top3.addAll(unlocked.take(3 - top3.length));

    return _card(
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _amber,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.workspace_premium,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'الشارات المتاحة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  Get.bottomSheet(
                    Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'جميع الشارات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.53,
                                  ),
                              itemCount: controller.achievements.length,
                              itemBuilder: (context, i) {
                                final a = controller.achievements[i];
                                return tile(
                                  a.isUnlocked ? 'مفتوح' : 'مغلق',
                                  a.isUnlocked ? a.color : _faint,
                                  a.icon,
                                  a.titleKey.tr,
                                  a.progress,
                                  '${(a.progress * 100).toInt()}%',
                                  isExpanded: false,
                                  subtitle: a.descKey.tr,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    isScrollControlled: true,
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                    Icon(Icons.chevron_left, size: 16, color: _blue),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: top3.take(3).map((a) {
              return tile(
                a.isUnlocked ? 'مفتوح' : 'مغلق',
                a.isUnlocked ? a.color : _faint,
                a.icon,
                a.titleKey.tr,
                a.progress,
                '${(a.progress * 100).toInt()}%',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _todayActivity() {
    final int total = controller.stepsToday.value;
    final int currentHour = DateTime.now().hour;

    // Expert Logic: Prefer real sensor data, fallback to estimation
    final List<double> values;
    final hasRealData = controller.hourlySteps.any((s) => s > 0);
    
    if (hasRealData) {
      values = controller.hourlySteps.map((s) => s.toDouble()).toList();
    } else {
      // Realistic walking curve estimation - heavier morning commute & evening activity
      final weights = [
        0.0, 0.0, 0.0, 0.0, 0.0, 0.05, // 0-5 AM
        0.2, 0.5, 0.7, 0.4, 0.35, 0.3, // 6-11 AM
        0.45, 0.6, 0.4, 0.35, 0.5, 0.85, // 12-17 PM
        0.75, 0.6, 0.4, 0.25, 0.1, 0.0, // 18-23 PM
      ];

      // Only sum weights up to the current hour for accurate distribution
      double activeWeight = 0;
      for (int h = 0; h <= currentHour; h++) {
        activeWeight += weights[h];
      }

      // Use today's date as a seed so jitter is consistent within a day but different each day
      final daySeed = DateTime.now().day * 31 + DateTime.now().month;

      values = List<double>.generate(24, (h) {
        if (h > currentHour || total == 0) return 0.0;
        if (activeWeight == 0) return 0.0;
        // Natural jitter ±15% per hour, seeded per day+hour for consistency
        final jitter = 0.85 + (math.Random(daySeed + h).nextDouble() * 0.3);
        return (total * (weights[h] / activeWeight) * jitter);
      });
    }

    // Dynamic maxY based on actual data
    double peakVal = 0;
    for (var v in values) {
      if (v > peakVal) peakVal = v;
    }
    final maxY = (peakVal * 1.3).clamp(500.0, 10000.0);
    final interval = (maxY / 3).roundToDouble().clamp(200.0, 5000.0);

    Color barColor(double v, int hour) {
      // Future hours = transparent (won't appear)
      if (hour > currentHour) return Colors.transparent;
      // Current hour = highlighted blue
      if (hour == currentHour) return _blue;
      // Past hours color by intensity
      if (v < 200) return _faint.withAlpha(120);
      if (v < 600) return _red;
      if (v < 1500) return _amber;
      if (v < 2200) return Color(0xFFFCD34D);
      return _greenDeep;
    }

    return _card(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'نشاطك على مدار اليوم',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'الآن ${currentHour > 12 ? '${currentHour - 12} م' : '$currentHour ص'}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = group.x;
                      if (h > currentHour) return null;
                      final period = h >= 12 ? 'م' : 'ص';
                      final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                      return BarTooltipItem(
                        '${rod.toY.toInt()} خطوة\n$displayH $period',
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Color(0xFFEEF0F3), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: interval,
                      getTitlesWidget: (v, _) {
                        if (v == 0) return SizedBox.shrink();
                        final label = v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '${v.toInt()}';
                        return Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 9, color: _faint),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 6,
                      getTitlesWidget: (v, _) {
                        final labels = {
                          0: '12 ص',
                          6: '6 ص',
                          12: '12 م',
                          18: '6 م',
                        };
                        final t = labels[v.toInt()];
                        if (t == null) return SizedBox();
                        return Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            t,
                            style: TextStyle(fontSize: 9, color: _faint),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(24, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: i > currentHour ? 0 : values[i].clamp(0, maxY).toDouble(),
                        color: barColor(values[i], i),
                        width: 8,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    final progress = controller.progress;
    final avg = controller.getDailyAverage;
    final steps = controller.stepsToday.value;
    
    String mainTip = '';
    String subTip = '';
    
    if (progress >= 1.0) {
      mainTip = 'جسمك في أفضل حالاته الآن! 💪';
      subTip = 'لقد حققت هدفك، احرص على أخذ قسط من الراحة والاسترخاء.';
    } else if (progress == 0) {
      mainTip = 'المشي المبكر هو وقتك الذهبي! ☀️';
      subTip = '10 دقائق مشي الآن ستضاعف مستوى نشاطك طوال اليوم.';
    } else if (steps > avg && avg > 0) {
      mainTip = 'أنت تتفوق على متوسطك المعتاد! 🚀';
      subTip = 'معدل حرق السعرات لديك اليوم ممتاز، استمر في الحركة.';
    } else if (progress > 0.5) {
      mainTip = 'أفضل وقت لإنهاء نشاطك هو بين 6-8 مساءً.';
      subTip = 'حاول المشي 15 دقيقة إضافية لتحسين طاقتك أكثر.';
    } else {
      mainTip = 'الجلوس طويلاً يقلل من تركيزك! 🚶‍♂️';
      subTip = 'خذ استراحة قصيرة وامشِ لبضع خطوات لتجديد دورتك الدموية.';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _blue.withAlpha(20),
            _purple.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _blue.withAlpha(30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withAlpha(10),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      'نصيحة اليوم',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  mainTip,
                  style: TextStyle(
                    fontSize: 11,
                    color: _text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subTip,
                  style: TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 110,
            height: 90,
            child: CustomPaint(painter: _RunnerScenePainter()),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painters perfectly matching the Mockup ---
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final center = (Offset.zero & size).center;
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color(0xFFEFEFF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        Color(0xFF3B82F6),
        Color(0xFF06B6D4),
        Color(0xFFEC4899),
        Color(0xFF8B5CF6),
        Color(0xFF3B82F6),
      ],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RunnerScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sunPaint = Paint()..color = Color(0xFFFFD24D);
    canvas.drawCircle(Offset(w * 0.18, h * 0.22), 8, sunPaint);

    final trunk = Paint()..color = Color(0xFF8B5E3C);
    canvas.drawRect(Rect.fromLTWH(w * 0.07, h * 0.55, 4, h * 0.25), trunk);
    final leaf = Paint()..color = Color(0xFF22C55E);
    canvas.drawCircle(Offset(w * 0.085, h * 0.55), 10, leaf);

    canvas.drawRect(Rect.fromLTWH(w * 0.92, h * 0.6, 3, h * 0.2), trunk);
    canvas.drawCircle(Offset(w * 0.93, h * 0.6), 8, leaf);

    final ground = Paint()
      ..color = Color(0xFF94A3B8)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h * 0.92), Offset(w, h * 0.92), ground);

    final bodyColor = Paint()..color = Color(0xFF1F2937);
    final shirt = Paint()..color = Color(0xFF60A5FA);
    final skin = Paint()..color = Color(0xFFFCD9B0);

    final cx = w * 0.48, cy = h * 0.55;

    canvas.drawCircle(Offset(cx, cy - 22), 7, skin);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy - 22), radius: 7),
      3.6,
      2.6,
      false,
      bodyColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    bodyColor.style = PaintingStyle.fill;

    final torso = Path()
      ..moveTo(cx - 8, cy - 14)
      ..lineTo(cx + 10, cy - 14)
      ..lineTo(cx + 8, cy + 6)
      ..lineTo(cx - 6, cy + 6)
      ..close();
    canvas.drawPath(torso, shirt);

    final arm1 = Paint()
      ..color = Color(0xFFFCD9B0)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 8, cy - 10), Offset(cx + 18, cy - 4), arm1);
    canvas.drawLine(Offset(cx + 18, cy - 4), Offset(cx + 14, cy - 16), arm1);
    canvas.drawLine(Offset(cx - 8, cy - 10), Offset(cx - 18, cy + 4), arm1);

    final legPaint = Paint()
      ..color = Color(0xFF1E40AF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 4, cy + 6), Offset(cx + 16, cy + 22), legPaint);
    canvas.drawLine(
      Offset(cx + 16, cy + 22),
      Offset(cx + 22, cy + 32),
      legPaint,
    );
    canvas.drawLine(Offset(cx - 2, cy + 6), Offset(cx - 14, cy + 18), legPaint);
    canvas.drawLine(
      Offset(cx - 14, cy + 18),
      Offset(cx - 8, cy + 30),
      legPaint,
    );

    final shoe = Paint()..color = Color(0xFF111827);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 24, cy + 32), width: 10, height: 4),
      shoe,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6, cy + 30), width: 10, height: 4),
      shoe,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
