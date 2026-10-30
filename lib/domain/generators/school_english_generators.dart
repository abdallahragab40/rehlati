/// كلمات وجمل كتاب Connect لأولى (الترم التاني) وتانية اللي مكانتش في التطبيق
/// (tool/SCHOOL_CURRICULUM_INDEX.md): المشاعر، الطقس والفصول، أوض البيت، الأماكن، المواصلات،
/// الهدوم، الرياضات، أيام الأسبوع والشهور، وin / on / under.
///
/// الكلمات من جداول Scope and Sequence في الكتاب، والصور والجمل من عندنا.
library;

import '../../content/language_data.dart';
import '../../core/utils/rng.dart';
import '../question.dart';
import 'english_generators.dart' show vocabGame;

const enFeelings = [
  Word('happy', '😀'), Word('sad', '😢'), Word('angry', '😠'), Word('scared', '😨'), Word('tired', '😴'), Word('surprised', '😲'),
];
const enWeather = [
  Word('sunny', '☀️'), Word('rainy', '🌧️'), Word('cloudy', '☁️'), Word('windy', '🌬️'), Word('snowy', '❄️'), Word('hot', '🥵'),
  Word('cold', '🥶'),
];
const enSeasons = [Word('spring', '🌸'), Word('summer', '🏖️'), Word('fall', '🍂'), Word('winter', '⛄')];
const enRooms = [
  Word('bedroom', '🛏️'), Word('bathroom', '🛁'), Word('kitchen', '🍳'), Word('living room', '🛋️'), Word('dining room', '🍽️'),
  Word('garden', '🌷'),
];
const enPlaces = [
  Word('hospital', '🏥'), Word('school', '🏫'), Word('shop', '🏪'), Word('park', '🏞️'), Word('street', '🛣️'), Word('beach', '🏖️'),
  Word('post office', '🏤'), Word('supermarket', '🛒'),
];
const enTransport = [
  Word('car', '🚗'), Word('bus', '🚌'), Word('taxi', '🚕'), Word('bicycle', '🚲'), Word('plane', '✈️'), Word('motorcycle', '🏍️'),
  Word('truck', '🚚'), Word('train', '🚆'),
];
const enClothes = [
  Word('T-shirt', '👕'), Word('shoes', '👟'), Word('jacket', '🧥'), Word('pants', '👖'), Word('dress', '👗'), Word('socks', '🧦'),
];
const enSports = [
  Word('football', '⚽'), Word('basketball', '🏀'), Word('tennis', '🎾'), Word('volleyball', '🏐'), Word('swimming', '🏊'),
  Word('running', '🏃'),
];

final enFeelingsGame = vocabGame('en_feelings', enFeelings, 'en_feel', ask: 'How do they feel?', hint: (w) => 'They feel $w.');
final enWeatherGame = vocabGame('en_weather', enWeather, 'en_weather', ask: "What's the weather like?", hint: (w) => "It's $w.");
final enSeasonsGame = vocabGame('en_seasons', enSeasons, 'en_season', ask: 'Which season is it?', hint: (w) => "It's $w.");
final enRoomsGame = vocabGame('en_rooms', enRooms, 'en_room', ask: 'Which room is this?', hint: (w) => "It's the $w.");
final enPlacesGame = vocabGame('en_places', enPlaces, 'en_place', ask: 'Where is this?', hint: (w) => "It's the $w.");
final enTransportGame = vocabGame('en_transport', enTransport, 'en_transport', hint: (w) => "It's a $w.");
final enClothesGame = vocabGame('en_clothes', enClothes, 'en_clothes', hint: (w) => 'They are $w.');
final enSportsGame = vocabGame('en_sports', enSports, 'en_sport', ask: 'What sport is this?', hint: (w) => "It's $w.");

// ---------------------------------------------------------------- الأيام والشهور

const enDays = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
const enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December',
];

