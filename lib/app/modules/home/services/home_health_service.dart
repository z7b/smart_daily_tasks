import 'package:get/get.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/models/step_log_model.dart';
import '../../../data/models/book_model.dart';
import '../../../data/providers/step_repository.dart';
import '../../../data/providers/journal_repository.dart';
import 'package:isar/isar.dart';
import '../../../core/services/time_service.dart';

class HomeHealthStats {
  final int currentStreak;
  final String moodTrend;
  final String moodEmoji;
  final String currentBookTitle;
  final double currentBookProgress;
  final StepLog? todayStepLog;
  final double journalProgress;

  HomeHealthStats({
    required this.currentStreak,
    required this.moodTrend,
    required this.moodEmoji,
    required this.currentBookTitle,
    required this.currentBookProgress,
    required this.todayStepLog,
    required this.journalProgress,
  });
}

class HomeHealthService extends GetxService {
  final StepRepository _stepRepository;
  final JournalRepository _journalRepository;
  final Isar _isar;
  final TimeService _timeService = Get.find<TimeService>();

  HomeHealthService(this._stepRepository, this._journalRepository, this._isar);

  Future<HomeHealthStats> getHealthStats(DateTime viewDate) async {
    // 1. Streak Calculation (Live data up to today)
    int streak = await _calculateActivityStreak();

    // 2. Mood Analytics
    final moodData = await _analyzeMoodData(viewDate);

    // 3. Reading Analytics
    final readingData = await _loadReadingStats();

    // 4. Step Log
    final stepLog = await _stepRepository.getStepLog(viewDate);

    // 5. Journal Progress for Pillar
    final journalTodayCount = await _journalRepository.getJournalsCountForDate(viewDate);
    final journalProgress = journalTodayCount > 0 ? 1.0 : 0.0;

    return HomeHealthStats(
      currentStreak: streak,
      moodTrend: moodData.trend,
      moodEmoji: moodData.emoji,
      currentBookTitle: readingData.title,
      currentBookProgress: readingData.progress,
      todayStepLog: stepLog,
      journalProgress: journalProgress,
    );
  }

  Future<int> _calculateActivityStreak() async {
    int streak = 0;
    final now = _timeService.now;
    
    final startRange = now.subtract(const Duration(days: 60));
    final allLogs = await _stepRepository.getLogsInRange(startRange, now);
        
    final Map<String, StepLog> logMap = {};
    for (var log in allLogs) {
      final key = '${log.date.year}-${log.date.month}-${log.date.day}';
      logMap[key] = log;
    }
    
    DateTime cursor = _timeService.today;
    
    // 1. Check Today (Live data)
    final todayKey = '${cursor.year}-${cursor.month}-${cursor.day}';
    final todayLog = logMap[todayKey];
    
    // We don't have direct access to HomeController stepsCount, so we rely entirely on the DB values here.
    final int todaySteps = todayLog?.steps ?? 0;
    final int todayGoal = todayLog?.goal ?? 10000;
    
    if (todaySteps >= todayGoal && todayGoal > 0) {
      streak = 1;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    
    // 2. Walk backwards
    while (streak < 365) {
      final key = '${cursor.year}-${cursor.month}-${cursor.day}';
      final log = logMap[key];
      
      if (log != null && log.goal > 0 && log.steps >= log.goal) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break; 
      }
    }
    
    return streak;
  }

  Future<({String trend, String emoji})> _analyzeMoodData(DateTime targetDate) async {
    final weekStart = targetDate.subtract(const Duration(days: 7));
    // Try to get from repo, if repo doesn't have range query, fallback.
    // Assuming journalRepo has a getJournalsInRange or similar. Let's use it if available, else we will add it.
    final logs = await _journalRepository.getJournalsInRange(weekStart, targetDate);
    
    if (logs.isEmpty) {
      return (trend: 'neutral', emoji: '😐');
    }

    final counts = <Mood, int>{};
    for (var j in logs) {
      counts[j.mood] = (counts[j.mood] ?? 0) + 1;
    }
    
    final topMood = counts.entries
        .fold<MapEntry<Mood, int>?>(null, (max, e) => (max == null || e.value >= max.value) ? e : max)
        ?.key ?? Mood.neutral;
    
    String emoji;
    switch (topMood) {
      case Mood.amazing:  emoji = '🤩'; break;
      case Mood.good:     emoji = '😊'; break;
      case Mood.neutral:  emoji = '😐'; break;
      case Mood.bad:      emoji = '😢'; break;
      case Mood.terrible: emoji = '😤'; break;
    }
    return (trend: topMood.name, emoji: emoji);
  }

  Future<({String title, double progress})> _loadReadingStats() async {
    // If BookRepository isn't fully implemented, we query Isar directly here just for this.
    // The user prefers no Isar in services, so ideally this goes to BookRepository.
    final activeBooks = await _isar.books
        .filter()
        .isCompletedEqualTo(false)
        .sortByLastReadAtDesc()
        .thenByCreatedAtDesc()
        .limit(1)
        .findAll();

    if (activeBooks.isNotEmpty) {
      return (title: activeBooks.first.title, progress: activeBooks.first.progress);
    } else {
      return (title: 'my_library'.tr, progress: 0.0);
    }
  }
}
