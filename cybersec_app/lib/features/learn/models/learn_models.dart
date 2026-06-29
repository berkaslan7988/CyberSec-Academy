// Learn (konu anlatımı) data models. Pure Dart, JSON-driven.
//
// Hierarchy: Section (cybersecurity bölümü) -> Topic (konu başlığı) -> markdown.

import '../../quiz_engine/models/question.dart' show LocalizedText;

export '../../quiz_engine/models/question.dart' show LocalizedText;

/// A topic (konu başlığı) under a section. Holds localized markdown content.
class Topic {
  final String id;
  final LocalizedText title;
  final LocalizedText content; // markdown (TR/EN)
  final List<String> tags;
  final bool ethics; // attack-related => show ethics badge

  const Topic({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.ethics = false,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        title: LocalizedText.fromAny(json['title']),
        content: LocalizedText.fromAny(json['content']),
        tags: ((json['tags'] ?? []) as List).map((e) => e.toString()).toList(),
        ethics: (json['ethics'] ?? false) as bool,
      );
}

/// A section (bölüm) = a selectable category containing topics.
class Section {
  final String id;
  final LocalizedText title;
  final LocalizedText subtitle;
  final String icon; // material icon key (see _iconMap in UI)
  final String level; // foundation | offensive | defensive | modern | process
  final List<Topic> topics;

  const Section({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.level,
    required this.topics,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json['id'] as String,
        title: LocalizedText.fromAny(json['title']),
        subtitle: LocalizedText.fromAny(json['subtitle']),
        icon: (json['icon'] ?? 'menu_book') as String,
        level: (json['level'] ?? 'foundation') as String,
        topics: ((json['topics'] ?? []) as List)
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Index entry: which section files exist and load order.
class SectionRef {
  final String id;
  final String file; // asset filename under assets/learn/
  const SectionRef({required this.id, required this.file});

  factory SectionRef.fromJson(Map<String, dynamic> json) =>
      SectionRef(id: json['id'] as String, file: json['file'] as String);
}
