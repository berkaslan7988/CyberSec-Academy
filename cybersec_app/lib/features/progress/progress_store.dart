import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks learning progress across the app and persists it to disk via
/// shared_preferences, so progress survives app restarts.
///
/// Data is small and key/value shaped (a set of read topics + per-section
/// scores), which is exactly what shared_preferences is good at. If richer
/// querying/statistics are needed later, swap the backend for Drift/SQLite —
/// the public API below stays the same.
class ProgressStore extends ChangeNotifier {
  // Storage keys.
  static const _kRead = 'progress.readTopics';
  static const _kBest = 'progress.bestScore';
  static const _kAttempts = 'progress.attempts';

  SharedPreferences? _prefs;

  // Keys are "sectionId/topicId".
  final Set<String> _readTopics = {};
  // sectionId -> best quiz score percent (0..100).
  final Map<String, int> _bestScore = {};
  // sectionId -> number of quiz attempts.
  final Map<String, int> _attempts = {};

  String _key(String sectionId, String topicId) => '$sectionId/$topicId';

  /// Loads persisted progress. Call once at startup before showing the UI.
  /// Safe to call even if storage is empty or unavailable.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;

      _readTopics
        ..clear()
        ..addAll(prefs.getStringList(_kRead) ?? const []);

      _bestScore
        ..clear()
        ..addAll(_decodeIntMap(prefs.getString(_kBest)));

      _attempts
        ..clear()
        ..addAll(_decodeIntMap(prefs.getString(_kAttempts)));

      notifyListeners();
    } catch (_) {
      // If persistence isn't available, fall back to in-memory only.
    }
  }

  Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ---- topic reading ----
  void markRead(String sectionId, String topicId) {
    final k = _key(sectionId, topicId);
    if (_readTopics.add(k)) {
      _prefs?.setStringList(_kRead, _readTopics.toList());
      notifyListeners();
    }
  }

  bool isRead(String sectionId, String topicId) =>
      _readTopics.contains(_key(sectionId, topicId));

  /// How many topics of [sectionId] have been read, given that section's ids.
  int readCount(String sectionId, Iterable<String> topicIds) =>
      topicIds.where((t) => isRead(sectionId, t)).length;

  // ---- quiz scores ----
  void recordQuiz(String sectionId, int percent) {
    _attempts[sectionId] = (_attempts[sectionId] ?? 0) + 1;
    final prev = _bestScore[sectionId];
    if (prev == null || percent > prev) {
      _bestScore[sectionId] = percent;
    }
    _prefs?.setString(_kBest, jsonEncode(_bestScore));
    _prefs?.setString(_kAttempts, jsonEncode(_attempts));
    notifyListeners();
  }

  int? bestScore(String sectionId) => _bestScore[sectionId];
  int attempts(String sectionId) => _attempts[sectionId] ?? 0;

  // ---- overall ----
  int get totalReadTopics => _readTopics.length;

  /// Clears all progress (in-memory and persisted).
  Future<void> reset() async {
    _readTopics.clear();
    _bestScore.clear();
    _attempts.clear();
    await _prefs?.remove(_kRead);
    await _prefs?.remove(_kBest);
    await _prefs?.remove(_kAttempts);
    notifyListeners();
  }
}
