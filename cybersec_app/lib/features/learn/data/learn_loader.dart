import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/learn_models.dart';

/// Loads the learn index and section content from assets/learn/.
class LearnLoader {
  static const _base = 'assets/learn/';

  /// Reads index.json -> list of section files, then loads each section.
  static Future<List<Section>> loadAll() async {
    final indexRaw = await rootBundle.loadString('${_base}index.json');
    final index = jsonDecode(indexRaw) as Map<String, dynamic>;
    final refs = ((index['sections'] ?? []) as List)
        .map((e) => SectionRef.fromJson(e as Map<String, dynamic>))
        .toList();

    final sections = <Section>[];
    for (final ref in refs) {
      try {
        final raw = await rootBundle.loadString('$_base${ref.file}');
        sections.add(Section.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip a malformed/missing section rather than crashing the app.
      }
    }
    return sections;
  }
}
