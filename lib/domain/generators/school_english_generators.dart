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
    hint: n < 20 ? '11 = eleven, 12 = twelve; 13–19 end in -teen.' : 'Say the tens first, then the ones.',
    speakHint: n < 20 ? 'Say them in order' : 'Say the tens first, then the ones',
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
/// focus كمان ممكن يحدد الأصوات نفسها: «digraph:sh,th» أو «long:a,i» (درس بعينه في الكتاب).
Question enSounds(int lv, Rng r, {String? focus}) {
  final parts = focus?.split(':');
  final only = parts != null && parts.length == 2 ? parts[1].split(',').toSet() : null;
  final group = parts?.first;
  final kinds = _soundHints.containsKey(group)
      ? [group!]
      : lv <= 1
          ? ['blendS', 'blendL', 'digraph']
          : _soundHints.keys.toList();
  final kind = r.sample(kinds);
  final pool = soundWords.where((w) => w.$4 == kind && (only == null || only.contains(w.$3))).toList();
  final (word, pic, sound, _) = r.sample(pool.isEmpty ? soundWords.where((w) => w.$4 == kind).toList() : pool);
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

// ================================================================ Connect 3 (تالتة)

/// جملة بخانة وصورة: الإجابة الواحدة الصح بتيجي من الصورة أو من كلمة في الجملة.
Question _enBlank(String type, String skill, String? pic, String sentence, String answer, List<String> choices, Rng r,
        {required String hint}) =>
    Question(
      type: type, mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: skill,
      ask: 'Choose the right word', speak: 'Choose the right word.',
      visuals: [if (pic != null) PicsVisual(pic, 1, big: true), WordLineVisual.text(sentence, big: true)],
      choices: r.shuffle([...choices]), answer: answer,
      hint: hint, speakHint: hint,
      sayRight: sentence.replaceFirst('___', answer),
    );

/// (الصورة، الجملة، الكلمة) — الفاعل في الجملة بيحدد الكلمة: I → my، he → his، she → her.
/// (الصورة لوحدها مكانتش كفاية: «These are ___ books.» مع 🙋 كانت تنفع his وher كمان.)
const possessiveSentences = [
  ('👦', 'He loves ___ dog.', 'his'), ('👧', 'She loves ___ cat.', 'her'), ('🙋', 'I love ___ mom.', 'my'),
  ('👦', 'He is washing ___ hands.', 'his'), ('👧', 'She is brushing ___ hair.', 'her'), ('🙋', 'I am doing ___ homework.', 'my'),
];

Question enPossessive(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(possessiveSentences);
  return _enBlank('en_possessive', 'en_poss:$answer', pic, sentence, answer, ['my', 'his', 'her'], r,
      hint: 'I → my, he → his, she → her.');
}

/// (الجملة، الإجابة، الاختيارات) — Yesterday = ماضي. المنتظم بـ ed، ومن المستوى التالت أفعال شاذة (went, saw).
const pastSentences = [
  ('Yesterday, I ___ football.', 'played', ['play', 'plays', 'played']),
  ('Yesterday, she ___ to school.', 'walked', ['walk', 'walks', 'walked']),
  ('Yesterday, we ___ our room.', 'cleaned', ['clean', 'cleans', 'cleaned']),
  ('Yesterday, he ___ the ball.', 'kicked', ['kick', 'kicks', 'kicked']),
  ('Yesterday, they ___ their hands.', 'clapped', ['clap', 'claps', 'clapped']),
  ('Yesterday, I ___ my grandma.', 'called', ['call', 'calls', 'called']),
];
const pastIrregular = [
  ('Yesterday, he ___ to the park.', 'went', ['go', 'goes', 'went']),
  ('Yesterday, they ___ a lion at the zoo.', 'saw', ['see', 'sees', 'saw']),
  ('Yesterday, I ___ an apple.', 'ate', ['eat', 'eats', 'ate']),
  ('Yesterday, she ___ very fast.', 'ran', ['run', 'runs', 'ran']),
];

/// focus: regular / irregular.
Question enPast(int lv, Rng r, {String? focus}) {
  final irregular = focus == 'irregular' || (focus != 'regular' && lv >= 3 && r.chance(.4));
  final (sentence, answer, choices) = r.sample(irregular ? pastIrregular : pastSentences);
  return _enBlank('en_past', 'en_past:${irregular ? 'irr' : 'reg'}', null, sentence, answer, choices, r,
      hint: irregular ? 'Some verbs change: go → went, see → saw.' : 'Yesterday = past. Add -ed: play → played.');
}

/// (الصورة، الجملة، الإجابة، الاختيارات).
const safetySentences = [
  ('⛑️', 'You ___ wear a helmet on a bike.', 'must', ['must', "mustn't"]),
  ('🚦', 'You ___ cross when the light is red.', "mustn't", ['must', "mustn't"]),
  ('🔥', '___ touch! It is hot.', "Don't", ['Do', "Don't"]),
  ('🛑', '___! A car is coming.', 'Stop', ['Stop', 'Go']),
  ('🚗', 'You ___ wear a seat belt.', 'must', ['must', "mustn't"]),
  ('🧑‍🦯', '___ talk to strangers.', "Don't", ['Do', "Don't"]),
];

Question enSafety(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer, choices) = r.sample(safetySentences);
  return _enBlank('en_safety', 'en_safety:$answer', pic, sentence, answer, choices, r,
      hint: "must = you have to. mustn't / Don't = no!");
}

