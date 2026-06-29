import 'package:flutter/material.dart';

import '../../progress/progress_store.dart';
import '../../quiz_engine/models/quiz.dart';
import '../../review/review_scheduler.dart';
import '../models/learn_models.dart';
import 'section_icons.dart';
import 'topics_screen.dart';

/// Lists every cybersecurity section as a selectable option, with progress.
class SectionsScreen extends StatelessWidget {
  final List<Section> sections;
  final Map<String, Quiz> quizzes;
  final String lang;
  final ProgressStore progress;
  final ReviewScheduler review;

  const SectionsScreen({
    super.key,
    required this.sections,
    required this.quizzes,
    required this.lang,
    required this.progress,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sections.length,
        itemBuilder: (context, i) {
          final s = sections[i];
          final color = levelColor(context, s.level);
          final topicIds = s.topics.map((t) => t.id);
          final read = progress.readCount(s.id, topicIds);
          final total = s.topics.length;
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.subtitle.resolve(lang)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : read / total,
                            minHeight: 6,
                            backgroundColor: color.withOpacity(0.15),
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$read/$total',
                          style: Theme.of(context).textTheme.labelSmall),
                      if (best != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.quiz, size: 13, color: color),
                        Text(' $best%',
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TopicsScreen(
                    section: s,
                    lang: lang,
                    progress: progress,
                    review: review,
                    sectionQuiz: quizzes[s.id],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
