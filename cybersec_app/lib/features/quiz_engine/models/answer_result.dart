// Result of evaluating a user's answer.

enum AnswerStatus { correct, partiallyCorrect, incorrect }

class AnswerResult {
  final AnswerStatus status;

  /// 0.0 .. 1.0
  final double score;

  /// Human-readable reasons / what was missing (already localized by caller or
  /// produced as machine keys for the UI to localize).
  final List<String> missing;

  /// The canonical correct answer to show the user (e.g. "nmap -sV 10.10.10.5").
  final String? correctAnswer;

  const AnswerResult({
    required this.status,
    required this.score,
    this.missing = const [],
    this.correctAnswer,
  });

  bool get isCorrect => status == AnswerStatus.correct;

  static const AnswerResult emptyIncorrect =
      AnswerResult(status: AnswerStatus.incorrect, score: 0.0);
}