/// «What day comes after Monday?» — ومن المستوى التاني «before» كمان. الأسبوع بيبدأ السبت زي الكتاب.
Question Function(int, Rng, {String? focus}) _sequenceGame(String type, List<String> items, String noun) =>
    (int lv, Rng r, {String? focus}) {
      final i = items.contains(focus) ? items.indexOf(focus!) : r.rnd(0, items.length - 1);
      final after = lv <= 1 || r.chance(.5);
      final answer = items[(i + (after ? 1 : -1)) % items.length];
      final ask = 'What $noun comes ${after ? 'after' : 'before'} ${items[i]}?';
      final others = r.shuffle([for (final x in items) if (x != answer && x != items[i]) x]).take(lv <= 1 ? 2 : 3);
      return Question(
        type: type, mode: QMode.choice, lang: 'en', ltr: true, numeric: false, wide: true, skill: '$type:${items[i]}',
        ask: ask, speak: ask,
        visuals: [CaptionVisual(after ? '${items[i]} → ?' : '? → ${items[i]}')],
        choices: r.shuffle([answer, ...others]),
        answer: answer,
        hint: 'Say them in order: ${items.join(', ')}.',
        speakHint: 'Say them in order',
      );
    };

final enDaysGame = _sequenceGame('en_days', enDays, 'day');
final enMonthsGame = _sequenceGame('en_months', enMonths, 'month');

// ---------------------------------------------------------------- in / on / under

/// (الصورة، الاسم) للحاجة، و(الصورة، الاسم، الحروف اللي تنفع معاه) للمكان.
const prepThings = [('🐱', 'cat'), ('🐶', 'dog'), ('⚽', 'ball'), ('🐦', 'bird'), ('🧸', 'teddy bear'), ('🍎', 'apple')];
/// صورة الكنبة فيها أباجورة طويلة وضهر الكرسي عالي، فـ"on" عليهم بتبان طايرة — الكرسي للـ under بس.
const prepPlaces = [
  ('📦', 'box', ['in', 'on', 'under']), ('🧺', 'basket', ['in']), ('🪑', 'chair', ['under']), ('🛏️', 'bed', ['on', 'under']),
];

/// «Where is the cat?» وصورة الحاجة جوه المكان أو فوقه أو تحته، ومن المستوى التاني: اختار الجملة الصح.
Question enPrep(int lv, Rng r, {String? focus}) {
  final (thing, thingName) = r.sample(prepThings);
  final (place, placeName, allowed) = r.sample(prepPlaces);
  final prep = focus != null && allowed.contains(focus) ? focus : r.sample(allowed);
  String sentence(String p) => 'The $thingName is $p the $placeName.';
  final visual = PrepVisual(thing, place, prep);
  if (lv >= 2 && r.chance(.5)) {
    return Question(
      type: 'en_prep', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, wide: true, skill: 'en_prep:$prep',
      ask: 'Choose the right sentence', speak: 'Choose the right sentence.',
      visuals: [visual],
      choices: r.shuffle([for (final p in ['in', 'on', 'under']) sentence(p)]),
      answer: sentence(prep),
      hint: 'Look: is it in, on or under the $placeName?',
      speakHint: 'Is it in, on or under?',
    );
  }
  return Question(
    type: 'en_prep', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_prep:$prep',
    ask: 'Where is the $thingName?', speak: 'Where is the $thingName?',
    visuals: [visual],
    choices: r.shuffle(['in', 'on', 'under']),
    answer: prep,
    hint: 'in = inside, on = on top, under = below',
    speakHint: 'In is inside. On is on top. Under is below.',
    sayRight: sentence(prep),
  );
}

// ---------------------------------------------------------------- Classroom actions

const enActions = [
  Word('write', '✍️'), Word('read', '📖'), Word('draw', '🖍️'), Word('sing', '🎤'), Word('clean', '🧹'), Word('sit', '🪑'),
  Word('stand', '🧍'), Word('listen', '👂'),
];
final enActionsGame = vocabGame('en_actions', enActions, 'en_action', ask: 'Which action is this?', hint: (w) => 'We $w in class.');

// ---------------------------------------------------------------- الأعداد لحد ١٠٠

const _ones = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen',
  'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
];
const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