const enFood = [
  Word('rice', '🍚'), Word('bread', '🍞'), Word('cheese', '🧀'), Word('honey', '🍯'), Word('soup', '🍲'), Word('fries', '🍟'),
  Word('cookies', '🍪'), Word('sweets', '🍬'), Word('lollipop', '🍭'), Word('vegetables', '🥦'), Word('nuts', '🥜'),
  Word('soda', '🥤'),
];
final enFoodGame = vocabGame('en_food', enFood, 'en_food', ask: 'What food is this?', hint: (w) => 'The word is "$w".');

/// (الجملة، الإجابة) — and = الاتنين، or = واحد بس (غالبًا سؤال)، but = عكس.
const conjSentences = [
  ('I like apples ___ bananas.', 'and'), ('My dad ___ my mom are at home.', 'and'),
  ('Do you want tea ___ juice?', 'or'), ('Is it a cat ___ a dog?', 'or'),
  ("I like cats, ___ I don't like dogs.", 'but'), ("The phone is new, ___ it doesn't work.", 'but'),
];

Question enConj(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = r.sample(conjSentences);
  return _enBlank('en_conj', 'en_conj:$answer', null, sentence, answer, ['and', 'or', 'but'], r,
      hint: 'and = both, or = one of them, but = something different.');
}

/// (الصورة، الجملة، الإجابة).
const canSentences = [
  ('🐟', 'A fish ___ swim.', 'can'), ('🐟', 'A fish ___ fly.', "can't"), ('🐦', 'A bird ___ fly.', 'can'),
  ('🐘', 'An elephant ___ fly.', "can't"), ('🐒', 'A monkey ___ climb.', 'can'), ('🐢', 'A turtle ___ run fast.', "can't"),
];

Question enCan(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(canSentences);
  return _enBlank('en_can', 'en_can:$answer', pic, sentence, answer, ['can', "can't"], r,
      hint: "can = it is able to. can't = it is not able to.");
}

// ================================================================ Connect 4 (رابعة)

