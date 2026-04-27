import 'dart:async';
import 'package:get/get.dart';
import '../helpers/log_helper.dart';

/// Centralized Time Service for the entire application.
/// Manages "now" boundaries, day changes, and time-related events.
class TimeService extends GetxService {
  final _now = DateTime.now().obs;
  DateTime get now => _now.value;
  
  final _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).obs;
  DateTime get today => _today.value;

  final onDayChanged = StreamController<DateTime>.broadcast();
  Stream<DateTime> get dayChangedStream => onDayChanged.stream;
  Timer? _midnightTimer;

  Future<TimeService> init() async {
    _startMidnightTimer();
    return this;
  }

  void _startMidnightTimer() {
    _midnightTimer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final timeToMidnight = tomorrow.difference(now);
    
    talker.info('⏳ TimeService: Next midnight in ${timeToMidnight.inHours}h ${timeToMidnight.inMinutes % 60}m');
    
    _midnightTimer = Timer(timeToMidnight, () {
      _handleDayChange();
      _startMidnightTimer(); // Reschedule
    });
  }

  void _handleDayChange() {
    final newNow = DateTime.now();
    final newToday = DateTime(newNow.year, newNow.month, newNow.day);
    
    _now.value = newNow;
    _today.value = newToday;
    
    talker.info('🌙 TimeService: Day change detected! Today is now $newToday');
    onDayChanged.add(newToday);
  }

  @override
  void onClose() {
    _midnightTimer?.cancel();
    onDayChanged.close();
    super.onClose();
  }

  /// Utility to check if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
