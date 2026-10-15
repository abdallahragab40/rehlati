# Arabic teaching voice previews

Question voice is **on** in the app, with one voice for everything: `ar-SA-ZariyahNeural`.
Letters, short syllables and taught words come from the vowelled `teaching.tsv`; instructions
come from `clips.tsv` and `phrases.tsv`. `python3 tool/render_voice.py` renders all of them
into `assets/audio/clips/`.
`lib/core/audio/teaching.dart` maps a bare letter, syllable or word to its teaching clip.
**Licence (15 Oct 2026):** the app owner holds a licence for this voice. The bundled clips were still rendered with
`edge-tts`; if the licence is for Azure AI Speech, re-render through it before release
(`AZURE_SPEECH_KEY=... AZURE_SPEECH_REGION=... FORCE=1 python3 tool/render_voice.py --engine azure`).
No paid account is needed for Edge previews; those previews are evaluation material,
not licensed production assets. Nothing here creates a cloud account or incurs charges.

## Inputs

- `teaching.tsv`: 162 draft clips: 28 names, 84 short syllables, 28 picture words,
  20 reading words, plus همزة and تاء مربوطة for spelling, matching `lib/content/language_data.dart`.
- Text and spoken input are separate TSV columns so reviewed pronunciation corrections
  can be made without changing the displayed label. No extra ه or repeated vowels are added.
- Standalone words target pausal endings (no tanwin). Review the audible ending of ة.
- The `alif` keys match the existing app's first entry. أَ، أُ، إِ are **hamza** syllables;
  they must not be presented as sounds of long alif. Resolve that distinction in the lesson
  before integrating these clips. The inventory and diacritics are drafts, not teacher approval.

## Zero-payment local preview

From the Flutter project directory:

```sh
python3 -m venv build/voice-tools
build/voice-tools/bin/pip install edge-tts
build/voice-tools/bin/python tool/render_voice.py --engine edge                    # app clips
build/voice-tools/bin/python tool/render_voice.py --pack teaching --engine edge     # review copy
```

The converter uses macOS `afconvert`. The teaching pack renders a separate review copy into
`build/voice-preview/edge/<voice>/teaching/` (with `index.html`) and never touches the app clips.

Inspect inputs without installing dependencies or calling a service:

```sh
python3 tool/render_voice.py --engine edge --dry-run
python3 tool/render_voice.py --pack teaching --engine edge --dry-run
python3 -m unittest discover -s tool -p 'test_render_voice.py'
```

Use explicit `--engine edge` for a zero-payment run even if Azure credentials are configured.

## Listening review

Check every clip for correct consonant and vowel, preserved shadda, short vowels staying
short, no letter-name substitution for syllables, no added sounds, and no cut-off edges.
Pay special attention to ث/س، ذ/ز، ظ/ض، ق/ء، ج, ح/ه and ع/ء. A fluent فصحى reviewer can
listen without recording anything. A pleasant voice alone does not establish teaching accuracy.
Rejected clips need revised input or another voice; do not ship the original workaround
that appends هْ to short syllables. Device TTS is not a reviewed replacement.

## Production route under a zero-payment constraint

Edge previews are not cleared for commercial distribution. Azure's published terms grant
prebuilt neural output commercial rights to paid-tier customers, so F0 is not our route.
Google Cloud documents application use of generated audio and a Chirp 3 HD free allowance
of one million characters. This is a candidate to investigate, not a guarantee of a
payment-free account: verify billing-account requirements and how to prevent billable usage
before setting anything up. Budget alerts alone are not a hard spending cap.
Do not enable billing or regenerate on a paid resource for this project without an updated
user instruction. No Google renderer or cloud credentials have been configured here.

References checked October 14, 2026:

- https://www.microsoft.com/licensing/terms/en-US/productoffering/MicrosoftAzure/allprograms
- https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts
- https://docs.cloud.google.com/text-to-speech/docs/basics
- https://cloud.google.com/text-to-speech/pricing

## Remaining before release

- Finish the listening review (`build/voice-preview/.../teaching/review.html`) and fix rejected clips.
- Have a فصحى reviewer confirm hamza (أَ أُ إِ) versus long alif in the letter lesson.
- Re-render every clip from a source cleared for commercial use, then re-run
  `flutter test` and `flutter test integration_test/voice_device_test.dart -d <device>`.