/// ٢٥ ← twenty-five.
String enNumberWord(int n) => n == 100
    ? 'one hundred'
    : n < 20
        ? _ones[n]
        : '${_tens[n ~/ 10]}${n % 10 == 0 ? '' : '-${_ones[n % 10]}'}';

/// العدد مكتوب بالأرقام والطفل يختار اسمه، أو «What comes next?» بالعد بالعشرات أو واحد واحد.
/// focus: to20 / to50 / to100 بيحدد المدى (درس المدرسة)، ومن غيره المستوى.
Question enCount100(int lv, Rng r, {String? focus}) {
  final (lo, hi) = switch (focus) {
    'to20' => (11, 20),
    'to50' => (20, 50),
    'to100' => (20, 100),
    _ => switch (lv) { <= 1 => (11, 20), 2 => (20, 50), _ => (20, 100) },
  };
  if (r.chance(.4)) {
    final byTen = hi > 20 && r.chance(.5);
    final step = byTen ? 10 : 1;
    final start = byTen ? r.rnd(1, hi ~/ 10 - 3) * 10 : r.rnd(lo, hi - 3);
    final seq = [for (var i = 0; i < 3; i++) start + i * step];
    final next = start + 3 * step;
    final options = {next, next + step, if (next - 2 * step > 0) next - 2 * step, next + 1, next - 1}..remove(seq.last);
    return Question(
      type: 'en_count100', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, wide: true, skill: 'en_next:$step',
      ask: 'What comes next?', speak: 'What comes next?',
      visuals: [CaptionVisual('${seq.join(', ')}, ?')],
      choices: r.shuffle([enNumberWord(next), ...r.shuffle(options.where((x) => x != next && x <= 100).toList()).take(2).map(enNumberWord)]),
      answer: enNumberWord(next),
      hint: byTen ? 'Count by tens: ten, twenty, thirty…' : 'Count one more.',
      speakHint: byTen ? 'Count by tens' : 'Count one more',
    );
  }
  final n = r.rnd(lo, hi);
  // الأرقام المقلوبة (٢٥ و٥٢) وجيران العدد
  final swapped = n % 10 * 10 + n ~/ 10;
  final wrong = {if (n >= 20 && n % 10 != 0 && swapped != n && swapped >= 10) swapped, n + 1, n - 1, n + 10, n - 10}
    ..removeWhere((x) => x < 11 || x > 100 || x == n);
  return Question(
    type: 'en_count100', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, wide: true, skill: 'en_num100:$n',
    ask: 'Which number is this?', speak: 'Which number is this?',
    visuals: [BigLetterVisual('$n')],
    choices: r.shuffle([enNumberWord(n), ...r.shuffle(wrong.toList()).take(2).map(enNumberWord)]),
    answer: enNumberWord(n),
    hint: n < 20 ? 'Teen numbers end in -teen.' : 'Say the tens first, then the ones.',
    speakHint: n < 20 ? 'Teen numbers end in teen' : 'Say the tens first, then the ones',
    sayRight: enNumberWord(n),
  );
}

// ---------------------------------------------------------------- Pronouns

/// (الصورة، الجملة، الضمير) — الصورة بتفرّق He وShe وIt، وam / are بيفرّقوا I وThey.
const pronounSentences = [
  ('👦', '___ is happy.', 'He'), ('👧', '___ is tired.', 'She'), ('🐶', '___ is small.', 'It'),
  ('👴', '___ is my grandfather.', 'He'), ('👵', '___ is my grandmother.', 'She'), ('🐱', '___ is a cat.', 'It'),
  ('👫', '___ are friends.', 'They'), ('👨‍👩‍👧', '___ are my family.', 'They'), ('🙋', '___ am a student.', 'I'),
  ('🙋', '___ am seven.', 'I'),
];

