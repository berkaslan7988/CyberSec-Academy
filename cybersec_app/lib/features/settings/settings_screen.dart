import 'package:flutter/material.dart';

import '../progress/progress_store.dart';
import '../review/review_scheduler.dart';

/// App settings: language, theme mode, reset progress, and an about/ethics
/// section. Language/theme changes are applied via callbacks to the app root.
class SettingsScreen extends StatelessWidget {
  final String lang;
  final ThemeMode themeMode;
  final ValueChanged<String> onSetLang;
  final ValueChanged<ThemeMode> onSetThemeMode;
  final ProgressStore progress;
  final ReviewScheduler review;

  const SettingsScreen({
    super.key,
    required this.lang,
    required this.themeMode,
    required this.onSetLang,
    required this.onSetThemeMode,
    required this.progress,
    required this.review,
  });

  bool get _tr => lang == 'tr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tr ? 'Ayarlar' : 'Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(context, _tr ? 'Dil' : 'Language'),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'tr',
                  groupValue: lang,
                  onChanged: (v) => onSetLang(v!),
                  title: const Text('Türkçe'),
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: lang,
                  onChanged: (v) => onSetLang(v!),
                  title: const Text('English'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(context, _tr ? 'Tema' : 'Theme'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (v) => onSetThemeMode(v!),
                  title: Text(_tr ? 'Sistem' : 'System'),
                  secondary: const Icon(Icons.brightness_auto),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (v) => onSetThemeMode(v!),
                  title: Text(_tr ? 'Açık' : 'Light'),
                  secondary: const Icon(Icons.light_mode),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (v) => onSetThemeMode(v!),
                  title: Text(_tr ? 'Koyu' : 'Dark'),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(context, _tr ? 'Veri' : 'Data'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(_tr ? 'İlerlemeyi sıfırla' : 'Reset progress'),
              subtitle: Text(_tr
                  ? 'Okunan konular, skorlar ve tekrar takvimi silinir.'
                  : 'Clears read topics, scores and the review schedule.'),
              onTap: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(context, _tr ? 'Hakkında' : 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CyberSec Akademi',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_tr ? 'Sürüm 0.1.0 · MIT Lisansı' : 'Version 0.1.0 · MIT License',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Text(
                    _tr
                        ? 'Etik & yasal: Bu bir öğrenme aracıdır. Tüm araç ve teknikler yalnızca kendi sistemlerinde, izole lab ortamında veya yazılı izinli testte kullanılmalıdır. Yetkisiz erişim suçtur.'
                        : 'Ethics & legal: This is a learning tool. All tools and techniques must be used only on your own systems, an isolated lab, or an authorized test. Unauthorized access is a crime.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr ? 'İlerlemeyi sıfırla?' : 'Reset progress?'),
        content: Text(_tr
            ? 'Tüm ilerleme ve tekrar verisi kalıcı olarak silinecek. Bu geri alınamaz.'
            : 'All progress and review data will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr ? 'Vazgeç' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr ? 'Sıfırla' : 'Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await progress.reset();
      await review.reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tr ? 'İlerleme sıfırlandı.' : 'Progress reset.'),
        ));
      }
    }
  }
}
