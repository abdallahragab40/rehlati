/// English للابتدائي: قراءة كلمات CVC، و a / an، والجمع (أولى لتالتة)، وبعدين is / are،
/// وأدوات السؤال، وتكملة الجملة (رابعة لسادسة). النطق بصوت الجهاز الإنجليزي (lang: 'en').
///
/// القوايم كلمات مشهورة من غير استثناءات صعبة (hour، unicorn)؛ الشاذ في الجمع من المستوى الرابع بس.
library;

import '../../core/utils/rng.dart';
import '../question.dart';

T _focused<T>(List<T> pool, Rng r, String? focus, String Function(T) key) =>
    pool.where((x) => key(x) == focus).firstOrNull ?? r.sample<T>(pool);

/// (الكلمة، الصورة، كلمات حقيقية بتفرق عنها في صوت واحد).
const cvcWords = [
  ('cat', '🐱', ['cut', 'cot', 'cap']), ('dog', '🐶', ['dig', 'dot', 'log']), ('pig', '🐷', ['peg', 'big', 'pin']),
  ('sun', '☀️', ['sum', 'run', 'bun']), ('bus', '🚌', ['bun', 'but', 'bug']), ('hat', '🎩', ['hit', 'hot', 'ham']),
  ('bed', '🛏️', ['bad', 'bud', 'red']), ('fox', '🦊', ['fix', 'box', 'fog']), ('cup', '☕', ['cap', 'cop', 'pup']),
  ('net', '🥅', ['nut', 'not', 'pet']), ('map', '🗺️', ['mop', 'cap', 'man']), ('bat', '🦇', ['bet', 'but', 'bag']),
  ('van', '🚐', ['fan', 'pan', 'man']), ('hen', '🐔', ['ten', 'pen', 'men']),
];

/// ١ — Read the word: الصورة والطفل يختار كلمتها من كلمات بتفرق في صوت واحد.
Question enCvc(int lv, Rng r, {String? focus}) {
  final (word, emoji, near) = _focused(cvcWords, r, focus, (w) => w.$1);
  return Question(
    type: 'en_cvc', mode: QMode.choice, lang: 'en', ltr: true, wide: true, numeric: false, skill: 'en_cvc:$word',
    ask: 'Which word is it?', speak: 'Look at the picture. Which word is it?',
    visuals: [PicsVisual(emoji, 1, big: true)],
    choices: r.shuffle([word, ...r.shuffle([...near]).take(lv <= 2 ? 2 : 3)]),
    answer: word,
    hint: 'Say each sound: ${word.split('').join(' - ')}',
    speakHint: 'Say each sound slowly',
    sayRight: word,
  );
}

/// (الاسم، الصورة) — "an" قبل صوت حرف متحرك، و"a" قبل الباقي.
const anNouns = [
  ('apple', '🍎'), ('egg', '🥚'), ('orange', '🍊'), ('umbrella', '☂️'), ('ice cream', '🍦'), ('owl', '🦉'),
  ('elephant', '🐘'), ('ant', '🐜'),
];
const aNouns = [
  ('ball', '⚽'), ('cat', '🐱'), ('banana', '🍌'), ('book', '📚'), ('dog', '🐶'), ('kite', '🪁'), ('pen', '🖊️'), ('car', '🚗'),
];

/// ٢ — a or an?
Question enAAn(int lv, Rng r, {String? focus}) {
  final an = r.chance(.5);
  final (noun, emoji) = r.sample(an ? anNouns : aNouns);
  final article = an ? 'an' : 'a';
  return Question(
    type: 'en_a_an', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_a_an:$article',
    ask: 'a or an?', speak: 'Is it a or an?',
    visuals: [PicsVisual(emoji, 1), CaptionVisual('___ $noun')],
    choices: const ['a', 'an'],
    answer: article,
    hint: 'Use "an" before a, e, i, o, u sounds: an apple. Use "a" before other sounds: a ball.',
    speakHint: 'Use an before a vowel sound',
    sayRight: '$article $noun',
  );
}

/// (مفرد، جمع، الصورة، المستوى اللي بيظهر منه، جمع غلط مشهور).
const plurals = [
  ('cat', 'cats', '🐱', 1, 'cates'), ('dog', 'dogs', '🐶', 1, 'doges'), ('ball', 'balls', '⚽', 1, 'balles'),
  ('book', 'books', '📚', 1, 'bookes'), ('apple', 'apples', '🍎', 1, 'applees'), ('pen', 'pens', '🖊️', 1, 'penes'),
  ('box', 'boxes', '📦', 2, 'boxs'), ('bus', 'buses', '🚌', 2, 'buss'), ('fox', 'foxes', '🦊', 2, 'foxs'),
  ('watch', 'watches', '⌚', 2, 'watchs'),
  ('baby', 'babies', '👶', 3, 'babys'), ('cherry', 'cherries', '🍒', 3, 'cherrys'),
  ('butterfly', 'butterflies', '🦋', 3, 'butterflys'),
  ('child', 'children', '🧒', 4, 'childs'), ('mouse', 'mice', '🐭', 4, 'mouses'), ('tooth', 'teeth', '🦷', 4, 'tooths'),
  ('foot', 'feet', '🦶', 4, 'foots'),
];

const _countWords = ['two', 'three', 'four', 'five'];

