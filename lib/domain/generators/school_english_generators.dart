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
