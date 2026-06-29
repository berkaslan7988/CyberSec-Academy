import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../models/answer_result.dart';
import '../state/quiz_controller.dart';
import 'question_views.dart';

class QuizScreen extends StatelessWidget {
  final QuizController controller;
  final String lang;
  final VoidCallback onToggleLang;

  /// When embedded in HomeShell, the shell already provides an AppBar + lang
  /// toggle, so this screen omits its own AppBar to avoid a double header.
  final bool embedded;

  const QuizScreen({
    super.key,
    required this.controller,
    required this.lang,
    required this.onToggleLang,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(lang);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final q = controller.current;
        final res = controller.result;
        final finished = controller.answered && controller.isLast;

        return Scaffold(
          appBar: embedded
              ? null
              : AppBar(
                  title: Text(controller.quiz.title.resolve(lang)),
                  actions: [
                    TextButton.icon(
                      onPressed: onToggleLang,
                      icon: const Icon(Icons.translate, color: Colors.white),
                      label: Text(lang.toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
          body: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (controller.position + (controller.answered ? 1 : 0)) /
                      controller.total,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.questionOf} ${controller.position + 1}/${controller.total}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(q.prompt.resolve(lang),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        QuestionView(
                          question: q,
                          lang: lang,
                          locked: controller.answered,
                          onChanged: controller.setAnswer,
                        ),
                        if (res != null) ...[
                          const SizedBox(height: 16),
                          _FeedbackPanel(result: res, lang: lang, question: q),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomBar(
                  controller: controller,
                  lang: lang,
                  finished: finished,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final AnswerResult result;
  final String lang;
  final dynamic question;
  const _FeedbackPanel(
      {required this.result, required this.lang, required this.question});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(lang);
    final (color, icon, title) = switch (result.status) {
      AnswerStatus.correct => (Colors.green, Icons.check_circle, s.correct),
      AnswerStatus.partiallyCorrect => (Colors.orange, Icons.adjust, s.partial),
      AnswerStatus.incorrect => (Colors.red, Icons.cancel, s.incorrect),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
          if (result.status != AnswerStatus.correct &&
              result.correctAnswer != null) ...[
            const SizedBox(height: 8),
            Text(s.correctAnswerLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            SelectableText(result.correctAnswer!,
                style: const TextStyle(fontFamily: 'monospace')),
          ],
          if (result.missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final m in result.missing)
              Text('• ${s.missingHint(m)}',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Text(s.explanationLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(question.explanation.resolve(lang)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final QuizController controller;
  final String lang;
  final bool finished;
  const _BottomBar(
      {required this.controller, required this.lang, required this.finished});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(lang);

    if (finished) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${s.quizComplete}  ${s.yourScore}: ${controller.scorePercent}%',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.hasWrong)
                  OutlinedButton.icon(
                    onPressed: controller.retryWrong,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.retryWrong),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: controller.restart,
                  icon: const Icon(Icons.replay),
                  label: Text(s.restart),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: controller.answered
            ? FilledButton(
                onPressed: controller.next,
                child: Text(s.next),
              )
            : FilledButton(
                onPressed: controller.canCheck ? controller.check : null,
                child: Text(s.check),
              ),
      ),
    );
  }
}
