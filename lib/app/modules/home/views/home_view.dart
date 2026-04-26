import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_daily_tasks/app/data/models/attendance_log_model.dart';

import 'package:smart_daily_tasks/app/modules/settings/views/settings_view.dart';
import 'package:smart_daily_tasks/app/modules/home/controllers/home_controller.dart';
import 'package:smart_daily_tasks/app/modules/home/widgets/quick_log_strip.dart';

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
            child: _buildActivityHomeCard(context),
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
                    'calendar'.tr,
                    '${controller.calendarEventCount.value.f} ${'events'.tr}',
                    Icons.calendar_month,
                    const Color(0xFFBF5AF2),
                    Routes.CALENDAR,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const bookColor = Color(0xFF5E5CE6);

    return Obx(() {
      final hasBook = controller.currentBookTitle.value.isNotEmpty;
      if (!hasBook && controller.bookCount.value == 0) return const SizedBox();

      return GestureDetector(
        onTap: () => Get.toNamed(Routes.BOOKS),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : bookColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : bookColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: bookColor.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bookColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: bookColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'my_library'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (hasBook)
                    Text(
                      '${(controller.currentBookProgress.value.clamp(0.0, 1.0) * 100).toInt().f}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: bookColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'reading_goal_msg'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: bookColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'read_verb'.tr,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: bookColor,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bookColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width:
                          (Get.width - 96) *
                          controller.currentBookProgress.value.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: bookColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: bookColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'reading_no_active'.tr,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.4),
                    fontWeight: FontWeight.bold,
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => route.isNotEmpty ? Get.toNamed(route) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : moodColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : moodColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: moodColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Obx(
              () => Text(
                controller.moodEmoji.value,
                style: const TextStyle(fontSize: 24),
              ),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    '${'dominant_mood'.tr}: ${controller.weeklyMoodTrend.value.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_graph_rounded,
            size: 20,
            color: moodColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildSalaryHomeCard(BuildContext context) {
    return Obx(() {
      final days = controller.daysUntilSalary.value;
      final now = DateTime.now();
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final elapsedDays = now.day;
      final progress = (elapsedDays / daysInMonth).clamp(0.0, 1.0);

      final Color primaryColor = const Color(0xFF4F46E5); // Indigo 600
      final Color secondaryColor = const Color(0xFF9333EA); // Purple 600

      return GestureDetector(
        onTap: () => Get.toNamed(Routes.JOB),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: isDark ? 0.8 : 0.9),
                secondaryColor.withValues(alpha: isDark ? 0.8 : 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'salary_countdown'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${days.f} ${'days_left'.tr}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    height: 10,
                    width: (Get.width - 96) * progress,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActivityHomeCard(BuildContext context) {
    final healthService = Get.find<HealthService>();

    return Obx(() {
      final authStatus = healthService.isAuthorized.value;
      final isAuth = authStatus == true;
      final isChecking = authStatus == null;
      final isConnecting = healthService.isConnecting.value;

      final Color primaryColor = const Color(
        0xFF0F172A,
      ); // Slate 900 (Deep/Premium)
      final Color accentColor = const Color(0xFF1E293B); // Slate 800
      final Color glowColor = const Color(0xFF22D3EE); // Cyan 400 (Energy)
      final Color progressColor = const Color(0xFF3B82F6); // Blue 500

      return GestureDetector(
        onTap: isAuth ? () => Get.toNamed(Routes.STEPS) : null,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isAuth
                ? LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isAuth ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: isAuth
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
            border: isAuth
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.5,
                  )
                : Border.all(color: Colors.blueAccent.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.bolt_fill,
                      color: glowColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'النشاط والحركة',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isAuth ? Colors.white : null,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (isAuth &&
                                controller.currentStreak.value > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🔥',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${controller.currentStreak.value.f} يوم',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().scale(),
                            ],
                          ],
                        ),
                        if (isAuth)
                          Text(
                            controller.stepsProgress.value >= 1.0
                                ? 'تم تحقيق الهدف! عمل رائع 🎉'
                                : 'استمر! أنت تتقدم بثبات نحو هدفك',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAuth)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 24),

              if (isChecking)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
              else if (!isAuth)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isConnecting
                        ? null
                        : () => controller.connectHealth(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'connect_fit'.tr,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else ...[
                // Steps Display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      controller.stepsCount.value.f,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 42,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'خطوة',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(controller.stepsProgress.value * 100).toInt().f}%',
                          style: TextStyle(
                            color: glowColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'من الهدف',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Enhanced Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      height: 12,
                      width:
                          (Get.width - 96) *
                          controller.stepsProgress.value.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [progressColor, glowColor],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics Grid (Calories, Distance, Active Time)
                Row(
                  children: [
                    _buildPremiumInsight(
                      CupertinoIcons.flame_fill,
                      controller.caloriesCount.value.toInt().f,
                      'سعرة',
                      const Color(0xFFF87171),
                    ),
                    const SizedBox(width: 12),
                    _buildPremiumInsight(
                      CupertinoIcons.location_solid,
                      (controller.distanceCount.value / 1000).fd(2),
                      'كم',
                      const Color(0xFF60A5FA),
                    ),
                    const SizedBox(width: 12),
                    _buildPremiumInsight(
                      CupertinoIcons.timer_fill,
                      (controller.stepsCount.value / 100).toInt().f,
                      'دقيقة',
                      const Color(0xFF34D399),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPremiumInsight(
    IconData icon,
    String value,
    String unit,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextShiftHomeCard(BuildContext context) {
    if (!Get.isRegistered<JobController>()) return const SizedBox();
    final jobCtrl = Get.find<JobController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const jobColor = Color(0xFF5E5CE6);

    return Obx(() {
      try {
        final shiftDetails = jobCtrl.getNextShiftDetails();
        if (shiftDetails == null && jobCtrl.totalMandatedDays.value == 0) {
          return const SizedBox();
        }

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

        final presentCount =
            jobCtrl.statsSummary[AttendanceStatus.present] ?? 0;
        final totalDays = jobCtrl.totalMandatedDays.value;

        return GestureDetector(
          onTap: () => Get.toNamed(Routes.JOB),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : jobColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : jobColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: jobColor.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: jobColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.briefcase_fill,
                        color: jobColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'my_job'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    if (totalDays > 0)
                      Text(
                        '${presentCount.f} / ${totalDays.f}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: jobColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (shiftDetails != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${jobCtrl.profile.value.companyName ?? 'no_company'.tr} • ${jobCtrl.profile.value.jobPosition ?? 'job_position'.tr}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isActive
                                  ? '${'ends'.tr}: $timeLeftStr'
                                  : '${'starts'.tr}: $timeLeftStr',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isActive ? Colors.greenAccent : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: jobColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${TimeOfDay.fromDateTime(start!).format(context).f} - ${TimeOfDay.fromDateTime(end!).format(context).f}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: jobColor,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: const Duration(seconds: 2)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: jobColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        height: 8,
                        width:
                            (Get.width - 96) *
                            (totalDays > 0
                                ? (presentCount / totalDays).clamp(0.0, 1.0)
                                : 0.0),
                        decoration: BoxDecoration(
                          color: jobColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: jobColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'no_shift_scheduled'.tr,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const medColor = Colors.redAccent;

    return Obx(
      () => GestureDetector(
        onTap: () => Get.toNamed('/medication'),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : medColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : medColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: medColor.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: medColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_fill,
                      color: medColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'my_medications'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${controller.medTakenDoses.value} / ${controller.medExpectedDoses.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: medColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (controller.nextMedicationTime.value.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.nextMedicationName.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'remaining'.tr}: ${controller.nextMedicationTimeLeft.value}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: medColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.nextMedicationTime.value,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: medColor,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: medColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width:
                          (Get.width - 96) *
                          (controller.medExpectedDoses.value > 0
                              ? (controller.medTakenDoses.value /
                                    controller.medExpectedDoses.value)
                              : 0.0),
                      decoration: BoxDecoration(
                        color: medColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: medColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No medications scheduled',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskHomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF007AFF);

    return Obx(
      () => GestureDetector(
        onTap: () => Get.toNamed(Routes.TASKS),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : accentColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'tasks'.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (_) {
                      final activeTasks =
                          controller.taskCount.value -
                          controller.cancelledTasksCount.value;
                      return Text(
                        activeTasks > 0
                            ? '${controller.completedTasksCount.value} / $activeTasks'
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
              const SizedBox(height: 20),
              if (controller.nextTaskTitle.value.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.nextTaskTitle.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'remaining'.tr}: ${controller.nextTaskTimeLeft.value}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.nextTaskEndTime.value.isNotEmpty
                                ? '${controller.nextTaskTime.value} - ${controller.nextTaskEndTime.value}'
                                : controller.nextTaskTime.value,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      height: 8,
                      width:
                          (Get.width - 96) *
                          (controller.taskCount.value > 0
                              ? ((controller.taskCount.value -
                                        controller.tasksLeftCount.value) /
                                    controller.taskCount.value)
                              : 0.0),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'No pending tasks',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF3B82F6); // Blue 500
    final secondaryColor = const Color(0xFF8B5CF6); // Violet 500

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: isDark ? 0.9 : 1.0),
            secondaryColor.withValues(alpha: isDark ? 0.9 : 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 40,
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
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        'unified_status'.trParams({
                          'percent': (controller.progressPercentage.value * 100)
                              .toInt()
                              .toString(),
                        }),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Unified Master Progress Bar
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                Obx(
                  () => AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    height: 14,
                    width:
                        constraints.maxWidth *
                        (controller.progressPercentage.value.clamp(0.0, 1.0)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pillars Status Row
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPillarSmall(
                  context,
                  'mind'.tr,
                  controller.mindProgress.value,
                  Colors.blueAccent,
                ),
                _buildPillarSmall(
                  context,
                  'body'.tr,
                  controller.bodyProgress.value,
                  Colors.greenAccent,
                ),
                _buildPillarSmall(
                  context,
                  'spirit'.tr,
                  controller.spiritProgress.value,
                  Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarSmall(
    BuildContext context,
    String label,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 3,
              width: 60 * progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