Question enPronouns(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(pronounSentences);
  final others = r.shuffle(['I', 'He', 'She', 'It', 'They'].where((p) => p != answer).toList()).take(lv <= 1 ? 1 : 2);
  return Question(
    type: 'en_pronouns', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_pron:$answer',
    ask: 'Choose the right word', speak: 'Choose the right word.',
    visuals: [PicsVisual(pic, 1, big: true), WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle([answer, ...others]),
    answer: answer,
    hint: 'He = a boy, She = a girl, It = an animal or a thing, They = more than one, I = me.',
    speakHint: 'He is a boy, she is a girl, it is an animal or a thing, they are more than one',
    sayRight: sentence.replaceFirst('___', answer),
  );
}

// ---------------------------------------------------------------- Phonics: blends, digraphs, long vowels

/// (الكلمة، الصورة، الصوت الناقص، المجموعة). الناقص في أول الكلمة، أو آخرها (final)، أو حرف العلة (long).
const soundWords = [
  ('skate', '⛸️', 'sk', 'blendS'), ('snake', '🐍', 'sn', 'blendS'), ('star', '⭐', 'st', 'blendS'), ('swan', '🦢', 'sw', 'blendS'),
  ('clock', '🕐', 'cl', 'blendL'), ('block', '🧱', 'bl', 'blendL'), ('flag', '🚩', 'fl', 'blendL'), ('sled', '🛷', 'sl', 'blendL'),
  ('ship', '🚢', 'sh', 'digraph'), ('shoe', '👞', 'sh', 'digraph'), ('chair', '🪑', 'ch', 'digraph'),
  ('cheese', '🧀', 'ch', 'digraph'), ('thumb', '👍', 'th', 'digraph'), ('three', '3️⃣', 'th', 'digraph'),
  ('lamp', '🪔', 'mp', 'final'), ('gift', '🎁', 'ft', 'final'), ('salt', '🧂', 'lt', 'final'), ('hand', '✋', 'nd', 'final'),
  ('mask', '🎭', 'sk', 'final'),
  ('cake', '🎂', 'a', 'long'), ('game', '🎮', 'a', 'long'), ('kite', '🪁', 'i', 'long'), ('bike', '🚲', 'i', 'long'),
  ('nose', '👃', 'o', 'long'), ('rose', '🌹', 'o', 'long'), ('cube', '🧊', 'u', 'long'),
];

const _soundHints = {
  'blendS': 'Two letters, two sounds: s + k = sk.',
  'blendL': 'Two letters, two sounds: c + l = cl.',
  'digraph': 'Two letters, one sound: sh, ch, th.',
  'final': 'Listen to the end of the word.',
  'long': 'The silent e makes the vowel say its name: c-a-k-e.',
};

/// الصوت الناقص في الكلمة. focus: blendS / blendL / digraph / final / long (درس المدرسة).
Question enSounds(int lv, Rng r, {String? focus}) {
  final kinds = _soundHints.containsKey(focus)
      ? [focus!]
      : lv <= 1
          ? ['blendS', 'blendL', 'digraph']
          : _soundHints.keys.toList();
  final kind = r.sample(kinds);
  final (word, pic, sound, _) = r.sample(soundWords.where((w) => w.$4 == kind).toList());
  final at = switch (kind) { 'final' => word.length - sound.length, 'long' => word.indexOf(sound), _ => 0 };
  final shown = '${word.substring(0, at)}${'_' * sound.length}${word.substring(at + sound.length)}';
  final options = {for (final w in soundWords) if (w.$4 == kind) w.$3}.toList();
  final choices = [sound, ...r.shuffle(options.where((s) => s != sound).toList()).take(lv <= 1 ? 1 : 2)];
  return Question(
    type: 'en_sounds', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_sound:$kind',
    ask: 'Which sound is missing?', speak: 'Which sound is missing? $word.',
    visuals: [PicsVisual(pic, 1, big: true), BigLetterVisual(shown)],
    choices: r.shuffle(choices),
    answer: sound,
    // الصوت لوحده مش بيتسجّل حلو — الكلمة كاملة بتتقال لما يجاوب صح
    choiceSay: {for (final c in choices) c: ''},
    hint: _soundHints[kind]!,
    speakHint: _soundHints[kind]!,
    sayRight: word,
  );
}
