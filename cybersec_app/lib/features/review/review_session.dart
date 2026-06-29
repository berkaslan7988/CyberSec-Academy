import '../quiz_engine/models/question.dart';
import '../quiz_engine/models/quiz.dart';
import 'review_scheduler.dart';

/// Builds a review quiz from all questions that are currently due, drawn across
/// every section quiz. Each returned question carries its composite key
/// ("sectionId/questionId") as its id, so the runner can re-schedule it.
class ReviewSession {
  /// [sectionQuizzes] maps sectionId -> Quiz. Returns the due questions
  /// (shuffled, capped at [limit]).
  static List<Question> buildDueQuestions(
    Map<String, Quiz> sectionQuizzes,
    ReviewScheduler scheduler, {
    int limit = 20,
    DateTime? at,
  }) {
    // Index composite key -> question.
    final index = <String, Question>{};
    sectionQuizzes.forEach((sectionId, quiz) {
      for (final q in quiz.questions) {
        index['$sectionId/${q.id}'] = q;
      }
    });

    final due = scheduler.dueKeys(at: at);
    final questions = <Question>[];
    for (final key in due) {
      final q = index[key];
      if (q != null) questions.add(q.withId(key));
    }
    questions.shuffle();
    return questions.length > limit ? questions.sublist(0, limit) : questions;
  }
}