/// المضارع البسيط: الفاعل بيحدد شكل الفعل. focus: affirm (plays/play) / negq (doesn't / Does).
const presentSentences = [
  ('She ___ football every day.', 'plays', ['play', 'plays', 'playing']),
  ('They ___ to school by bus.', 'go', ['go', 'goes', 'going']),
  ('My dad ___ coffee in the morning.', 'drinks', ['drink', 'drinks', 'drinking']),
  ('I ___ with my nose.', 'smell', ['smell', 'smells', 'smelling']),
  ('He ___ his teeth every night.', 'brushes', ['brush', 'brushes', 'brushing']),
  ('We ___ our grandma on Fridays.', 'visit', ['visit', 'visits', 'visiting']),
];
const presentNegQ = [
  ('He ___ like fish.', "doesn't", ["don't", "doesn't"]),
  ('They ___ play in the street.', "don't", ["don't", "doesn't"]),
  ('___ she live near the park?', 'Does', ['Do', 'Does']),
  ('___ you help your neighbors?', 'Do', ['Do', 'Does']),
  ('My cat ___ eat vegetables.', "doesn't", ["don't", "doesn't"]),
  ('___ your friends volunteer?', 'Do', ['Do', 'Does']),
];

Question enPresent(int lv, Rng r, {String? focus}) {
  final negq = focus == 'negq' || (focus != 'affirm' && lv >= 2 && r.chance(.5));
  final (sentence, answer, choices) = r.sample(negq ? presentNegQ : presentSentences);
  return _enBlank('en_present', 'en_present:${negq ? 'negq' : 'aff'}', null, sentence, answer, choices, r,
      hint: negq ? "he / she / it → doesn't, Does. I / you / we / they → don't, Do." : 'he / she / it → add -s: she plays.');
}

/// (الصورة، الجملة، الإجابة، الاختيارات) — focus: comp (bigger) / super (the biggest).
const compareSentences = [
  ('🐘🐭', 'An elephant is ___ than a mouse.', 'bigger', ['big', 'bigger', 'the biggest']),
  ('🦒🐶', 'A giraffe is ___ than a dog.', 'taller', ['tall', 'taller', 'the tallest']),
  ('🐆🐢', 'A cheetah is ___ than a turtle.', 'faster', ['fast', 'faster', 'the fastest']),
  ('🐢🐇', 'A turtle is ___ than a rabbit.', 'slower', ['slow', 'slower', 'the slowest']),
];
const superSentences = [
  ('🐋', 'The blue whale is ___ animal in the world.', 'the biggest', ['big', 'bigger', 'the biggest']),
  ('🦒', 'The giraffe is ___ animal in the zoo.', 'the tallest', ['tall', 'taller', 'the tallest']),
  ('🐆', 'The cheetah is ___ animal on land.', 'the fastest', ['fast', 'faster', 'the fastest']),
  ('🗼', 'Cairo Tower is ___ building in our street.', 'the tallest', ['tall', 'taller', 'the tallest']),
];

Question enCompare(int lv, Rng r, {String? focus}) {
  final sup = focus == 'super' || (focus != 'comp' && lv >= 3 && r.chance(.5));
  final (pic, sentence, answer, choices) = r.sample(sup ? superSentences : compareSentences);
  return _enBlank('en_compare', 'en_compare:${sup ? 'super' : 'comp'}', pic, sentence, answer, choices, r,
      hint: sup ? 'Many things: the + -est (the biggest).' : 'Two things: -er + than (bigger than).');
}

