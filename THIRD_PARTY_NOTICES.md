# Third-party notices — Rehlati

The app's own code and content are covered by [LICENSE](LICENSE). The components below keep their own licences and terms. The app shows the same credits to parents in the parent dashboard (المصادر والتراخيص), and its licence page lists the fonts and every bundled open-source package.

## Original web app

"رحلتي التعليمية" by Mahmoud Rabea Hassan (github.com/MahmoudRabea93/rehlati). Used and adapted with the author's permission.

## Fonts (bundled)

| Font | Licence | File |
|---|---|---|
| Baloo Bhaijaan 2 | SIL Open Font License 1.1 | `assets/fonts/OFL-BalooBhaijaan2.txt` |
| Amiri Quran | SIL Open Font License 1.1 | `assets/fonts/OFL-AmiriQuran.txt` |

Both licence texts ship inside the app and are registered on its licence page (`lib/main.dart`).

## Quran text (fetched at runtime, cached on the device)

- **Source:** [AlQuran Cloud](https://alquran.cloud) API, Uthmani text from the [Tanzil Project](https://tanzil.net).
- **Terms:**
  - AlQuran Cloud allows the text to be stored and shown, including in apps, provided the source is acknowledged and the diacritics and orthography are kept.
  - Tanzil (Creative Commons Attribution 3.0) allows use in any application provided Tanzil is clearly named as the source, its address (tanzil.net) is given, its copyright notice is included, and the text isn't changed.
  - The app has no links out (Kids Category), so tanzil.net appears as text in the parent dashboard, and the notice is on the app's licence page.
- **Changes:** none to the ayah text. AlQuran Cloud puts the basmala at the start of ayah 1 of each surah. The app removes it there, matching Quran.com and the standard ayah numbering (`stripBasmala` in `lib/features/quran/quran_repository.dart`).
- **Checked:** terms read on 15 Oct 2026 (alquran.cloud/terms-and-conditions, last updated 14 June 2026; tanzil.net/docs/text_license).

## Quran text verification (not stored)

- **Source:** [Quran.com](https://quran.com) API v4 (Quran Foundation).
- **Use:** only on the parent's "check the Quran text" screen, which compares it letter by letter with AlQuran Cloud. Nothing from it is cached.
- **Why it isn't stored:** the Quran Foundation developer terms forbid storing their content for more than a week except through their Content Sync APIs (api-docs.quran.foundation/legal/developer-terms, read 15 Oct 2026).

## Quran recitation (fetched at runtime, cached on the device)

- **Source:** [EveryAyah](https://everyayah.com). Reciters: Mahmoud Khalil Al-Husary, Abdul Basit Abdul Samad, Mohamed Siddiq Al-Minshawi, and the Minshawi and Husary teaching (muallim) recitations.
- **Terms:** EveryAyah publishes no terms of use. Copyright in recitations rests with the reciters or their estates. The app streams single ayahs and keeps them on the device for offline listening; it never bundles or redistributes them.
- **Open item:** get written confirmation of this use from EveryAyah's contact (quran.zendesk.com).

## Question voice (bundled clips)

Arabic prompts are recorded with the `ar-SA-ZariyahNeural` voice (Microsoft Azure AI Speech) under the app owner's licence. The clips are in `assets/audio/clips/`.

## Music and sound effects (bundled)

Generated for this app by `tool/render_music.dart` and `tool/render_sfx.dart`. No third-party audio.

## Open-source packages

Flutter and every Dart package in `pubspec.lock` (Riverpod, go_router, just_audio, audioplayers, flutter_local_notifications, image, share_plus and others) are under their own open-source licences (BSD, MIT or Apache 2.0). Flutter collects them into the app's licence page automatically.
