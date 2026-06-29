// Lightweight UI string localization (TR/EN) for the demo.
// In the full app these move to ARB files (flutter_localizations + intl).

class AppStrings {
  final String lang; // 'tr' | 'en'
  const AppStrings(this.lang);

  bool get isTr => lang == 'tr';

  String get appTitle => isTr ? 'CyberSec Akademi' : 'CyberSec Academy';
  String get check => isTr ? 'Kontrol Et' : 'Check';
  String get next => isTr ? 'Sonraki' : 'Next';
  String get finish => isTr ? 'Bitir' : 'Finish';
  String get correct => isTr ? 'Doğru!' : 'Correct!';
  String get partial => isTr ? 'Neredeyse! Kısmen doğru.' : 'Almost! Partially correct.';
  String get incorrect => isTr ? 'Yanlış.' : 'Incorrect.';
  String get correctAnswerLabel => isTr ? 'Doğru cevap:' : 'Correct answer:';
  String get explanationLabel => isTr ? 'Açıklama:' : 'Explanation:';
  String get typeCommandHint =>
      isTr ? 'Komutu buraya yaz…' : 'Type the command here…';
  String get fillHint => isTr ? 'Cevabını yaz…' : 'Type your answer…';
  String get yourScore => isTr ? 'Skorun' : 'Your score';
  String get quizComplete => isTr ? 'Quiz tamamlandı!' : 'Quiz complete!';
  String get restart => isTr ? 'Baştan Başla' : 'Restart';
  String get retryWrong =>
      isTr ? 'Yanlışları Tekrar Et' : 'Retry Wrong Ones';
  String get questionOf => isTr ? 'Soru' : 'Question';
  String get selectLanguage => isTr ? 'Dil' : 'Language';
  String get tapToOrderHint =>
      isTr ? 'Sürükleyerek doğru sıraya koy' : 'Drag to the correct order';
  String get matchHint =>
      isTr ? 'Her satır için doğru karşılığı seç' : 'Pick the right match per row';

  String missingHint(String key) {
    final parts = key.split(':');
    final kind = parts.first;
    final val = parts.length > 1 ? parts.sublist(1).join(':') : '';
    switch (kind) {
      case 'token':
        return isTr ? 'Araç adı eksik/yanlış: $val' : 'Missing/wrong tool: $val';
      case 'flag':
        return isTr ? 'Bayrak eksik: $val' : 'Missing flag: $val';
      case 'target':
        return isTr ? 'Hedef eksik: $val' : 'Missing target: $val';
      case 'forbidden':
        return isTr ? 'İzin verilmeyen ifade: $val' : 'Not allowed: $val';
      case 'empty':
        return isTr ? 'Boş cevap' : 'Empty answer';
      default:
        return val;
    }
  }
}
