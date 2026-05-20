/// Pure Dart medication scheduling helper — zero Flutter/GetX dependencies.
///
/// All methods operate on **minutes-from-midnight** (0–1439) integers,
/// making them trivially unit-testable without any platform or locale setup.
///
/// The [MedicationController] converts between TimeOfDay/String and these
/// integers when calling these helpers.
class MedicationSchedulerHelper {
  // ──────────────────────────────────────────────────────────
  // Sleep-Zone Clamping
  // ──────────────────────────────────────────────────────────

  /// Shifts a dose hour away from the sleep zone (01:00–05:00).
  ///
  /// - Hours 01–02 → 23 (pre-sleep, still the same night)
  /// - Hours 03–05 → 06 (post-wake, first thing in the morning)
  /// - Hour 00 is intentionally left unchanged (some medications are valid at midnight)
  ///
  /// Returns the clamped hour (0–23).
  static int applySleepZoneClamping(int hour) {
    assert(hour >= 0 && hour <= 23, 'hour must be in [0, 23]');
    if (hour >= 1 && hour <= 5) {
      return hour < 3 ? 23 : 6;
    }
    return hour;
  }

  // ──────────────────────────────────────────────────────────
  // Minimum Spacing Enforcement
  // ──────────────────────────────────────────────────────────

  /// Removes doses that fall too close to their predecessor after
  /// sleep-zone clamping.
  ///
  /// [sortedMinutes] — list of minutes-from-midnight, **sorted ascending**.
  /// [minimumMinutes] — minimum required gap between consecutive doses.
  ///
  /// Handles midnight wrap-around correctly
  /// (e.g. 23:00 → 01:00 = 120 min, not –1320).
  ///
  /// Returns a named record `(kept, skipped)`:
  /// - `kept`    — doses that passed the spacing check
  /// - `skipped` — doses that were too close and were removed
  static ({List<int> kept, List<int> skipped}) enforceMinimumSpacing(
    List<int> sortedMinutes,
    int minimumMinutes,
  ) {
    assert(minimumMinutes >= 0, 'minimumMinutes must be non-negative');

    if (sortedMinutes.isEmpty) return (kept: [], skipped: []);
    if (sortedMinutes.length == 1) {
      return (kept: List.of(sortedMinutes), skipped: []);
    }

    final kept = <int>[sortedMinutes.first];
    final skipped = <int>[];

    for (int i = 1; i < sortedMinutes.length; i++) {
      final prev = kept.last;
      final curr = sortedMinutes[i];

      int diff = curr - prev;
      if (diff < 0) diff += 1440; // handle midnight wrap-around

      if (diff >= minimumMinutes) {
        kept.add(curr);
      } else {
        skipped.add(curr);
      }
    }

    return (kept: kept, skipped: skipped);
  }

  // ──────────────────────────────────────────────────────────
  // Time Generation (Interval-based)
  // ──────────────────────────────────────────────────────────

  /// Generates dose times for **interval-based** scheduling
  /// (e.g. "every 4 hours starting at 08:00").
  ///
  /// Returns `(kept, skipped)` after applying sleep-zone clamping and
  /// minimum-spacing enforcement.
  static ({List<int> kept, List<int> skipped}) generateIntervalTimes({
    required int startHour,
    required int startMinute,
    required int intervalHours,
  }) {
    if (intervalHours <= 0) return (kept: [], skipped: []);

    final int count = (24 / intervalHours).ceil();
    final rawMinutes = <int>{};

    for (int i = 0; i < count; i++) {
      int hour = (startHour + (i * intervalHours)) % 24;
      hour = applySleepZoneClamping(hour);
      rawMinutes.add(hour * 60 + startMinute);
    }

    final sorted = rawMinutes.toList()..sort();
    // Minimum = half the interval (at least 2 h = 120 min)
    final minimumMinutes = _max(intervalHours * 30, 120);
    return enforceMinimumSpacing(sorted, minimumMinutes);
  }

  // ──────────────────────────────────────────────────────────
  // Time Generation (Frequency-based)
  // ──────────────────────────────────────────────────────────

  /// Generates dose times for **frequency-based** scheduling
  /// (e.g. "3 times a day starting at 08:00").
  ///
  /// [frequency]   — number of daily doses (1–24).
  /// [wakingHours] — configurable waking day length (default 16 h).
  ///
  /// Returns `(kept, skipped)` after applying sleep-zone clamping and
  /// minimum-spacing enforcement.
  static ({List<int> kept, List<int> skipped}) generateFrequencyTimes({
    required int startHour,
    required int startMinute,
    required int frequency,
    int wakingHours = 16,
  }) {
    if (frequency <= 0 || frequency > 24) return (kept: [], skipped: []);

    final int interval = frequency > 1 ? wakingHours ~/ (frequency - 1) : 0;
    final rawMinutes = <int>{};

    for (int i = 0; i < frequency; i++) {
      int hour = ((startHour + (i * interval)) % 24).toInt();
      hour = applySleepZoneClamping(hour);
      rawMinutes.add(hour * 60 + startMinute);
    }

    final sorted = rawMinutes.toList()..sort();
    final safeMinimum = interval > 0 ? _max(interval * 30, 120) : 120;
    return enforceMinimumSpacing(sorted, safeMinimum);
  }

  // ──────────────────────────────────────────────────────────
  // Utilities
  // ──────────────────────────────────────────────────────────

  static int _max(int a, int b) => a > b ? a : b;

  /// Converts minutes-from-midnight to a human-readable "HH:MM" string (24 h).
  /// Useful for debugging and log output.
  static String minutesToHhmm(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
