// Dispatches answer evaluation by question type. Pure Dart.

import '../models/answer_result.dart';
import '../models/question.dart';
import 'command_evaluator.dart';

class AnswerEvaluator {
  /// [userAnswer] shape depends on the question type:
  ///   multipleChoice -> Set<int> (selected option indices)
  ///   trueFalse      -> int (selected option index, 0/1)
  ///   fillBlank      -> String
  ///   command        -> String
  ///   matching       -> Map<int,int> (leftIndex -> chosen rightIndex)
  ///   ordering       -> List<int> (the user's order, as original indices)
  static AnswerResult evaluate(Question q, Object? userAnswer) {
    switch (q.type) {
      case QuestionType.multipleChoice:
        return _evalChoice(q, userAnswer);
      case QuestionType.trueFalse:
        return _evalTrueFalse(q, userAnswer);
      case QuestionType.fillBlank:
        return _evalFillBlank(q, userAnswer);
      case QuestionType.command:
        return CommandEvaluator.evaluate((userAnswer ?? '').toString(), q);
      case QuestionType.matching:
        return _evalMatching(q, userAnswer);
      case QuestionType.ordering:
        return _evalOrdering(q, userAnswer);
    }
  }

  static AnswerResult _evalChoice(Question q, Object? userAnswer) {
    final selected = _asIntSet(userAnswer);
    final correct = <int>{};
    for (var i = 0; i < q.options.length; i++) {
      if (q.options[i].correct) correct.add(i);
    }
    final status = _setsEqual(selected, correct)
        ? AnswerStatus.correct
        : (selected.intersection(correct).isNotEmpty &&
                selected.difference(correct).isEmpty
            ? AnswerStatus.partiallyCorrect
            : AnswerStatus.incorrect);
    return AnswerResult(
      status: status,
      score: status == AnswerStatus.correct ? 1.0 : 0.0,
      correctAnswer: correct.map((i) => q.options[i].label.en).join(', '),
    );
  }

  static AnswerResult _evalTrueFalse(Question q, Object? userAnswer) =>
      _evalChoice(q, userAnswer is int ? {userAnswer} : userAnswer);

  static AnswerResult _evalFillBlank(Question q, Object? userAnswer) {
    final ans = (userAnswer ?? '').toString().trim().toLowerCase();
    final ok = q.acceptedAnswers.any((a) => a.trim().toLowerCase() == ans);
    return AnswerResult(
      status: ok ? AnswerStatus.correct : AnswerStatus.incorrect,
      score: ok ? 1.0 : 0.0,
      correctAnswer: q.acceptedAnswers.isNotEmpty ? q.acceptedAnswers.first : null,
    );
  }

  static AnswerResult _evalMatching(Question q, Object? userAnswer) {
    final map = (userAnswer is Map)
        ? userAnswer.map((k, v) => MapEntry(k as int, v as int))
        : <int, int>{};
    var correct = 0;
    // Correct mapping is identity: pair[i].left -> pair[i].right.
    for (var i = 0; i < q.pairs.length; i++) {
      if (map[i] == i) correct++;
    }
    final total = q.pairs.length;
    final score = total == 0 ? 0.0 : correct / total;
    return AnswerResult(
      status: correct == total
          ? AnswerStatus.correct
          : (correct == 0 ? AnswerStatus.incorrect : AnswerStatus.partiallyCorrect),
      score: score,
    );
  }

  static AnswerResult _evalOrdering(Question q, Object? userAnswer) {
    final order = (userAnswer is List)
        ? userAnswer.map((e) => e as int).toList()
        : <int>[];
    // Correct order is 0,1,2,...,n-1 (orderedItems is already in correct order).
    var correct = order.isNotEmpty;
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) {
        correct = false;
        break;
      }
    }
    return AnswerResult(
      status: correct ? AnswerStatus.correct : AnswerStatus.incorrect,
      score: correct ? 1.0 : 0.0,
    );
  }

  static Set<int> _asIntSet(Object? v) {
    if (v is Set<int>) return v;
    if (v is Iterable) return v.map((e) => e as int).toSet();
    if (v is int) return {v};
    return <int>{};
  }

  static bool _setsEqual(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
