import 'package:flutter/material.dart';

import '../../../shared/markdown_view.dart';
import '../../progress/progress_store.dart';
import '../models/learn_models.dart';

/// Renders a single topic's localized markdown content and marks it as read.
class TopicDetailScreen extends StatefulWidget {
  final Topic topic;
  final String lang;
  final String sectionId;
  final String sectionTitle;
  final ProgressStore progress;

  const TopicDetailScreen({
    super.key,
    required this.topic,
    required this.lang,
    required this.sectionId,
    required this.sectionTitle,
    required this.progress,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Opening a topic marks it as read.
    widget.progress.markRead(widget.sectionId, widget.topic.id);
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final lang = widget.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title.resolve(lang)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Text(widget.sectionTitle,
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.ethics)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  border: Border.all(color: Colors.amber.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang == 'tr'
                            ? 'Etik & yasal: Bu teknikler yalnızca kendi sistemlerinde veya yazılı izinli lab ortamında denenir.'
                            : 'Ethics & legal: Practice these techniques only on your own systems or an authorized lab.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            MarkdownView(topic.content.resolve(lang)),
            if (topic.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                children: [
                  for (final tag in topic.tags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
