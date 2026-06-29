import 'package:flutter/material.dart';

/// Maps a string icon key (from JSON) to a Material icon.
IconData sectionIcon(String key) {
  switch (key) {
    case 'lan':
      return Icons.lan;
    case 'terminal':
      return Icons.terminal;
    case 'travel_explore':
      return Icons.travel_explore;
    case 'radar':
      return Icons.radar;
    case 'public':
      return Icons.public;
    case 'smart_toy':
      return Icons.smart_toy;
    case 'shield':
      return Icons.shield;
    case 'bug_report':
      return Icons.bug_report;
    case 'cloud':
      return Icons.cloud;
    case 'memory':
      return Icons.memory;
    case 'code':
      return Icons.code;
    case 'bolt':
      return Icons.bolt;
    case 'vpn_key':
      return Icons.vpn_key;
    case 'hub':
      return Icons.hub;
    case 'find_in_page':
      return Icons.find_in_page;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'build':
      return Icons.build;
    case 'lock':
      return Icons.lock;
    case 'description':
      return Icons.description;
    case 'school':
      return Icons.school;
    default:
      return Icons.menu_book;
  }
}

/// A subtle color per section level, for visual grouping.
Color levelColor(BuildContext context, String level) {
  final c = Theme.of(context).colorScheme;
  switch (level) {
    case 'offensive':
      return Colors.redAccent;
    case 'defensive':
      return Colors.lightBlueAccent;
    case 'modern':
      return Colors.purpleAccent;
    case 'process':
      return Colors.amberAccent;
    default:
      return c.primary; // foundation
  }
}
