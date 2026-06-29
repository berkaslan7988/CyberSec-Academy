import 'package:flutter/material.dart';

import '../../progress/progress_store.dart';
import '../models/learn_models.dart';
import 'topic_detail_screen.dart';

/// Full-text search across sections, topics and tags. Tapping a result opens
/// the topic. Matches both TR and EN text so search works regardless of UI lang.
class TopicSearchDelegate extends SearchDelegate<void> {
  final List<Section> sections;
  final String lang;
  final ProgressStore progress;

  late final List<_Hit> _index = _buildIndex();

  TopicSearchDelegate({
    required this.sections,
    required this.lang,
    required this.progress,
  });

  bool get _tr => lang == 'tr';

  List<_Hit> _buildIndex() {
    final out = <_Hit>[];
    for (final s in sections) {
      for (final t in s.topics) {
        final haystack = [
          t.title.tr,
          t.title.en,
          s.title.tr,
          s.title.en,
          t.tags.join(' '),
        ].join(' ').toLowerCase();
        out.add(_Hit(section: s, topic: t, haystack: haystack));
      }
    }
    return out;
  }

  List<_Hit> _matches(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _index.where((h) => h.haystack.contains(query)).toList();
  }

  @override
  String get searchFieldLabel => _tr ? 'Konu veya araç ara…' : 'Search topic or tool…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _resultsList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _resultsList(context);

  Widget _resultsList(BuildContext context) {
    final hits = _matches(query);
    if (query.trim().isEmpty) {
      return Center(
        child: Text(_tr ? 'Aramaya başla…' : 'Start typing…',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    if (hits.isEmpty) {
      return Center(
        child: Text(_tr ? 'Sonuç bulunamadı' : 'No results',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      itemCount: hits.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final h = hits[i];
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(h.topic.title.resolve(lang)),
          subtitle: Text(h.section.title.resolve(lang)),
          trailing:
              h.topic.ethics ? const Icon(Icons.warning_amber, size: 18) : null,
          onTap: () {
            close(context, null);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TopicDetailScreen(
                topic: h.topic,
                lang: lang,
                sectionId: h.section.id,
                sectionTitle: h.section.title.resolve(lang),
                progress: progress,
              ),
            ));
          },
        );
      },
    );
  }
}

class _Hit {
  final Section section;
  final Topic topic;
  final String haystack;
  const _Hit({required this.section, required this.topic, required this.haystack});
}
