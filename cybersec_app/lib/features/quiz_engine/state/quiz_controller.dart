import 'package:flutter/foundation.dart';

import '../logic/answer_evaluator.dart';
import '../models/answer_result.dart';
import '../models/question.dart';
import '../models/quiz.dart';

/// Drives a quiz session: current index, the pending answer, scoring,
/// per-question feedback, and the "retry wrong ones" queue (a tiny step toward
/// spaced repetition). Plain ChangeNotifier — no external state package needed.
class QuizController extends ChangeNotifier {
  final Quiz quiz;

  /// Optional: which learn section this quiz belongs to.
  final String? sectionId;

  /// Called once, when the final question of the run is answered, with the
  /// final score percent. Used to record progress.
  final void Function(int percent)? onComplete;

  /// Called after each question is checked, with the question id and whether it
  /// was fully correct. Used to feed the spaced-repetition scheduler.
  final void Function(String questionId, bool correct)? onAnswered;

  bool _completedFired = false;

  QuizController(this.quiz,
      {this.sectionId, this.onComplete, this.onAnswered}) {
    _order = List<int>.generate(quiz.questions.length, (i) => i);
  }

  late List<int> _order; // indices into quiz.questions, current run order
  int _pos = 0;

  Object? _pendingAnswer; // current widget's answer payload
  AnswerResult? _result; // set after Check is pressed
  bool _answered = false;

  double _scoreSum = 0; // sum of fractional scores
  int _graded = 0;
  final Set<String> _wrongIds = {};

  // ---- getters ----
  Question get current => quiz.questions[_order[_pos]];
  int get position => _pos;
  int get total => _order.length;
  bool get answered => _answered;
  AnswerResult? get result => _result;
  bool get isLast => _pos >= _order.length - 1;
  bool get hasWrong => _wrongIds.isNotEmpty;

  /// 0..100 percentage based on fractional scores (partial credit counts).
  int get scorePercent =>
      _graded == 0 ? 0 : ((_scoreSum / _graded) * 100).round();

  // ---- actions ----
  void setAnswer(Object? answer) {
    _pendingAnswer = answer;
    notifyListeners();
  }

  bool get canCheck => !_answered && _hasUsableAnswer();

  bool _hasUsableAnswer() {
    final a = _pendingAnswer;
    if (a == null) return false;
    if (a is String) return a.trim().isNotEmpty;
    if (a is Iterable) return a.isNotEmpty;
    if (a is Map) return a.isNotEmpty;
    return true;
  }

  void check() {
    if (_answered) return;
    final res = AnswerEvaluator.evaluate(current, _pendingAnswer);
    _result = res;
    _answered = true;
    _scoreSum += res.score;
    _graded += 1;
    if (res.status != AnswerStatus.correct) {
      _wrongIds.add(current.id);
    } else {
      _wrongIds.remove(current.id);
    }
    // Feed the spaced-repetition scheduler.
    onAnswered?.call(current.id, res.status == AnswerStatus.correct);
    // Fire completion callback once when the last question is answered.
    if (isLast && !_completedFired) {
      _completedFired = true;
      onComplete?.call(scorePercent);
    }
    notifyListeners();
  }

  void next() {
    if (_pos < _order.length - 1) {
      _pos += 1;
      _resetQuestionState();
      notifyListeners();
    }
  }

  void restart() {
    _order = List<int>.generate(quiz.questions.length, (i) => i);
    _pos = 0;
    _scoreSum = 0;
    _graded = 0;
    _completedFired = false;
    _wrongIds.clear();
    _resetQuestionState();
    notifyListeners();
  }

  /// Re-run only the questions answered incorrectly.
  void retryWrong() {
    final wrong = quiz.questions
        .asMap()
        .entries
        .where((e) => _wrongIds.contains(e.value.id))
        .map((e) => e.key)
        .toList();
    if (wrong.isEmpty) return;
    _order = wrong;
    _pos = 0;
    _scoreSum = 0;
    _graded = 0;
    _completedFired = false;
    _wrongIds.clear();
    _resetQuestionState();
    notifyListeners();
  }

  void _resetQuestionState() {
    _pendingAnswer = null;
    _result = null;
    _answered = false;
  }
}
