import 'dart:io';
void main() {
  var file = File('lib/app/core/translations/messages.dart');
  var lines = file.readAsLinesSync();
  var enKeys = <String>{};
  var arKeys = <String>{};
  var currentMap = '';
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.contains("'en': {")) currentMap = 'en';
    else if (line.contains("'ar': {")) currentMap = 'ar';
    
    var match = RegExp(r"^\s*'([^']+)'\s*:").firstMatch(line);
    if (match != null) {
      var key = match.group(1)!;
      if (currentMap == 'en') {
        if (enKeys.contains(key)) print('Duplicate EN: \ at \');
        enKeys.add(key);
      } else if (currentMap == 'ar') {
        if (arKeys.contains(key)) print('Duplicate AR: \ at \');
        arKeys.add(key);
      }
    }
  }
}
