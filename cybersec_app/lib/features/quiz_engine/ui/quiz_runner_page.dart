import 'package:flutter/material.dart';

import '../../progress/progress_store.dart';
import '../../review/review_scheduler.dart';
import '../models/quiz.dart';
import '../state/quiz_controller.dart';
import 'quiz_screen.dart';

/// Owns a QuizController for a single section quiz run, records the result into
/// [progress] on completion, feeds each answer into the [review] scheduler, and
/// disposes the controller when popped.
class QuizRunnerPage extends StatefulWidget {
  final Quiz quiz;
  final String sectionId;
  final String lang;
  final ProgressStore progress;
  final ReviewScheduler? review;

  const QuizRunnerPage({
    super.key,
    required this.quiz,
    required this.sectionId,
    required this.lang,
    required this.progress,
    this.review,
  });

  @override
  State<QuizRunnerPage> createState() => _QuizRunnerPageState();
}

class _QuizRunnerPageState extends State<QuizRunnerPage> {
  late final QuizController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuizController(
      widget.quiz,
      sectionId: widget.sectionId,
      onComplete: (percent) =>
          widget.progress.recordQuiz(widget.sectionId, percent),
      onAnswered: (qid, correct) =>
          widget.review?.record('${widget.sectionId}/$qid', correct),
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
