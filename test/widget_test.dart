import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:smart_daily_tasks/app/modules/home/views/home_view.dart';
import 'package:smart_daily_tasks/app/modules/home/controllers/home_controller.dart';
import 'package:smart_daily_tasks/app/core/translations/translation_service.dart';

class TestBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}

void main() {
  testWidgets('HomeView smoke test', (WidgetTester tester) async {
    // Setup
    Get.testMode = true;

    // Pump Widget with Binding
    await tester.pumpWidget(
      GetMaterialApp(
        translations: TranslationService(),
        locale: const Locale('en', 'US'), // Force English for test verification
        initialBinding: TestBinding(),
        home: const HomeView(),
      ),
    );

    // Allow animations to settle
    await tester.pumpAndSettle();

    // Verify Dashboard Items are present (using English keys from TranslationService)
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);

    // Verify Greeting is present (Starts with Good...)
    // This confirms translation service is working correctly inside GetMaterialApp
    expect(find.textContaining('Good'), findsWidgets);

    // Clean up
    Get.reset();
  });
}