/// next to و between: صف صور، والجملة عن اللي في النص أو جنبه.
Question enPrep2(int lv, Rng r, {String? focus}) {
  const things = [('🌳', 'tree'), ('🏠', 'house'), ('🚗', 'car'), ('🐱', 'cat'), ('🐶', 'dog'), ('⚽', 'ball')];
  final row = r.shuffle([...things]).take(3).toList();
  final between = r.chance(.5);
  // الصف بيتقري من الشمال (إنجليزي): أول عنصر على الشمال
  final sentence = between
      ? 'The ${row[1].$2} is ___ the ${row[0].$2} and the ${row[2].$2}.'
      : 'The ${row[0].$2} is ___ the ${row[1].$2}.';
  return Question(
    type: 'en_prep2', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_prep2:${between ? 'between' : 'next'}',
    ask: 'Choose the right word', speak: 'Choose the right word.',
    visuals: [CaptionVisual(row.map((x) => x.$1).join('   ')), WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle(['between', 'next to', 'under']), answer: between ? 'between' : 'next to',
    hint: 'between = in the middle of two things. next to = beside.',
    speakHint: 'between is in the middle, next to is beside',
    sayRight: sentence.replaceFirst('___', between ? 'between' : 'next to'),
  );
}

const enJobs = [
  Word('doctor', '🧑‍⚕️'), Word('teacher', '🧑‍🏫'), Word('engineer', '👷'), Word('firefighter', '🧑‍🚒'),
  Word('police officer', '👮'), Word('farmer', '🧑‍🌾'), Word('pilot', '🧑‍✈️'), Word('cook', '🧑‍🍳'),
  Word('photographer', '📸'), Word('carpenter', '🪚'),
];
final enJobsGame = vocabGame('en_jobs', enJobs, 'en_job', ask: 'What is this job?', hint: (w) => 'This is a $w.');

const enEnvironment = [
  Word('desert', '🏜️'), Word('forest', '🌲'), Word('river', '🏞️'), Word('village', '🏘️'), Word('city', '🏙️'),
  Word('oasis', '🌴'), Word('sea', '🌊'), Word('mountain', '⛰️'), Word('recycle', '♻️'), Word('pollution', '🏭'),
];
final enEnvironmentGame = vocabGame('en_environment', enEnvironment, 'en_env', ask: 'What is this?', hint: (w) => 'The word is "$w".');

/// countable / uncountable: a carton of milk, a bottle of water…
const containerSentences = [
  ('🥛', 'a ___ of milk', 'carton', ['carton', 'slice', 'bar']),
  ('💧', 'a ___ of water', 'bottle', ['bottle', 'piece', 'slice']),
  ('🍞', 'a ___ of bread', 'slice', ['slice', 'bottle', 'carton']),
  ('🍫', 'a ___ of chocolate', 'bar', ['bar', 'bottle', 'carton']),
  ('🍰', 'a ___ of cake', 'piece', ['piece', 'bottle', 'carton']),
  ('🍯', 'a ___ of honey', 'jar', ['jar', 'slice', 'bar']),
];

Question enContainers(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.4)) {
    const words = [('apple', true), ('water', false), ('egg', true), ('milk', false), ('banana', true), ('rice', false)];
    final (w, countable) = r.sample(words);
    return Question(
      type: 'en_containers', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true,
      skill: 'en_count:${countable ? 'c' : 'u'}',
      ask: 'Can we count it?', speak: 'Can we count it? $w.',
      visuals: [BigLetterVisual(w)],
      choices: const ['countable', 'uncountable'], answer: countable ? 'countable' : 'uncountable',
      hint: 'We can count apples (one apple, two apples). We can\'t count water.',
      speakHint: 'We can count apples. We can not count water.',
      sayRight: w,
    );
  }
  final (pic, phrase, answer, choices) = r.sample(containerSentences);
  return _enBlank('en_containers', 'en_container', pic, phrase, answer, choices, r,
      hint: 'a carton of milk, a bottle of water, a slice of bread, a bar of chocolate.');
}

const enCelebrate = [
  Word('gift', '🎁'), Word('balloons', '🎈'), Word('fireworks', '🎆'), Word('candles', '🕯️'), Word('music', '🎵'),
  Word('cake', '🎂'), Word('party', '🎉'), Word('ribbon', '🎀'),
];
final enCelebrateGame = vocabGame('en_celebrate', enCelebrate, 'en_celebrate', ask: "Let's celebrate! What is this?",
    hint: (w) => 'The word is "$w".');

/// should / shouldn't للنصيحة.
const shouldSentences = [
  ('🧴', 'You ___ wear sunscreen at the beach.', 'should'),
  ('🐠', 'You ___ touch the corals.', "shouldn't"),
  ('💧', 'You ___ drink water when you hike.', 'should'),
  ('🗑️', 'You ___ leave trash on the beach.', "shouldn't"),
  ('🦺', 'You ___ wear a life jacket on the boat.', 'should'),
  ('🌊', 'You ___ swim alone in the sea.', "shouldn't"),
];

