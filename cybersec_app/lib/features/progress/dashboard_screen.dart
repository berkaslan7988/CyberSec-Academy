import 'package:flutter/material.dart';
import '../learn/models/learn_models.dart';
import '../learn/ui/topics_screen.dart';
import '../quiz_engine/models/quiz.dart';
import '../review/review_scheduler.dart';
import 'progress_store.dart';

/// Phase 4 — statistics & achievements dashboard.
/// Shows overall progress, stat cards, badges and weak-area suggestions.
class DashboardScreen extends StatelessWidget {
  final List<Section> sections;
  final Map<String, Quiz> quizzes;
  final String lang;
  final ProgressStore progress;
  final ReviewScheduler review;

  const DashboardScreen({
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
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final stats = _compute();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OverallRing(percent: stats.readPercent, lang: lang),
            const SizedBox(height: 20),
            _statCards(context, stats),
            const SizedBox(height: 24),
            Text(_tr ? 'Başarımlar' : 'Achievements',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _achievements(context, stats),
            const SizedBox(height: 24),
            Text(_tr ? 'Önerilen Sonraki Adımlar' : 'Suggested Next Steps',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._suggestions(context, stats),
          ],
        );
      },
    );
  }

  // ---- computation ----
  _Stats _compute() {
    var totalTopics = 0;
    var readTopics = 0;
    var sectionsStarted = 0;
    var quizzesTaken = 0;
    var bestSum = 0;
    var bestCount = 0;
    var perfectCount = 0;

    for (final s in sections) {
      final ids = s.topics.map((t) => t.id);
      final read = progress.readCount(s.id, ids);
      totalTopics += s.topics.length;
      readTopics += read;
      if (read > 0) sectionsStarted++;
      final best = progress.bestScore(s.id);
      if (best != null) {
        bestSum += best;
        bestCount++;
        if (best == 100) perfectCount++;
      }
      quizzesTaken += progress.attempts(s.id);
    }

    return _Stats(
      totalTopics: totalTopics,
      readTopics: readTopics,
      sectionsStarted: sectionsStarted,
      totalSections: sections.length,
      quizzesTaken: quizzesTaken,
      avgScore: bestCount == 0 ? 0 : (bestSum / bestCount).round(),
      sectionsScored: bestCount,
      perfectCount: perfectCount,
      readPercent:
          totalTopics == 0 ? 0 : ((readTopics / totalTopics) * 100).round(),
    );
  }

  // ---- stat cards ----
  Widget _statCards(BuildContext context, _Stats s) {
    final cards = [
      _StatCard(
          icon: Icons.menu_book,
          value: '${s.readTopics}/${s.totalTopics}',
          label: _tr ? 'Okunan konu' : 'Topics read'),
      _StatCard(
          icon: Icons.category,
          value: '${s.sectionsStarted}/${s.totalSections}',
          label: _tr ? 'Başlanan bölüm' : 'Sections started'),
      _StatCard(
          icon: Icons.quiz,
          value: '${s.quizzesTaken}',
          label: _tr ? 'Çözülen quiz' : 'Quizzes taken'),
      _StatCard(
          icon: Icons.military_tech,
          value: s.sectionsScored == 0 ? '—' : '${s.avgScore}%',
          label: _tr ? 'Ort. en iyi skor' : 'Avg best score'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: cards,
    );
  }

  // ---- achievements ----
  Widget _achievements(BuildContext context, _Stats s) {
    final list = <_Badge>[
      _Badge(Icons.flag, _tr ? 'İlk Adım' : 'First Step',
          _tr ? 'İlk konuyu oku' : 'Read your first topic', s.readTopics >= 1),
      _Badge(Icons.explore, _tr ? 'Kaşif' : 'Explorer',
          _tr ? '5 bölüme başla' : 'Start 5 sections', s.sectionsStarted >= 5),
      _Badge(Icons.quiz, _tr ? 'Sınav Zamanı' : 'Quiz Time',
          _tr ? 'İlk quizi çöz' : 'Take your first quiz', s.quizzesTaken >= 1),
      _Badge(Icons.workspace_premium, _tr ? 'Kusursuz' : 'Flawless',
          _tr ? 'Bir quizde %100' : 'Score 100% on a quiz', s.perfectCount >= 1),
      _Badge(Icons.timeline, _tr ? 'Yarı Yol' : 'Halfway',
          _tr ? 'Konuların %50\'si' : '50% of topics', s.readPercent >= 50),
      _Badge(Icons.school, _tr ? 'Bilgin' : 'Scholar',
          _tr ? 'Tüm konuları oku' : 'Read every topic',
          s.totalTopics > 0 && s.readTopics >= s.totalTopics),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [for (final b in list) _BadgeTile(badge: b)],
    );
  }

  // ---- suggestions ----
  List<Widget> _suggestions(BuildContext context, _Stats s) {
    final items = <Widget>[];

    // 1) Sections scored but below 70% → review + retest.
    for (final sec in sections) {
      final best = progress.bestScore(sec.id);
      if (best != null && best < 70) {
        items.add(_suggestionTile(
          context, sec,
          _tr ? 'Quiz skoru düşük (%$best) — tekrar gözden geçir'
              : 'Low quiz score ($best%) — review again',
          Icons.trending_down,
          Colors.orange,
        ));
      }
    }

    // 2) Not-started sections → start learning.
    for (final sec in sections) {
      final read = progress.readCount(sec.id, sec.topics.map((t) => t.id));
      if (read == 0) {
        items.add(_suggestionTile(
          context, sec,
          _tr ? 'Henüz başlamadın — keşfet' : 'Not started yet — explore',
          Icons.play_circle_outline,
          Theme.of(context).colorScheme.primary,
        ));
      }
    }

    // 3) Read but quiz not taken → test yourself.
    for (final sec in sections) {
      final read = progress.readCount(sec.id, sec.topics.map((t) => t.id));
      if (read > 0 &&
          progress.bestScore(sec.id) == null &&
          quizzes.containsKey(sec.id)) {
        items.add(_suggestionTile(
          context, sec,
          _tr ? 'Okudun — şimdi kendini test et' : 'Read — now test yourself',
          Icons.quiz,
          Colors.lightBlueAccent,
        ));
      }
    }

    if (items.isEmpty) {
      return [
        Card(
          child: ListTile(
            leading: const Icon(Icons.celebration, color: Colors.green),
            title: Text(_tr
                ? 'Harika gidiyorsun! Şu an önerilen bir şey yok.'
                : 'You are doing great! Nothing to suggest right now.'),
          ),
        )
      ];
    }
    return items.take(5).toList();
  }

  Widget _suggestionTile(BuildContext context, Section sec, String msg,
      IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(sec.title.resolve(lang),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(msg),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TopicsScreen(
              section: sec,
              lang: lang,
              progress: progress,
              review: review,
              sectionQuiz: quizzes[sec.id],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats {
  final int totalTopics,
      readTopics,
      sectionsStarted,
      totalSections,
      quizzesTaken,
      avgScore,
      sectionsScored,
      perfectCount,
      readPercent;
  const _Stats({
    required this.totalTopics,
    required this.readTopics,
    required this.sectionsStarted,
    required this.totalSections,
    required this.quizzesTaken,
    required this.avgScore,
    required this.sectionsScored,
    required this.perfectCount,
    required this.readPercent,
  });
}

class _OverallRing extends StatelessWidget {
  final int percent;
  final String lang;
  const _OverallRing({required this.percent, required this.lang});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        label: lang == 'tr'
            ? 'Genel ilerleme yüzde $percent'
            : 'Overall progress $percent percent',
        child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 12,
                backgroundColor: c.primary.withOpacity(0.15),
                color: c.primary,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$percent%',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(lang == 'tr' ? 'tamamlandı' : 'complete',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge {
  final IconData icon;
  final String title;
  final String desc;
  final bool unlocked;
  const _Badge(this.icon, this.title, this.desc, this.unlocked);
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final color = badge.unlocked ? Colors.amber : Colors.grey;
    return Tooltip(
      message: badge.desc,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(badge.unlocked ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(badge.unlocked ? 0.6 : 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(badge.unlocked ? badge.icon : Icons.lock_outline,
                color: color, size: 28),
            const SizedBox(height: 6),
            Text(badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badge.unlocked ? null : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
