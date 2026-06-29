import 'package:flutter/material.dart';

import '../../learn/models/learn_models.dart';
import '../../learn/ui/section_icons.dart';
import '../../progress/progress_store.dart';
import '../../review/review_runner_page.dart';
import '../../review/review_scheduler.dart';
import '../../review/review_session.dart';
import '../models/quiz.dart';
import 'quiz_runner_page.dart';

/// The Test tab: a spaced-repetition review entry at the top, then one entry
/// per section that has a quiz, with the best score.
class SectionQuizListScreen extends StatelessWidget {
  final List<Section> sections;
  final Map<String, Quiz> quizzes;
  final String lang;
  final ProgressStore progress;
  final ReviewScheduler review;

  const SectionQuizListScreen({
    super.key,
    required this.sections,
    required this.quizzes,
    required this.lang,
    required this.progress,
    required this.review,
  });

  bool get _tr => lang == 'tr';

  @override
  Widget build(BuildContext context) {
    final entries = sections.where((s) => quizzes.containsKey(s.id)).toList();
    return ListenableBuilder(
      listenable: Listenable.merge([progress, review]),
      builder: (context, _) {
        final due = review.dueCount();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _ReviewCard(
              due: due,
              tracked: review.trackedCount,
              lang: lang,
              onStart: due == 0
                  ? null
                  : () {
                      final qs = ReviewSession.buildDueQuestions(quizzes, review);
                      if (qs.isEmpty) return;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ReviewRunnerPage(
                          questions: qs,
                          lang: lang,
                          scheduler: review,
                        ),
                      ));
                    },
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Text(_tr ? 'Bölüm Quizleri' : 'Section Quizzes',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final s in entries) _sectionTile(context, s),
          ],
        );
      },
    );
  }

  Widget _sectionTile(BuildContext context, Section s) {
    final quiz = quizzes[s.id]!;
    final color = levelColor(context, s.level);
    final best = progress.bestScore(s.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(sectionIcon(s.icon), color: color),
        ),
        title: Text(s.title.resolve(lang),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${quiz.questions.length} ${_tr ? 'soru' : 'questions'}'),
        trailing: best == null
            ? const Icon(Icons.play_circle_outline)
            : _ScoreBadge(percent: best),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuizRunnerPage(
              quiz: quiz,
              sectionId: s.id,
              lang: lang,
              progress: progress,
              review: review,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int due;
  final int tracked;
  final String lang;
  final VoidCallback? onStart;
  const _ReviewCard(
      {required this.due,
      required this.tracked,
      required this.lang,
      this.onStart});

  bool get _tr => lang == 'tr';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final enabled = onStart != null;
    return Card(
      color: enabled ? c.primaryContainer : null,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.refresh,
                  size: 36,
                  color: enabled ? c.onPrimaryContainer : Colors.grey),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tr ? 'Bugün Tekrar Et' : 'Today\'s Review',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? (_tr
                              ? '$due soru tekrara hazır (aralıklı tekrar)'
                              : '$due questions due (spaced repetition)')
                          : (tracked == 0
                              ? (_tr
                                  ? 'Bir bölüm quizi çöz; yanlışların burada tekrara gelir.'
                                  : 'Take a section quiz; your misses return here.')
                              : (_tr
                                  ? 'Şu an vadesi gelen tekrar yok. Sonra tekrar bak.'
                                  : 'Nothing due right now. Check back later.')),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (enabled)
                CircleAvatar(
                  backgroundColor: c.onPrimaryContainer,
                  child: Text('$due',
                      style: TextStyle(
                          color: c.primaryContainer,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int percent;
  const _ScoreBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? Colors.green
        : (percent >= 50 ? Colors.orange : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text('$percent%',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