Question enShould(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(shouldSentences);
  return _enBlank('en_should', 'en_should:$answer', pic, sentence, answer, ['should', "shouldn't"], r,
      hint: "should = a good idea. shouldn't = a bad idea.");
}

// ================================================================ Connect 5 (خامسة)

/// (الأيام، الجملة، الإجابة) — علامة لكل يوم في الأسبوع: ✔ عمله، ✖ ماعملوش.
const frequencySentences = [
  ('✔✔✔✔✔✔✔', 'I ___ brush my teeth before bed.', 'always'),
  ('✔✔✔✔✔✔✖', 'She ___ walks to school.', 'usually'),
  ('✔✖✔✖✖✔✖', 'We ___ eat pizza.', 'sometimes'),
  ('✖✖✖✖✖✖✖', 'He ___ drinks soda.', 'never'),
  ('✔✔✔✔✔✔✔', 'My dad ___ reads the news.', 'always'),
  ('✖✔✖✖✔✖✖', 'They ___ play chess.', 'sometimes'),
];

Question enFrequency(int lv, Rng r, {String? focus}) {
  final (days, sentence, answer) = r.sample(frequencySentences);
  return Question(
    type: 'en_frequency', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_freq:$answer',
    ask: 'Choose the right word', speak: 'Choose the right word.',
    visuals: [CaptionVisual('This week: $days'), WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle(['always', 'usually', 'sometimes', 'never']), answer: answer,
    hint: 'every day = always, most days = usually, some days = sometimes, no days = never.',
    speakHint: 'Every day is always. No days is never.',
    sayRight: sentence.replaceFirst('___', answer),
  );
}

const someAnySentences = [
  ('🥛', 'There is ___ milk in the fridge.', 'some'), ('🍎', 'Are there ___ apples?', 'any'),
  ('🥚', "There aren't ___ eggs.", 'any'), ('🍪', 'I have ___ cookies.', 'some'),
  ('🧀', 'Is there ___ cheese?', 'any'), ('🍞', 'We need ___ bread.', 'some'),
];

Question enSomeAny(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(someAnySentences);
  return _enBlank('en_someAny', 'en_someAny:$answer', pic, sentence, answer, ['some', 'any'], r,
      hint: 'some in positive sentences. any in questions and negatives.');
}

const didSentences = [
  ('___ you play football yesterday?', 'Did', ['Did', 'Do', 'Does']),
  ('___ she visit her grandma last week?', 'Did', ['Did', 'Do', 'Does']),
  ('He ___ go to school yesterday. He was sick.', "didn't", ["didn't", "doesn't", "don't"]),
  ('We ___ watch TV last night.', "didn't", ["didn't", "doesn't", "don't"]),
  ('Where ___ they go last summer?', 'did', ['did', 'do', 'does']),
  ('What ___ you eat yesterday?', 'did', ['did', 'do', 'does']),
];

Question enDid(int lv, Rng r, {String? focus}) {
  final (sentence, answer, choices) = r.sample(didSentences);
  return _enBlank('en_did', 'en_did:${answer.toLowerCase()}', null, sentence, answer, choices, r,
      hint: "yesterday, last week = past: Did …? / didn't.");
}

const timePrepSentences = [
  ('My birthday is ___ July.', 'in'), ('We have English ___ Monday.', 'on'), ("School starts ___ 8 o'clock.", 'at'),
  ('It is cold ___ winter.', 'in'), ('I sleep ___ night.', 'at'), ('The party is ___ Friday.', 'on'),
  ('He was born ___ 2015.', 'in'),
];

Question enInOnAt(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = r.sample(timePrepSentences);
  return _enBlank('en_inOnAt', 'en_time:$answer', null, sentence, answer, ['in', 'on', 'at'], r,
      hint: 'in + month, season, year. on + day. at + time.');
}

const couldSentences = [
  ('👶', 'When I was a baby, I ___ walk.', "couldn't", ['could', "couldn't"]),
  ('🏊', 'I learned to swim last year. Now I ___ swim.', 'can', ['can', "can't"]),
  ('🚲', 'At five, she ___ ride a bike. She learned at four.', 'could', ['could', "couldn't"]),
  ('🐧', 'A penguin ___ fly.', "can't", ['can', "can't"]),
  ('📖', 'At three, he ___ read. He was too young.', "couldn't", ['could', "couldn't"]),
  ('🎹', 'My sister plays every day. She ___ play the piano very well.', 'can', ['can', "can't"]),
];

Question enCould(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer, choices) = r.sample(couldSentences);
  return _enBlank('en_could', 'en_could:$answer', pic, sentence, answer, choices, r,
      hint: 'can / can\'t = now. could / couldn\'t = in the past.');
}