/// ٣ — One or many? صور كتير والطفل يختار الجمع الصح.
Question enPlural(int lv, Rng r, {String? focus}) {
  final pool = plurals.where((p) => p.$4 <= lv).toList();
  final (one, many, emoji, _, wrong) = _focused(pool, r, focus, (p) => p.$1);
  final n = r.rnd(2, 5);
  return Question(
    type: 'en_plural', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_plural:$one',
    ask: 'Choose the right word', speak: 'Look. Choose the right word.',
    visuals: [PicsVisual(emoji, n), CaptionVisual('${_countWords[n - 2]} ___')],
    choices: r.shuffle([many, one, wrong]),
    answer: many,
    hint: switch (many) {
      _ when many == '${one}s' => 'Add s: $one → $many',
      _ when many == '${one}es' => 'Add es after s, x, ch: $one → $many',
      _ when many.endsWith('ies') => 'Change y to ies: $one → $many',
      _ => 'This word is special: $one → $many',
    },
    speakHint: 'More than one',
    sayRight: '${_countWords[n - 2]} $many',
  );
}

/// (الجملة بخانة، الإجابة) — الفاعل مفرد أو جمع، و"I" مع am من المستوى التالت.
const isAreSentences = [
  ('The cat ___ black.', 'is'), ('The cats ___ black.', 'are'), ('My friends ___ happy.', 'are'),
  ('The apples ___ red.', 'are'), ('Ali ___ my brother.', 'is'), ('It ___ hot today.', 'is'),
  ('They ___ at school.', 'are'), ('The book ___ on the table.', 'is'), ('The birds ___ in the tree.', 'are'),
  ('My mother ___ a doctor.', 'is'), ('We ___ in the garden.', 'are'), ('The children ___ playing.', 'are'),
  ('I ___ ten years old.', 'am'), ('I ___ hungry.', 'am'),
];

/// ٤ — is, are or am?
Question enIsAre(int lv, Rng r, {String? focus}) {
  final pool = lv <= 2 ? isAreSentences.where((s) => s.$2 != 'am').toList() : isAreSentences;
  final (sentence, answer) = _focused(pool, r, focus, (s) => s.$1);
  return Question(
    type: 'en_isare', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true, skill: 'en_isare:$answer',
    ask: 'Complete the sentence', speak: 'Complete the sentence.',
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: lv <= 2 ? const ['is', 'are'] : const ['is', 'are', 'am'],
    answer: answer,
    hint: 'One → is. More than one → are. I → am.',
    speakHint: 'One is, many are, I am',
    sayRight: sentence.replaceFirst('___', answer),
  );
}

/// (السؤال بخانة، أداة السؤال).
const questionWords = [
  ('___ is your name?', 'What'), ('___ do you live?', 'Where'), ('___ old are you?', 'How'),
  ('___ is your teacher?', 'Who'), ('___ is your birthday?', 'When'), ('___ is the cat? It is under the table.', 'Where'),
  ('___ colour is the sky?', 'What'), ('___ are you sad? Because I lost my pen.', 'Why'),
  ('___ many apples do you have?', 'How'), ('___ is that boy? He is my brother.', 'Who'),
  ('___ do you go to school? At seven o\'clock.', 'When'), ('___ do you like milk? Because it is good.', 'Why'),
];

const _wh = ['What', 'Where', 'Who', 'When', 'Why', 'How'];

/// ٥ — Question words.
Question enQuestions(int lv, Rng r, {String? focus}) {
  final (q, answer) = _focused(questionWords, r, focus, (x) => x.$1);
  final others = r.shuffle([for (final w in _wh) if (w != answer) w]);
  return Question(
    type: 'en_questions', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true,
    skill: 'en_wh:$answer',
    ask: 'Choose the question word', speak: 'Choose the question word.',
    visuals: [WordLineVisual.text(q, big: true)],
    choices: r.shuffle([answer, ...others.take(lv <= 2 ? 2 : 3)]),
    answer: answer,
    hint: 'What = thing, Where = place, Who = person, When = time, Why = reason, How = way or number',
    speakHint: 'Think: a thing, a place, a person, a time, or a reason?',
    sayRight: q.replaceFirst('___', answer),
  );
}

/// (الجملة بخانة، الكلمة الصح، كلمتين غلط في المعنى).
const enBlankSentences = [
  ('I drink ___ every morning.', 'milk', ['chairs', 'pencils']),
  ('We read ___ at school.', 'books', ['shoes', 'apples']),
  ('Birds can ___.', 'fly', ['read', 'write']),
  ('I wash my hands with ___.', 'soap', ['bread', 'milk']),
  ('A fish lives in ___.', 'water', ['a tree', 'the sky']),
  ('I write with a ___.', 'pencil', ['banana', 'cup']),
  ('Cows give us ___.', 'milk', ['bread', 'juice']),
  ('In winter it is ___.', 'cold', ['hot', 'sweet']),
  ('My father drives a ___.', 'car', ['cake', 'book']),
  ('I see with my ___.', 'eyes', ['ears', 'feet']),
  ('We sleep at ___.', 'night', ['school', 'the beach']),
  ('The baby is crying because she is ___.', 'hungry', ['tall', 'blue']),
];

/// ٦ — Complete the sentence by meaning.
Question enSentence(int lv, Rng r, {String? focus}) {
  final (sentence, answer, wrong) = _focused(enBlankSentences, r, focus, (s) => s.$1);
  return Question(
    type: 'en_sentence', mode: QMode.choice, lang: 'en', ltr: true, numeric: false, bigChoices: true,
    skill: 'en_sentence:$sentence',
    ask: 'Complete the sentence', speak: 'Complete the sentence.',
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle([answer, ...wrong]),
    answer: answer,
    hint: 'Read the sentence with each word. Which one makes sense?',
    speakHint: 'Which one makes sense?',
    sayRight: sentence.replaceFirst('___', answer),
  );
}
