import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../controllers/home_controller.dart';
import '../../../routes/app_routes.dart';

class SpacesView extends GetView<HomeController> {
  const SpacesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'spaces'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95, // ✅ Adjusted for better text fit
                  children: [
                    _buildSpaceCard(
                      context,
                      title: 'tasks'.tr, // ✅ Fixed: Showing "المهام"
                      colors: const [Color(0xFF007AFF), Color(0xFF5E5CE6)],
                      fallbackIcon: Icons.task_alt_rounded,
                      onTap: () => Get.toNamed(Routes.TASKS),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'notes'.tr, // ✅ Fixed: Showing "الملاحظات"
                      colors: const [Color(0xFFFF9500), Color(0xFFFF2D55)],
                      fallbackIcon: Icons.edit_note_rounded,
                      onTap: () => Get.toNamed(Routes.NOTES),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'my_library'.tr,
                      colors: const [Color(0xFF5E5CE6), Color(0xFFBF5AF2)],
                      fallbackIcon: Icons.menu_book_rounded,
                      onTap: () => Get.toNamed(Routes.BOOKS),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'my_medications'.tr,
                      colors: const [Color(0xFFFF2D55), Color(0xFFFF375F)],
                      fallbackIcon: Icons.medical_services_rounded,
                      onTap: () => Get.toNamed(Routes.MEDICATION),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'bookmarks'.tr,
                      colors: const [Color(0xFFFF3B30), Color(0xFFFF9500)],
                      fallbackIcon: Icons.bookmark_rounded,
                      onTap: () => Get.toNamed(Routes.BOOKMARKS),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'journal'.tr,
                      colors: const [Color(0xFF34C759), Color(0xFF30B0C7)],
                      fallbackIcon: Icons.book_rounded,
                      onTap: () => Get.toNamed(Routes.JOURNAL),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'assistant'.tr,
                      colors: const [Color(0xFF8E8E93), Color(0xFF636366)],
                      fallbackIcon: Icons.auto_awesome_rounded,
                      onTap: () => Get.toNamed(Routes.ASSISTANT),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'calendar'.tr,
                      colors: const [Color(0xFFBF5AF2), Color(0xFFFF2D55)],
                      fallbackIcon: Icons.calendar_month_rounded,
                      onTap: () => Get.toNamed(Routes.CALENDAR),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'my_steps'.tr,
                      colors: const [Color(0xFF34C759), Color(0xFF00C7BE)],
                      fallbackIcon: Icons.directions_walk_rounded,
                      onTap: () => Get.toNamed(Routes.STEPS),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'my_job'.tr,
                      colors: const [Color(0xFF5E5CE6), Color(0xFFBF5AF2)],
                      fallbackIcon: Icons.business_center_rounded,
                      onTap: () => Get.toNamed(Routes.JOB),
                    ),
                    _buildSpaceCard(
                      context,
                      title: 'doctor_appointments'.tr,
                      colors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                      fallbackIcon: Icons.local_hospital_rounded,
                      onTap: () => Get.toNamed(Routes.APPOINTMENTS),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceCard(
    BuildContext context, {
    required String title,
    required List<Color> colors,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                maxLines: 2, // ✅ Prevents overflow
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: _buildIcon(fallbackIcon: fallbackIcon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({required IconData fallbackIcon}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(60),
          width: 1.2,
        ),
      ),
      child: Center(child: Icon(fallbackIcon, size: 26, color: Colors.white)),
    );
  }
}
