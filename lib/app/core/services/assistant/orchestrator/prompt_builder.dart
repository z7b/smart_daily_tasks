import 'package:get/get.dart';
import 'intent_analyzer.dart';

class PromptBuilder {
  static String buildSystemPrompt({
    required IntentType intent,
    Map<String, dynamic>? context,
  }) {
    final now = DateTime.now();
    final locale = Get.locale?.languageCode ?? 'ar';
    
    String basePrompt = '''
You are a professional Life OS Assistant. Help the user manage tasks, notes, and health.
Current Time: ${now.toString()}
Language: $locale
''';

    if (intent == IntentType.createTask) {
      basePrompt += '\nThe user wants to create a task. Extract the title and description if provided.';
    }

    basePrompt += '\nBe concise, professional, and support both Arabic and English.';
    
    return basePrompt;
  }
}
