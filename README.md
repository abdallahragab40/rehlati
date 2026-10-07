# رحلتي — Rehlati

Flutter (Android + iOS, phones and tablets) port of the رحلتي التعليمية web app: an Egyptian-Arabic learning app for kids aged 4–6, with five worlds (Quran, Math, Arabic, English, Games).

- Original web app: github.com/MahmoudRabea93/rehlati, by Mahmoud Rabea Hassan

## Run

```bash
flutter pub get
flutter run
flutter test                                   # unit, widget and screen smoke tests
flutter test --tags network --run-skipped      # live check of both Quran text sources
flutter run --dart-define=START=/quran/112     # open directly on any route
node tool/sync_web_content.mjs ../rehlati-web  # regenerate madd + parent-guide content from the web repo
flutter test tool/voice_phrases_test.dart && python3 tool/render_voice.py  # re-record Arabic voice (pip install edge-tts)
```

## Layout

| Path | What |
|---|---|
| `lib/content/` | Static data ported verbatim (letters, words, levels, items) |
| `lib/domain/` | Pure logic: question model, generators, stage registry, progress, adaptive, badges, engine |
| `lib/core/` | Theme, Arabic number utilities, RNG, audio services, shared widgets |
| `lib/features/` | Screens |
| `assets/` | Fonts (Baloo Bhaijaan 2, Amiri Quran — OFL), SVG art, voice clips, SFX |
| `tool/` | Offline asset generators (voice clips, SFX) |

## Android release signing

Create `android/key.properties` (git-ignored) pointing at your upload keystore:

```properties
storeFile=/path/to/upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without it, release builds fall back to the debug key, which works for `flutter run --release` but is rejected by Google Play.
