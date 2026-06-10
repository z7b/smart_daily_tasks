import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/helpers/log_helper.dart';

class WidgetGallerySheet extends StatefulWidget {
  const WidgetGallerySheet({super.key});

  @override
  State<WidgetGallerySheet> createState() => _WidgetGallerySheetState();
}

class _WidgetGallerySheetState extends State<WidgetGallerySheet> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Pin a widget on Android, show guide on iOS
  Future<void> _pinWidget(String providerName, String widgetTitle) async {
    if (Platform.isIOS) {
      _showIosGuide();
      return;
    }

    try {
      // Check if launcher supports pin widget
      final isSupported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      
      if (!isSupported) {
        talker.info('📌 Pin widget not supported, showing manual guide');
        _showAndroidGuide(widgetTitle);
        return;
      }

      talker.info('📌 Requesting pin for widget: $providerName');
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: 'com.rattib.app.$providerName',
      );
      Get.rawSnackbar(
        title: 'success'.tr,
        message: 'widget_added_successfully'.trParams({'name': widgetTitle}),
        backgroundColor: const Color(0xFF34C759),
      );
    } catch (e) {
      talker.error('❌ Failed to pin widget: $e, falling back to guide');
      _showAndroidGuide(widgetTitle);
    }
  }

  // Show manual guide for Android (fallback)
  void _showAndroidGuide(String widgetTitle) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('add_to_home_screen'.tr, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('1. ${'android_widget_step_1'.tr}'),
            const SizedBox(height: 6),
            Text('2. ${'android_widget_step_2'.tr}'),
            const SizedBox(height: 6),
            Text('3. ${'android_widget_step_3'.tr}'),
            const SizedBox(height: 6),
            Text('4. ${'android_widget_step_4'.tr}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('close'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  // Show manual guide for iOS
  void _showIosGuide() {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text('ios_widget_guide_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('1. ${'ios_widget_step_1'.tr}'),
            const SizedBox(height: 4),
            Text('2. ${'ios_widget_step_2'.tr}'),
            const SizedBox(height: 4),
            Text('3. ${'ios_widget_step_3'.tr}'),
            const SizedBox(height: 4),
            Text('4. ${'ios_widget_step_4'.tr}'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('close'.tr),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> widgetItems = [
      {
        'id': 'life_os',
        'provider': 'LifeOsWidgetProvider',
        'title': 'life_os_widget_title'.tr,
        'desc': 'life_os_widget_desc'.tr,
        'gradient': [const Color(0xFF6366F1), const Color(0xFF3B82F6)],
        'mock': _buildLifeOsMockup(),
      },
      {
        'id': 'tasks',
        'provider': 'TasksWidgetProvider',
        'title': 'tasks_widget_title'.tr,
        'desc': 'tasks_widget_desc'.tr,
        'color': const Color(0xFF0B0F19),
        'border': const Color(0xFF312E81),
        'mock': _buildTasksMockup(),
      },
      {
        'id': 'appointments',
        'provider': 'AppointmentsWidgetProvider',
        'title': 'appointments_widget_title'.tr,
        'desc': 'appointments_widget_desc'.tr,
        'gradient': [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        'mock': _buildAppointmentsMockup(),
      },
      {
        'id': 'medications',
        'provider': 'MedicationsWidgetProvider',
        'title': 'medications_widget_title'.tr,
        'desc': 'medications_widget_desc'.tr,
        'gradient': [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
        'mock': _buildMedicationsMockup(),
      },
      {
        'id': 'whiteboard',
        'provider': 'WhiteboardWidgetProvider',
        'title': 'whiteboard_widget_title'.tr,
        'desc': 'whiteboard_widget_desc'.tr,
        'color': const Color(0xFFFEF08A),
        'border': const Color(0xFFFDE047),
        'mock': _buildWhiteboardMockup(),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'widgets_gallery_title'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'widgets_gallery_subtitle'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 20),
            
            // Swipeable Widgets Mockups
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widgetItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widgetItems[index];
                  final isSelected = index == _currentPage;
                  
                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.92,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: item['color'],
                        gradient: item['gradient'] != null
                            ? LinearGradient(
                                colors: item['gradient'],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        border: item['border'] != null
                            ? Border.all(color: item['border'], width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: item['mock'],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widgetItems.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppTheme.primary
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Widget Details & Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    widgetItems[_currentPage]['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widgetItems[_currentPage]['desc'],
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _pinWidget(
                        widgetItems[_currentPage]['provider'],
                        widgetItems[_currentPage]['title'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        Platform.isIOS ? 'how_to_activate'.tr : 'add_to_home_screen'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOCKUP WIDGETS BUILDERS ---

  Widget _buildLifeOsMockup() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✨ رتّب',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ],
          ),
          const Spacer(),
          const Text(
            'تكامل حياتك الذكية',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'نظامك متكامل بنسبة 75%',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '75%',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksMockup() {
    const textStyle = TextStyle(color: Color(0xFFE8E8FF), fontSize: 12);
    
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✅ المهام اليومية',
                style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '3 متبقية',
                style: TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            height: 1,
            color: const Color(0xFF1F1F3A),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          // Task 1
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('جلسة القراءة المسائية', style: textStyle, maxLines: 1)),
            ],
          ),
          const SizedBox(height: 8),
          // Task 2
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF818CF8)),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('تحضير حقيبة النادي الرياضي', style: textStyle, maxLines: 1)),
            ],
          ),
          const SizedBox(height: 8),
          // Task 3
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('مراجعة قائمة المصروفات', style: textStyle, maxLines: 1)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  child: LinearProgressIndicator(
                    value: 0.4,
                    backgroundColor: Color(0xFF1F1F3A),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '2/5',
                style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsMockup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏥 مواعيد الطبيب',
                style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'قريباً',
                style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            height: 1,
            color: const Color(0xFF0A2A1E),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0F3D2E),
                ),
                alignment: Alignment.center,
                child: const Text('د', style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'د. سليمان السعدون',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'استشاري طب الأسرة',
                    style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2B20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('⏰ ', style: TextStyle(fontSize: 10)),
                      Expanded(
                        child: Text(
                          'غداً 04:30 م',
                          style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2B20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text('📍 ', style: TextStyle(fontSize: 10)),
                      Expanded(
                        child: Text(
                          'مستشفى الحبيب',
                          style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 9, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildMedicationsMockup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '💊 علاجاتي',
                style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '3/5',
                style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            height: 1,
            color: const Color(0xFF0A1A3A),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          const Text(
            'تم تناول 3 من 5 جرعات اليوم',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Color(0xFF0A1A3A),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1B3A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('3', style: TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('تم تناوله', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1B3A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('2', style: TextStyle(color: Color(0xFFF87171), fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('متبقي', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1B3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⏰ الجرعة القادمة', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 8)),
                    SizedBox(height: 1),
                    Text('أوميغا 3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('09:00 م', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteboardMockup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📌 الصبورة',
                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'مثبتة',
                style: TextStyle(color: Color(0xFF4338CA), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Text(
            '❝',
            style: TextStyle(color: Color(0xFFCA8A04), fontSize: 22, height: 0.8),
          ),
          const Text(
            '💡 فكرة مشروع الوجت:\nتصميم واجهات مصغرة فائقة الجمال متصلة بقاعدة البيانات وتعمل بالخلفية بشكل دائم وسلس.',
            style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.black.withValues(alpha: 0.1))),
              const SizedBox(width: 6),
              const Text('رتّب', style: TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
