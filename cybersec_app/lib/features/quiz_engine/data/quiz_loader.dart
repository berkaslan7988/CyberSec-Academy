import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/quiz.dart';

/// Loads a quiz JSON file bundled under assets/quizzes/.
class QuizLoader {
  static Future<Quiz> loadAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Quiz.fromJson(json);
  }

  /// Loads the per-section quiz map from section_quizzes.json.
  /// Returns sectionId -> Quiz.
  static Future<Map<String, Quiz>> loadSectionQuizzes(
      [String assetPath = 'assets/quizzes/section_quizzes.json']) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final quizzes = (json['quizzes'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final out = <String, Quiz>{};
    quizzes.forEach((sectionId, q) {
      out[sectionId] = Quiz.fromJson(q as Map<String, dynamic>);
    });
    return out;
  }
}
