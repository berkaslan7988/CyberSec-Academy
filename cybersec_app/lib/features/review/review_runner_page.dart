import 'package:flutter/material.dart';

import '../quiz_engine/models/question.dart';
import '../quiz_engine/models/quiz.dart';
import '../quiz_engine/state/quiz_controller.dart';
import '../quiz_engine/ui/quiz_screen.dart';
import 'review_scheduler.dart';

/// Runs a spaced-repetition review session over the given due [questions]
/// (whose ids are already composite "sectionId/questionId" keys). Each answer
/// re-schedules the card in [scheduler].
class ReviewRunnerPage extends StatefulWidget {
  final List<Question> questions;
  final String lang;
  final ReviewScheduler scheduler;

  const ReviewRunnerPage({
    super.key,
    required this.questions,
    required this.lang,
    required this.scheduler,
  });

  @override
  State<ReviewRunnerPage> createState() => _ReviewRunnerPageState();
}

class _ReviewRunnerPageState extends State<ReviewRunnerPage> {
  late final QuizController _controller;

  @override
  void initState() {
    super.initState();
    final quiz = Quiz(
      id: 'review',
      title: LocalizedText(
          tr: 'Bugün Tekrar Et', en: 'Today\'s Review'),
      questions: widget.questions,
    );
    _controller = QuizController(
      quiz,
      // qid is already the composite key.
      onAnswered: (qid, correct) => widget.scheduler.record(qid, correct),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuizScreen(
      controller: _controller,
      lang: widget.lang,
      onToggleLang: () {},
    );
  }
}
