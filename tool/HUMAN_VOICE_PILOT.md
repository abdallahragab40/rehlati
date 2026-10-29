# Human voice pilot: Arabic letters

The client said the app's Arabic letters don't sound right. Text-to-speech is weakest exactly here: letters said on their own, short syllables, sukun and tanween. Changing the speed doesn't fix where a letter is pronounced from. So before replacing the whole teaching library (`tool/teaching.tsv`, 287 clips), we record **47 clips** with a real teacher and compare them in the app against the current voice.

The pilot covers the letters children confuse most (ث ذ ظ ض ص ق ع ح خ غ, with ب as a baseline). For each one there's the letter's **name** (بَاء) and its **sound** with each vowel (بَ بُ بِ), recorded as separate clips. A name must never be used where the sound is meant, or the other way round.

## Who records

A teacher (male or female) who teaches young children to read Arabic, with clear Fusha pronunciation. A fluent Fusha reviewer listens to every take before it goes in.

## How to record

- **Room:** quiet, no echo (a room with curtains or a wardrobe of clothes works), phone or mic about 20 cm from the mouth.
- **File:** WAV, 44.1 or 48 kHz, 16 or 24 bit, mono or stereo. One file per clip, named exactly as the **key** below plus `.wav` (for example `l_tha_fatha.wav`).
- **Delivery:** about half a second of silence before and after. Calm and clear, the way you'd say it to a 4-year-old. Say only what's written: no "ه" added after a short vowel, no stretching a short vowel into a long one.
- **Names** (بَاء، ثَاء، …) at normal speed. **Syllables** (بَ، بُ، بِ) short and crisp.

## Putting the recordings in the app

1. Put the files in `tool/recordings/` (create the folder).
2. Run `build/voice-tools/bin/python tool/render_voice.py --engine edge`. Any clip that has a recording uses it instead of the generated voice, trimmed and converted the same way. Clips without a recording are left alone.
3. Listen in the app (letter board, harakat lessons) next to the old voice, and decide with the client before recording the remaining 240 clips.

Removing a recording and running the script again puts the generated voice back.

## The 47 clips

| Key | Say | What it is |
|---|---|---|
| `l_ba_name` | بَاء | ب · اسم الحرف |
| `l_ba_fatha` | بَ | ب · فتحة |
| `l_ba_damma` | بُ | ب · ضمة |
| `l_ba_kasra` | بِ | ب · كسرة |
| `l_tha_name` | ثَاء | ث · اسم الحرف |
| `l_tha_fatha` | ثَ | ث · فتحة |
| `l_tha_damma` | ثُ | ث · ضمة |
| `l_tha_kasra` | ثِ | ث · كسرة |
| `l_dhal_name` | ذَال | ذ · اسم الحرف |
| `l_dhal_fatha` | ذَ | ذ · فتحة |
| `l_dhal_damma` | ذُ | ذ · ضمة |
| `l_dhal_kasra` | ذِ | ذ · كسرة |
| `l_dha_name` | ظَاء | ظ · اسم الحرف |
| `l_dha_fatha` | ظَ | ظ · فتحة |
| `l_dha_damma` | ظُ | ظ · ضمة |
| `l_dha_kasra` | ظِ | ظ · كسرة |
| `l_dad_name` | ضَاد | ض · اسم الحرف |
| `l_dad_fatha` | ضَ | ض · فتحة |
| `l_dad_damma` | ضُ | ض · ضمة |
| `l_dad_kasra` | ضِ | ض · كسرة |
| `l_sad_name` | صَاد | ص · اسم الحرف |
| `l_sad_fatha` | صَ | ص · فتحة |
| `l_sad_damma` | صُ | ص · ضمة |
| `l_sad_kasra` | صِ | ص · كسرة |
| `l_qaf_name` | قَاف | ق · اسم الحرف |
| `l_qaf_fatha` | قَ | ق · فتحة |
| `l_qaf_damma` | قُ | ق · ضمة |
| `l_qaf_kasra` | قِ | ق · كسرة |
| `l_ayn_name` | عَيْن | ع · اسم الحرف |
| `l_ayn_fatha` | عَ | ع · فتحة |
| `l_ayn_damma` | عُ | ع · ضمة |
| `l_ayn_kasra` | عِ | ع · كسرة |
| `l_ha_name` | حَاء | ح · اسم الحرف |
| `l_ha_fatha` | حَ | ح · فتحة |
| `l_ha_damma` | حُ | ح · ضمة |
| `l_ha_kasra` | حِ | ح · كسرة |
| `l_kha_name` | خَاء | خ · اسم الحرف |
| `l_kha_fatha` | خَ | خ · فتحة |
| `l_kha_damma` | خُ | خ · ضمة |
| `l_kha_kasra` | خِ | خ · كسرة |
| `l_ghayn_name` | غَيْن | غ · اسم الحرف |
| `l_ghayn_fatha` | غَ | غ · فتحة |
| `l_ghayn_damma` | غُ | غ · ضمة |
| `l_ghayn_kasra` | غِ | غ · كسرة |
| `l_ba_tanween_damm` | بٌ | تنوين ضم |
| `sukun_kalb` | كَلْبٌ | كلمة فيها سكون |
| `w_shams` | شَمْس | كلمة بالوقف |
