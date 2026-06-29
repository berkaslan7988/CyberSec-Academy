import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spaced-repetition scheduler using a Leitner box system, persisted to disk.
///
/// Each card (keyed by "sectionId/questionId") has a box (1..6) and a due time.
/// Answering correctly promotes the card to a higher box (longer interval);
/// answering wrong resets it to box 1 (due again very soon). A card becomes due
/// for review when its due time has passed.
class ReviewScheduler extends ChangeNotifier {
  static const _kCards = 'review.cards';

  /// Interval per box, in days. Index 0 unused; box 1..6.
  static const List<int> boxDays = [0, 0, 1, 3, 7, 16, 35];
  static const int maxBox = 6;

  SharedPreferences? _prefs;

  // key -> card
  final Map<String, _Card> _cards = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      final raw = prefs.getString(_kCards);
      _cards.clear();
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        m.forEach((k, v) {
          final c = v as Map<String, dynamic>;
          _cards[k] = _Card(
            box: (c['b'] as num?)?.toInt() ?? 1,
            dueMs: (c['d'] as num?)?.toInt() ?? 0,
          );
        });
      }
      notifyListeners();
    } catch (_) {
      // in-memory fallback
    }
  }

  void _persist() {
    final m = _cards.map((k, c) => MapEntry(k, {'b': c.box, 'd': c.dueMs}));
    _prefs?.setString(_kCards, jsonEncode(m));
  }

  /// Record an answer. [correct] promotes; otherwise reset to box 1.
  void record(String key, bool correct, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final existing = _cards[key];
    int box;
    if (correct) {
      box = ((existing?.box ?? 1) + 1).clamp(1, maxBox);
    } else {
      box = 1;
    }
    final due = now.add(Duration(days: boxDays[box]));
    _cards[key] = _Card(box: box, dueMs: due.millisecondsSinceEpoch);
    _persist();
    notifyListeners();
  }

  /// Keys whose due time has passed (ready for review now).
  List<String> dueKeys({DateTime? at}) {
    final nowMs = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final out = <String>[];
    _cards.forEach((k, c) {
      if (c.dueMs <= nowMs) out.add(k);
    });
    return out;
  }

  int dueCount({DateTime? at}) => dueKeys(at: at).length;

  int get trackedCount => _cards.length;
  int? box(String key) => _cards[key]?.box;

  Future<void> reset() async {
    _cards.clear();
    await _prefs?.remove(_kCards);
    notifyListeners();
  }
}

class _Card {
  final int box;
  final int dueMs;
  const _Card({required this.box, required this.dueMs});
}
