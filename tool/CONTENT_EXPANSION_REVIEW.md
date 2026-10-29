# Sukun, tanween, and ages 9–12 — review handoff

Status: implemented practice and synthesized audio drafts. **No teacher has signed off.**
Requested by the app owner on 29 October 2026. This is a first practice pack for older children,
not coverage of the full Egyptian grade 4–6 curriculum. Store age claims should wait for content review.

## Sukun and tanween

Objective: identify the three tanween signs, distinguish them from short vowel signs, and identify
one consonant with sukun inside a fully vowelled word. Intended for early primary readers;
not a new age 9–12 prerequisite.

- `tool/teaching.tsv` adds 125 separate inputs: 81 tanween syllables (27 consonants × 3),
  28 named consonants with sukun, 15 vowelled words, and the word-part distractor `ةٌ`.
- `teaching.dart` routes the exact vowelled text to teaching recordings. Existing pausal
  recordings such as `شمس` stay distinct from `شَمْسٌ`.
- Open [the listening sheet](sukun-tanween-review.html) in a browser beside
  [the review TSV](SUKUN_TANWEEN_REVIEW.tsv). Each row is initially `pending`.
  Enter reviewer name, date, decision (`approved` or `revise`), and corrections in the TSV.
- The audio is synthesized with the existing Zariyah Edge preview workflow. Follow the existing
  production-source requirements in [VOICE_PREVIEW.md](../tool/VOICE_PREVIEW.md) before release.

Teacher checks:

1. Listen to all three endings for every consonant: short vowel + audible final /n/. A voice
   may switch to a letter name, stretch a short vowel, or drop tanween at a pause. Reject those clips.
2. In `بًا`, the written support alif must not turn the short vowel into a long madd. Do not
   teach “fathatan always needs alif”: words ending in ة and some hamza cases are exceptions.
   The current standalone tanween pool excludes hamza/alif and does not teach those cases yet.
3. Check all 15 word diacritics, the internal sukun, and final tanween. Confirm that the task
   intentionally teaches the connected ending, even when the word is heard alone.
4. Check isolated `ةٌ` (spoken input `تٌ`) as a distractor within زهرة/وردة; approve the teaching
   convention or request a whole-word prompt instead. It must never sound like a bare ه.
5. The isolated consonant with sukun is named (“لام ساكنة”), rather than given an invented
   standalone vowel. Confirm wording and that the displayed choices retain their diacritics.
6. Review the hints and the listen stage on a real device. Automated asset coverage does
   not establish pronunciation accuracy. Record rejected clip keys before revising inputs.

| Teacher | Date | Diacritics | Audible endings | Hints and distractors | Overall decision |
|---|---|---|---|---|---|
| Pending | | Pending | Pending | Pending | Pending |

## Ages 9–12: first maths pack

Objective: use multiplication to divide exactly, recover a missing dividend, calculate a proper
fraction of a quantity, and identify equivalent fractions. No remainders or decimals in this pack.
Prerequisite: multiplication tables to 10. The first stage opens for grade 4 or above (including the
usual grade inferred from age 9–12), or after passing `timesAll`. A parent's explicit grade wins.
Subsequent stages unlock in order. All old stage IDs keep their order.

| Stage | Levels 1–2 | Levels 3–4 | Teacher check |
|---|---|---|---|
| `divisionExact` | Divisor 2–5; quotient 1–5 | Divisor 2–10; quotient 1–10 | Inverse multiplication and equation reading |
| `divisionMissing` | Same bounds; missing dividend | Same extension | Does the hint support understanding? |
| `fractionOfNumber` | Unit fractions, denominators 2–5 | Proper fractions, denominators 2–10 | Equal parts before the symbolic procedure |
| `fractionEquivalent` | Unit fractions scaled by 2–3 | Proper fractions scaled by 2–5 | Same value despite different written numbers |

The path **رحلة القسمة والكسور** has four weeks of four lessons. It reuses scored practice for
review, so lesson titles do not promise separate subskills the generators cannot select.
Fractions use stacked numerator/denominator choices with spoken accessibility labels.
Questions remain answerable with voice disabled.

A teacher should review every week's goal, wording, examples and difficulty progression. Try the
pack with children across 9–12 before choosing narrower grade labels. Older learners start at the
existing adaptive subject level and can revisit easier levels through parent settings.

Still outside this first pack: multi-step word problems, decimals,
fractions arithmetic, larger-number arithmetic, and a complete grade-by-grade sequence.

