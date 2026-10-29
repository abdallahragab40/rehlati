# New games: what to check before release

16 new stages at the end of the Games world (branch `new-kids-games`). All their text is in
`lib/content/play_data.dart`. The voice clips were rendered with edge-tts (Zariyah), like the
other clips. If the voice licence is for Azure, re-render them with the rest.

## Needs a teacher or sheikh

- **Wudu order** (`wuduSteps`): hands, rinsing the mouth, nose, face, arms to the elbows, wiping the
  head, ears, feet. The game shows 3–6 steps in a row from this list. Check the order and the wording
  (اغسل كفّيك، المضمضة، الاستنشاق، اغسل وشّك، اغسل إيديك للكوع، امسح راسك، امسح ودانك، اغسل رجليك).
  It leaves out the intention and saying بسم الله on purpose.
- **Manners** (`manners`): 24 situations, each with a ✅ or ❌ answer and the reason that's said
  afterwards. They follow the parent-guide topics (sharing, hitting, cleaning, waiting, interrupting,
  water, animals, street safety).

- **Game ages** (`gameAges` in `lib/domain/stages.dart`): each game's age range decides what the
  games map shows first and what the journey picks. Games stay open for any age. Check the ranges,
  especially where one ends (shadow and opposites stop at 6, the letter games at 7–8).

## Listen to these clips

Animal sounds read by the voice: مووو، مياو مياو، هو هو، ماااء، كاك كاك كاك، كوكوكوكووو، سيو سيو،
كواك كواك، هوو هوو، زززززز، سسسسسس. Their keys are in `tool/phrases.tsv`. If a sound comes out
wrong, change its spelling in `animalSounds` and re-render.

## Puzzles for older children (6–12)

سودوكو (4×4 with pictures, then numbers, then 6×6, always one solution), برج هانوي (2–4 rings),
البازل المنزلق (3×3, more shuffling at higher levels) and كمّل المتتالية (adding, subtracting,
doubling, growing steps; numbers up to 100). Game difficulty now follows age: 3–4 → level 1,
5–6 → 2, 7–8 → 3, 9+ → 4.

## Known limits

- **Trace**: the game checks that the finger covers most of the shape and stays on it. It doesn't
  check stroke order or direction.
- **Where's the cat?** follows the device's reduce-motion setting only for the small effects. The
  cups still move, because following them is the game.
- **صوّر الكلمة** isn't a new stage: «الكلمة والصورة» (`ar_match_word`) in the Arabic world already
  shows a written word and asks for its picture.
