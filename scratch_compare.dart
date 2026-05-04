import 'dart:io';

void main() {
  final enFile = File('lib/app/core/translations/messages.dart');
  final frFile = File('lib/app/core/translations/fr_fr.dart');
  
  if (!enFile.existsSync()) {
    print('messages.dart not found!');
    return;
  }
  
  // Extract keys from EN dictionary in messages.dart
  final enContent = enFile.readAsStringSync();
  final enRegex = RegExp(r"'([a-zA-Z0-9_]+)':\s*'");
  final enKeys = enRegex.allMatches(enContent).map((m) => m.group(1)!).toSet();
  
  print('Found ${enKeys.length} keys in messages.dart');
  
  final langs = ['fr_fr', 'es_es', 'hi_in', 'ru_ru', 'zh_cn', 'zh_tw'];
  
  for (final lang in langs) {
    final file = File('lib/app/core/translations/$lang.dart');
    if (!file.existsSync()) continue;
    
    final content = file.readAsStringSync();
    final keys = enRegex.allMatches(content).map((m) => m.group(1)!).toSet();
    
    final missing = enKeys.difference(keys);
    print('\nMissing in $lang (${missing.length}):');
    if (missing.length > 50) {
      print("  ${missing.take(50).join(', ')} ... and ${missing.length - 50} more");
    } else {
      print("  ${missing.join(', ')}");
    }
  }
}
