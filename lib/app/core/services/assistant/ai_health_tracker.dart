enum ProviderStatus { healthy, degraded, dead }

class AiHealthTracker {
  static final Map<String, DateTime> _cooldowns = {};
  static final Map<String, int> _errorCounts = {};

  /// Marks a provider/model combo as degraded (e.g. after a 429)
  static void markDegraded(String providerId, String model, {Duration cooldown = const Duration(minutes: 5)}) {
    final key = '$providerId:$model';
    _cooldowns[key] = DateTime.now().add(cooldown);
    _errorCounts[key] = (_errorCounts[key] ?? 0) + 1;
  }

  /// Checks if a provider/model is currently healthy
  static bool isHealthy(String providerId, String model) {
    final key = '$providerId:$model';
    final cooldown = _cooldowns[key];
    if (cooldown == null) return true;
    
    if (DateTime.now().isAfter(cooldown)) {
      _cooldowns.remove(key);
      return true;
    }
    return false;
  }

  /// Gets remaining cooldown time if any
  static Duration? getRemainingCooldown(String providerId, String model) {
    final key = '$providerId:$model';
    final cooldown = _cooldowns[key];
    if (cooldown == null) return null;
    
    final diff = cooldown.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  static void reset(String providerId, String model) {
    final key = '$providerId:$model';
    _cooldowns.remove(key);
    _errorCounts[key] = 0;
  }
}
