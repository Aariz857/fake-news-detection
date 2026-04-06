import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_news_detector/data/models/analysis_result.dart';

/// Local storage service using SharedPreferences.
/// Persists analysis history on-device as JSON strings.
class StorageService {
  static const String _historyKey = 'analysis_history';
  static const int _maxEntries = 20;

  /// Save a result to local history.
  Future<void> saveResult(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Insert at beginning (most recent first)
    history.insert(0, result);

    // Cap at max entries
    final trimmed = history.take(_maxEntries).toList();

    // Serialize and store
    final jsonList = trimmed.map((r) => r.toJsonString()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  /// Get all history entries.
  Future<List<AnalysisResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];

    final results = <AnalysisResult>[];
    for (final jsonStr in jsonList) {
      try {
        results.add(AnalysisResult.fromJsonString(jsonStr));
      } catch (e) {
        // Skip corrupted entries
        continue;
      }
    }
    return results;
  }

  /// Delete a single result by ID.
  Future<bool> deleteResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    final before = history.length;
    history.removeWhere((r) => r.id == id);

    if (history.length == before) return false;

    final jsonList = history.map((r) => r.toJsonString()).toList();
    await prefs.setStringList(_historyKey, jsonList);
    return true;
  }

  /// Clear all history.
  Future<int> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    final count = history.length;
    await prefs.remove(_historyKey);
    return count;
  }

  /// Get the count of stored entries.
  Future<int> getHistoryCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_historyKey) ?? []).length;
  }
}
