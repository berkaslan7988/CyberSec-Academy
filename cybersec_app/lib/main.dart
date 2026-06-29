import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'core/l10n/app_strings.dart';
import 'features/learn/data/learn_loader.dart';
import 'features/learn/models/learn_models.dart';
import 'features/learn/ui/sections_screen.dart';
import 'features/learn/ui/topic_search_delegate.dart';
import 'features/progress/dashboard_screen.dart';
import 'features/progress/progress_store.dart';
import 'features/quiz_engine/data/quiz_loader.dart';
import 'features/quiz_engine/models/quiz.dart';
import 'features/quiz_engine/ui/section_quiz_list_screen.dart';
import 'features/review/review_scheduler.dart';
import 'features/settings/settings_screen.dart';

void main() => runApp(const CyberSecApp());

class CyberSecApp extends StatefulWidget {
  const CyberSecApp({super.key});

  @override
  State<CyberSecApp> createState() => _CyberSecAppState();
}

class _CyberSecAppState extends State<CyberSecApp> {
  String _lang = 'tr';
  ThemeMode _themeMode = ThemeMode.system;

  final ProgressStore _progress = ProgressStore();
  final ReviewScheduler _review = ReviewScheduler();
  List<Section>? _sections;
  Map<String, Quiz>? _quizzes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _progress.load();
    await _review.load();
    final sections = await LearnLoader.loadAll();
    final quizzes = await QuizLoader.loadSectionQuizzes();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _quizzes = quizzes;
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    _review.dispose();
    super.dispose();
  }

  void _toggleLang() => setState(() => _lang = _lang == 'tr' ? 'en' : 'tr');
  void _setLang(String l) => setState(() => _lang = l);
  void _setThemeMode(ThemeMode m) => setState(() => _themeMode = m);

  @override
  Widget build(BuildContext context) {
    final loading = _sections == null || _quizzes == null;
    return MaterialApp(
      title: AppStrings(_lang).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeShell(
              sections: _sections!,
              quizzes: _quizzes!,
              progress: _progress,
              review: _review,
              lang: _lang,
              themeMode: _themeMode,
              onToggleLang: _toggleLang,
              onSetLang: _setLang,
              onSetThemeMode: _setThemeMode,
            ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final List<Section> sections;
  final Map<String, Quiz> quizzes;
  final ProgressStore progress;
  final ReviewScheduler review;
  final String lang;
  final ThemeMode themeMode;
  final VoidCallback onToggleLang;
  final ValueChanged<String> onSetLang;
  final ValueChanged<ThemeMode> onSetThemeMode;

  const HomeShell({
    super.key,
    required this.sections,
    required this.quizzes,
    required this.progress,
    required this.review,
    required this.lang,
    required this.themeMode,
    required this.onToggleLang,
    required this.onSetLang,
    required this.onSetThemeMode,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _openSearch() {
    showSearch(
      context: context,
      delegate: TopicSearchDelegate(
        sections: widget.sections,
        lang: widget.lang,
        progress: widget.progress,
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        lang: widget.lang,
        themeMode: widget.themeMode,
        onSetLang: widget.onSetLang,
        onSetThemeMode: widget.onSetThemeMode,
        progress: widget.progress,
        review: widget.review,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final Widget content = switch (_tab) {
      0 => SectionsScreen(
          sections: widget.sections,
          quizzes: widget.quizzes,
          lang: lang,
          progress: widget.progress,
          review: widget.review,
        ),
      1 => SectionQuizListScreen(
          sections: widget.sections,
          quizzes: widget.quizzes,
          lang: lang,
          progress: widget.progress,
          review: widget.review,
        ),
      _ => DashboardScreen(
          sections: widget.sections,
          quizzes: widget.quizzes,
          lang: lang,
          progress: widget.progress,
          review: widget.review,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_tab) {
          0 => lang == 'tr' ? 'Öğren' : 'Learn',
          1 => lang == 'tr' ? 'Test' : 'Quiz',
          _ => lang == 'tr' ? 'Panel' : 'Dashboard',
        }),
        actions: [
          IconButton(
            tooltip: lang == 'tr' ? 'Ara' : 'Search',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          TextButton(
            onPressed: widget.onToggleLang,
            child: Text(lang.toUpperCase(),
                style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontWeight: FontWeight.bold)),
          ),
          IconButton(
            tooltip: lang == 'tr' ? 'Ayarlar' : 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        // Responsive: keep content readable width on large screens.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: content,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.menu_book),
              label: lang == 'tr' ? 'Öğren' : 'Learn'),
          NavigationDestination(
              icon: const Icon(Icons.quiz),
              label: lang == 'tr' ? 'Test' : 'Quiz'),
          NavigationDestination(
              icon: const Icon(Icons.insights),
              label: lang == 'tr' ? 'Panel' : 'Stats'),
        ],
      ),
    );
  }
}
