import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/app/core/translations/messages.dart');
  
  if (!enFile.existsSync()) {
    print('messages.dart not found!');
    return;
  }
  
  final enContent = enFile.readAsStringSync();
  final enRegex = RegExp(r"'([a-zA-Z0-9_]+)':\s*'([^']*)'");
  final enMatches = enRegex.allMatches(enContent);
  
  final enMap = <String, String>{};
  for (final m in enMatches) {
    enMap[m.group(1)!] = m.group(2)!;
  }
  
  final langs = ['fr_fr', 'es_es', 'hi_in', 'ru_ru'];
  final exportData = <String, Map<String, String>>{};
  
  for (final lang in langs) {
    final file = File('lib/app/core/translations/\$lang.dart');
    if (!file.existsSync()) continue;
    
    final content = file.readAsStringSync();
    final keys = RegExp(r"'([a-zA-Z0-9_]+)':\s*'").allMatches(content).map((m) => m.group(1)!).toSet();
    
    final missingKeys = enMap.keys.toSet().difference(keys);
    
    exportData[lang] = {};
    for (final key in missingKeys) {
      exportData[lang]![key] = enMap[key]!; // Export the English text to be translated
    }
    print('Exported \${missingKeys.length} missing keys for \$lang');
  }
  
  File('missing_translations.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(exportData));
  print('Successfully saved missing translations to missing_translations.json');
}