| Maths teacher | Date | Questions and hints | Weekly sequence | Age suitability | Decision |
|---|---|---|---|---|---|
| Pending | | Pending | Pending | Pending | Pending |

## Ages 9–12: first Arabic pack (grammar and comprehension)

Objective: classify a vowelled word as اسم / فعل / حرف; tell مفرد / مثنى / جمع and مذكر / مؤنث
for common words; give the opposite of a common adjective or place word; choose the word that
completes a short sentence. The first stage opens for grade 4 or above, or after `ar_sukun`.
Subsequent stages unlock in order. The path **رحلة القواعد والفهم** has four weeks of four lessons.

| Stage | What varies | Teacher check |
|---|---|---|
| `ar_wordType` | 10 nouns, 10 verbs (past and present), 10 particles; particles from level 3 | Is every particle a clear حرف for this age? (`فِي` is left out of this list only because the voice tool stretched it; it appears in sentences.) |
| `ar_number` | 10 singular / dual / plural sets; dual always nominative ـانِ | `شَجَرَةٌ` → `أَشْجَارٌ` (not شَجَرَاتٌ) and `طَالِبٌ` → `طُلَّابٌ`: accept as the taught plurals? |
| `ar_gender` | 8 pairs: ة-feminines plus وَلَدٌ/بِنْتٌ, دِيكٌ/دَجَاجَةٌ, جَمَلٌ/نَاقَةٌ, رَجُلٌ/امْرَأَةٌ, أَبٌ/أُمٌّ | No feminine-without-ة words like شَمْسٌ; add them later if wanted |
| `ar_opposite` | 12 pairs (كَبِيرٌ/صَغِيرٌ … مَفْتُوحٌ/مُغْلَقٌ); distractors from other pairs | `نَظِيفٌ`/`مُتَّسِخٌ` and `نَهَارٌ`/`لَيْلٌ` wording |
| `ar_sentence` | 12 sentences; the three choices share the grammatical case, so only meaning decides | Diacritics of every sentence and choice; is each wrong choice clearly wrong in meaning? |

Lists live in `lib/domain/generators/grammar_generators.dart`. All words are fully vowelled and
read in full (with tanween), not pausal. The voice tool no longer stretches `فِي` and similar words
inside fully vowelled sentences; syllable prompts like "اقرأ معي. فِي" are unchanged.

Still outside: reading passages with questions, إعراب, verb tenses and conjugation, and
grade-by-grade alignment.

| Arabic teacher | Date | Word lists and diacritics | Sentences | Age suitability | Decision |
|---|---|---|---|---|---|
| Pending | | Pending | Pending | Pending | Pending |

## Primary English (grades 1–3 and ages 9–12)

English questions are spoken by the device's English voice, so there are no new recordings.
Lists live in `lib/domain/generators/en_primary_generators.dart`.

| Stage | Opens | What varies | Teacher check |
|---|---|---|---|
| `en_cvc` | first primary, or after `en_word` | 14 CVC words with pictures; distractors are real words one letter away (a test enforces it) | Are all distractors familiar enough? |
| `en_a_an` | in order | 8 "an" nouns and 8 "a" nouns; no hour/unicorn exceptions | Add the exceptions later? |
| `en_plural` | in order | s and es from the start, y→ies from level 3, irregular (children, mice, teeth, feet) at level 4; distractors are the singular and a common wrong plural (cates, boxs, childs) | Are made-up wrong plurals acceptable as distractors? |
| `en_isare` | fourth primary, or after `en_plural` | 14 sentences; am (with I) from level 3 | Sentences and level |
| `en_questions` | in order | 12 questions for What / Where / Who / When / Why / How | Each blank has exactly one natural answer |
| `en_sentence` | in order | 12 sentences completed by meaning | Each wrong choice is clearly wrong |

Paths: **رحلة القراءة بالإنجليزي** (6–9) and **رحلة قواعد الإنجليزي** (9–12), 4 weeks of 4 lessons each.

| English teacher | Date | Word lists | Sentences and questions | Age suitability | Decision |
|---|---|---|---|---|---|
| Pending | | Pending | Pending | Pending | Pending |

## Automated validation — 29 October 2026

- `flutter analyze`: no issues.
- `flutter test`: 634 passed; one live Quran network test skipped by default.
- Python voice-renderer tests: 4 passed.
- All 125 teacher-sheet audio files exist and are nonempty. Seeded checks cover exact division,
  fraction quantities, unique equivalent-fraction answers, grade entry, and vowelled audio routing.
- Small-screen and accessibility tests include the new activities and path. No real-device
  listening or human teacher review was performed in this pass.