const haveToSentences = [
  ('🏫', 'She ___ wear a uniform at school.', 'has to'), ('🦷', 'I ___ brush my teeth every day.', 'have to'),
  ('🩺', 'He ___ see a doctor. He is sick.', 'has to'), ('📚', 'We ___ do our homework.', 'have to'),
  ('🐶', 'My brother ___ walk the dog.', 'has to'), ('🤫', 'They ___ be quiet in the library.', 'have to'),
];

Question enHaveTo(int lv, Rng r, {String? focus}) {
  final (pic, sentence, answer) = r.sample(haveToSentences);
  return _enBlank('en_haveTo', 'en_haveTo:$answer', pic, sentence, answer, ['have to', 'has to'], r,
      hint: 'he / she / it → has to. I / you / we / they → have to.');
}

const goingToSentences = [
  ('Tomorrow I ___ visit my grandma.', 'am going to'), ('Next week they ___ travel to Luxor.', 'are going to'),
  ('He ___ play football this evening.', 'is going to'), ('We ___ camp at the beach.', 'are going to'),
  ('She ___ pack her suitcase.', 'is going to'),
];

Question enGoingTo(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = r.sample(goingToSentences);
  return _enBlank('en_goingTo', 'en_goingTo:${answer.split(' ').first}', null, sentence, answer,
      ['am going to', 'is going to', 'are going to'], r,
      hint: 'I am going to. He / she is going to. We / they are going to.');
}

const continuousSentences = [
  ('Look! The baby ___.', 'is sleeping', ['sleeps', 'is sleeping']),
  ('Every morning, she ___ milk.', 'drinks', ['drinks', 'is drinking']),
  ('Listen! Someone ___ the piano.', 'is playing', ['plays', 'is playing']),
  ('My dad ___ to work every day.', 'goes', ['goes', 'is going']),
  ('Right now, we ___ English.', 'are studying', ['study', 'are studying']),
  ('Owls ___ at night.', 'hunt', ['hunt', 'are hunting']),
];

Question enContinuous(int lv, Rng r, {String? focus}) {
  final pool = continuousSentences.where((s) =>
      focus == 'continuous' ? s.$2.contains(' ') : focus == 'simple' ? !s.$2.contains(' ') : true).toList();
  final (sentence, answer, choices) = r.sample(pool);
  return _enBlank('en_continuous', 'en_cont:${answer.contains(' ') ? 'cont' : 'simple'}', null, sentence, answer, choices, r,
      hint: 'every day, always = present simple. now, look, listen = am / is / are + -ing.');
}

const enHealth = [
  Word('headache', '🤕'), Word('fever', '🤒'), Word('medicine', '💊'), Word('bandage', '🩹'), Word('thermometer', '🌡️'),
  Word('injection', '💉'), Word('ambulance', '🚑'), Word('tooth', '🦷'),
];
final enHealthGame = vocabGame('en_health', enHealth, 'en_health', ask: 'At the doctor\'s. What is this?',
    hint: (w) => 'The word is "$w".');

