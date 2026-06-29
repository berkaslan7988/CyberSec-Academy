import 'package:flutter/material.dart';

import '../../progress/progress_store.dart';
import '../../quiz_engine/models/quiz.dart';
import '../../quiz_engine/ui/quiz_runner_page.dart';
import '../../review/review_scheduler.dart';
import '../models/learn_models.dart';
import 'section_icons.dart';
import 'topic_detail_screen.dart';

/// Lists every topic (konu başlığı) inside the selected section, with a
/// "test this section" button when a quiz exists.
class TopicsScreen extends StatelessWidget {
  final Section section;
  final String lang;
  final ProgressStore progress;
  final ReviewScheduler review;
  final Quiz? sectionQuiz;

  const TopicsScreen({
    super.key,
    required this.section,
    required this.lang,
    required this.progress,
    required this.review,
    this.sectionQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final color = levelColor(context, section.level);
    return Scaffold(
      appBar: AppBar(title: Text(section.title.resolve(lang))),
      floatingActionButton: sectionQuiz == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizRunnerPage(
                    quiz: sectionQuiz!,
                    sectionId: section.id,
                    lang: lang,
                    progress: progress,
                    review: review,
                  ),
                ),
              ),
              icon: const Icon(Icons.quiz),
              label: Text(lang == 'tr' ? 'Bölümü Test Et' : 'Test This Section'),
            ),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: section.topics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final t = section.topics[i];
            final read = progress.isRead(section.id, t.id);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: read
                      ? Icon(Icons.check, color: color)
                      : Text('${i + 1}', style: TextStyle(color: color)),
                ),
                title: Text(t.title.resolve(lang)),
                subtitle: read
                    ? Text(lang == 'tr' ? 'Okundu' : 'Read',
                        style: Theme.of(context).textTheme.labelSmall)
                    : null,
                trailing: t.ethics
                    ? Tooltip(
                        message: lang == 'tr'
                            ? 'Etik/yasal: yalnızca izinli lab'
                            : 'Ethics/legal: authorized lab only',
                        child: const Icon(Icons.warning_amber, size: 18),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TopicDetailScreen(
                      topic: t,
                      lang: lang,
                      sectionId: section.id,
                      sectionTitle: section.title.resolve(lang),
                      progress: progress,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
