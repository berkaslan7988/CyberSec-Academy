# Katkı Rehberi

Teşekkürler! Bu proje, siber güvenliği etik/savunma odaklı öğreten açık kaynak bir Flutter uygulamasıdır.

## Geliştirme ortamı
- Flutter (stable kanal) kurulu olmalı: `flutter doctor` temiz olmalı.
- Proje kökü: `cybersec_app/`.

```bash
cd cybersec_app
flutter create . --platforms=windows,web   # platform dosyaları yoksa
flutter pub get
flutter run -d windows                      # veya -d chrome
flutter test                                # testler
flutter analyze                             # statik analiz
dart format .                               # biçimlendirme
```

## İçerik ekleme
- **Yeni konu/bölüm:** `cybersec_app/assets/learn/` içine JSON ekle, `index.json`'a bir satır koy. Her konu `title` ve `content` için **TR + EN** içermeli.
- **Yeni quiz sorusu:** `cybersec_app/assets/quizzes/section_quizzes.json` içindeki ilgili bölüme ekle. Komut sorularında `evaluation` şemasını kullan.

## Kurallar
- **Etik:** Tüm içerik yasal lab / izinli test bağlamında olmalı. Zararlı tam-zincir saldırı talimatı eklenmez; kavram + savunma odağı korunur.
- Her saldırı konusu bir savunma/tespit karşılığıyla sunulur (`ethics: true` işaretle).
- Kod stili: `flutter analyze` ve `dart format` temiz geçmeli.
- PR açmadan önce `flutter test` çalıştır.

## PR akışı
1. Fork + dal aç (`feature/...`).
2. Değişiklik + test.
3. CI'nin (analyze + test) yeşil olduğundan emin ol.
4. Açıklayıcı bir PR aç.