const enSpace = [
  Word('moon', '🌙'), Word('Earth', '🌍'), Word('star', '⭐'), Word('rocket', '🚀'), Word('astronaut', '🧑‍🚀'),
  Word('planet', '🪐'), Word('comet', '☄️'), Word('galaxy', '🌌'), Word('alien', '👽'),
];
final enSpaceGame = vocabGame('en_space', enSpace, 'en_space', ask: 'Our solar system. What is this?', hint: (w) => 'The word is "$w".');

const enNature = [
  Word('storm', '⛈️'), Word('tornado', '🌪️'), Word('wildfire', '🔥'), Word('flood', '🌊'), Word('lightning', '⚡'),
  Word('rainbow', '🌈'), Word('volcano', '🌋'), Word('drought', '🌵'),
];
final enNatureGame = vocabGame('en_nature', enNature, 'en_nature', ask: 'When nature changes. What is this?',
    hint: (w) => 'The word is "$w".');

const enHobbies = [
  Word('painting', '🎨'), Word('cycling', '🚴'), Word('chess', '♟️'), Word('piano', '🎹'), Word('photography', '📷'),
  Word('gardening', '🪴'), Word('board games', '🎲'), Word('skating', '⛸️'),
];
final enHobbiesGame = vocabGame('en_hobbies', enHobbies, 'en_hobby', ask: 'What is the hobby?', hint: (w) => 'The hobby is $w.');

// ================================================================ Connect 6 (سادسة)

const ableToSentences = [
  ('I ___ swim very fast.', 'am able to'), ('She ___ speak three languages.', 'is able to'),
  ('They ___ fix the car.', 'are able to'), ('The paramedic ___ help people quickly.', 'is able to'),
  ('We ___ build a robot.', 'are able to'),
];

Question enAbleTo(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = r.sample(ableToSentences);
  return _enBlank('en_ableTo', 'en_ableTo:${answer.split(' ').first}', null, sentence, answer,
      ['am able to', 'is able to', 'are able to'], r, hint: 'I am able to. He / she is able to. We / they are able to.');
}

/// either…or، both…and، neither…nor.
const pairSentences = [
  ('You can have ___ tea or juice.', 'either', ['either', 'both', 'neither']),
  ('___ Ali and Omar like painting.', 'Both', ['Both', 'Either', 'Neither']),
  ('___ my mom nor my dad likes coffee.', 'Neither', ['Neither', 'Both', 'Either']),
  ('We will go ___ to the museum or to the zoo.', 'either', ['either', 'both', 'neither']),
  ('She is ___ talented and kind.', 'both', ['both', 'either', 'neither']),
  ('He ___ sings nor dances.', 'neither', ['neither', 'both', 'either']),
];

Question enBothEither(int lv, Rng r, {String? focus}) {
  final (sentence, answer, choices) = r.sample(pairSentences);
  return _enBlank('en_bothEither', 'en_pairs:${answer.toLowerCase()}', null, sentence, answer, choices, r,
      hint: 'both … and = the two. either … or = one of the two. neither … nor = not this and not that.');
}

const whoWhichSentences = [
  ('The man ___ invented the clock was clever.', 'who'), ('This is the gadget ___ tells the time.', 'which'),
  ('She is the artist ___ painting won.', 'whose'), ('I met a girl ___ loves sculpture.', 'who'),
  ('The museum ___ we visited was huge.', 'which'), ('He is the boy ___ bike is red.', 'whose'),
];

Question enWhoWhich(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = r.sample(whoWhichSentences);
  return _enBlank('en_whoWhich', 'en_relPron:$answer', null, sentence, answer, ['who', 'which', 'whose'], r,
      hint: 'who = a person. which = a thing. whose = belongs to.');
}

const presentPerfectSentences = [
  ('I ___ visited Luxor three times.', 'have', ['have', 'has']),
  ('She ___ finished her homework.', 'has', ['have', 'has']),
  ('They ___ discovered a new tomb.', 'have', ['have', 'has']),
  ('___ you ever seen a mummy?', 'Have', ['Have', 'Has']),
  ('He ___ never been to Aswan.', 'has', ['have', 'has']),
  ('We ___ just eaten lunch.', 'have', ['have', 'has']),
];

