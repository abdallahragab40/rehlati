/// البيانات الثابتة لعالم الحساب — منقولة من js/data.js.
library;

class CountItem {
  const CountItem(this.emoji, this.question);
  final String emoji;
  final String question;
}

const countItems = [
  CountItem('🍎', 'كم تفاحة؟'), CountItem('🍌', 'كم موزة؟'),
  CountItem('🍓', 'كم فراولة؟'), CountItem('🎈', 'كم بالونة؟'),
  CountItem('🐥', 'كم كتكوت؟'), CountItem('🐟', 'كم سمكة؟'),
  CountItem('🍪', 'كم بسكويتة؟'), CountItem('🌸', 'كم وردة؟'),
  CountItem('🚗', 'كم سيارة؟'), CountItem('⭐', 'كم نجمة؟'),
];

class LevelSpec {
  const LevelSpec({required this.max, required this.sumMax, required this.steps, required this.choices});
  final int max;
  final int sumMax;
  final List<int> steps;
  final int choices;
}

/// حدود كل مستوى — لا يُولَّد أي سؤال خارجها.
const levels = {
  1: LevelSpec(max: 5, sumMax: 5, steps: [1], choices: 3),
  2: LevelSpec(max: 10, sumMax: 10, steps: [1], choices: 3),
  3: LevelSpec(max: 20, sumMax: 10, steps: [1], choices: 4),
  // العد بالاثنين يبدأ في المستوى الرابع بس، وبنسبة قليلة — طفل ٤–٦ سنين لسه بيثبّت العد بواحد
  4: LevelSpec(max: 20, sumMax: 20, steps: [1, 1, 1, 2], choices: 4),
};

LevelSpec levelSpec(int lv) => levels[lv.clamp(1, 4)]!;

const palette = [
  0xFFFF6B6B, 0xFF7A5CFF, 0xFF2FC9B4, 0xFFFF9F1C, 0xFF4CB8FF, 0xFF1FAE9B,
  0xFFE05FA8, 0xFF5FBF5F, 0xFFFFC43D, 0xFF6C7BFF, 0xFFFF7A59, 0xFF1FA9D6, 0xFFC06BE8,
];

const praise = ['ممتاز! 🎉', 'أحسنت! 🌟', 'رائع يا بطل! 👏', 'شاطر جدًا! 🦁'];

/// جُمل التشجيع المنطوقة ومفاتيح مقاطعها المسجّلة.
const praiseSay = [
  ('ممتاز يا بطل', 'praise1'),
  ('أحسنت', 'praise2'),
  ('شاطر جدًا', 'praise3'),
  ('برافو عليك', 'praise4'),
];

const retry = ['حاول مرة أخرى ❤️', 'قريب جدًا، جرّب تاني 💪', 'مش مشكلة، فكّر شوية 🙂'];

const questionsPerRound = 10;
const practiceCount = 5;
