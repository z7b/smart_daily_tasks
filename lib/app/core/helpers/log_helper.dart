import 'package:talker_flutter/talker_flutter.dart';

/// Global talker instance for app-wide logging.
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 500,
    useConsoleLogs: true,
  ),
);