Question enPresentPerfect(int lv, Rng r, {String? focus}) {
  final (sentence, answer, choices) = r.sample(presentPerfectSentences);
  return _enBlank('en_presentPerfect', 'en_pp:${answer.toLowerCase()}', null, sentence, answer, choices, r,
      hint: 'I / you / we / they have + done. He / she / it has + done.');
}

const usedToSentences = [
  ('My grandpa ___ travel by train, but now he drives.', 'used to', ['used to', "didn't use to"]),
  ('People ___ have phones long ago.', "didn't use to", ['used to', "didn't use to"]),
  ('Egypt ___ make cloth by hand.', 'used to', ['used to', "didn't use to"]),
  ('___ you use to play outside?', 'Did', ['Did', 'Do']),
  ('We ___ have electric buses, but now we do.', "didn't use to", ['used to', "didn't use to"]),
];

Question enUsedTo(int lv, Rng r, {String? focus}) {
  final (sentence, answer, choices) = r.sample(usedToSentences);
  return _enBlank('en_usedTo', 'en_usedTo:$answer', null, sentence, answer, choices, r,
      hint: 'used to = something in the past that is not true now.');
}

const conditionalSentences = [
  ('If it rains, we ___ stay at home.', 'will', ['will', 'are']),
  ('If you take the metro, you ___ arrive early.', 'will', ['will', 'did']),
  ('If she ___ hard, she will pass.', 'studies', ['studies', 'will study']),
  ('If we ___ the bus, we will be late.', 'miss', ['miss', 'will miss']),
  ('You will feel better if you ___ water.', 'drink', ['drink', 'will drink']),
];

Question enConditional(int lv, Rng r, {String? focus}) {
  final (sentence, answer, choices) = r.sample(conditionalSentences);
  return _enBlank('en_conditional', 'en_if:${answer == 'will' ? 'result' : 'if'}', null, sentence, answer, choices, r,
      hint: 'If + present simple, … will + verb.');
}

const enCommunityJobs = [
  Word('paramedic', '🚑'), Word('architect', '📐'), Word('mechanic', '🔧'), Word('tailor', '🧵'),
  Word('delivery worker', '🛵'), Word('street cleaner', '🧹'), Word('traffic officer', '🚦'), Word('water engineer', '🚰'),
];
final enCommunityJobsGame = vocabGame('en_jobs6', enCommunityJobs, 'en_job6', ask: 'Community builders. Who uses this?',
    hint: (w) => 'This is for a $w.');

const enTravel = [
  Word('passport', '🛂'), Word('luggage', '🧳'), Word('ticket', '🎫'), Word('map', '🗺️'), Word('tent', '⛺'),
  Word('cable car', '🚡'), Word('elevator', '🛗'), Word('monorail', '🚝'), Word('metro', '🚇'),
];
final enTravelGame = vocabGame('en_travel', enTravel, 'en_travel', ask: 'Travel and transport. What is this?',
    hint: (w) => 'The word is "$w".');

const enArt = [
  Word('canvas', '🖼️'), Word('paintbrush', '🖌️'), Word('palette', '🎨'), Word('sculpture', '🗿'),
  Word('sketch', '✏️'), Word('museum', '🏛️'),
];
final enArtGame = vocabGame('en_art', enArt, 'en_art', ask: 'Art and artists. What is this?', hint: (w) => 'The word is "$w".');

const enHeritage = [
  Word('papyrus', '📜'), Word('bricks', '🧱'), Word('gold', '🪙'), Word('clay', '🏺'), Word('stone', '🪨'),
  Word('temple', '🛕'), Word('amulet', '🧿'),
];
final enHeritageGame = vocabGame('en_heritage', enHeritage, 'en_heritage', ask: 'Made in Egypt. What is this?',
    hint: (w) => 'The word is "$w".');
