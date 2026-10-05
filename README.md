# رحلتي — Rehlati

Flutter (Android + iOS, phones and tablets) port of the رحلتي التعليمية web app: an Egyptian-Arabic learning app for kids aged 4–6, with four worlds (Quran, Math, Arabic, English).

- Port plan and status: [docs/PLAN.md](docs/PLAN.md)
- Building and publishing: [docs/RELEASE.md](docs/RELEASE.md)
- Privacy policy: [docs/PRIVACY.md](docs/PRIVACY.md)
- Original web app: github.com/MahmoudRabea93/rehlati, by Mahmoud Rabea Hassan

## Run

```bash
flutter pub get
flutter run
flutter test                                   # unit, widget and screen smoke tests
flutter test --tags network --run-skipped      # live check of both Quran text sources
flutter run --dart-define=START=/quran/112     # open directly on any route
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
