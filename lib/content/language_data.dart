/// بيانات عالمي العربي و English — منقولة من data/arabic.js و data/english.js.
library;

class Letter {
  const Letter(this.letter, this.word, this.emoji, [this.name]);
  final String letter;
  final String word;
  final String emoji;
  final String? name;
}

class Word {
  const Word(this.word, this.emoji);
  final String word;
  final String emoji;
}

const arLetters = [
  Letter('أ', 'أسد', '🦁', 'ألف'), Letter('ب', 'بطة', '🦆', 'باء'),
  Letter('ت', 'تفاحة', '🍎', 'تاء'), Letter('ث', 'ثعلب', '🦊', 'ثاء'),
  Letter('ج', 'جمل', '🐪', 'جيم'), Letter('ح', 'حصان', '🐴', 'حاء'),
  Letter('خ', 'خروف', '🐑', 'خاء'), Letter('د', 'دب', '🐻', 'دال'),
  Letter('ذ', 'ذرة', '🌽', 'ذال'), Letter('ر', 'ريشة', '🪶', 'راء'),
  Letter('ز', 'زرافة', '🦒', 'زاي'), Letter('س', 'سمكة', '🐟', 'سين'),
  Letter('ش', 'شمس', '☀️', 'شين'), Letter('ص', 'صاروخ', '🚀', 'صاد'),
  Letter('ض', 'ضفدع', '🐸', 'ضاد'), Letter('ط', 'طائرة', '✈️', 'طاء'),
  Letter('ظ', 'ظرف', '✉️', 'ظاء'), Letter('ع', 'عنب', '🍇', 'عين'),
  Letter('غ', 'غيمة', '☁️', 'غين'), Letter('ف', 'فيل', '🐘', 'فاء'),
  Letter('ق', 'قطة', '🐱', 'قاف'), Letter('ك', 'كتاب', '📚', 'كاف'),
  Letter('ل', 'ليمونة', '🍋', 'لام'), Letter('م', 'موزة', '🍌', 'ميم'),
  Letter('ن', 'نحلة', '🐝', 'نون'), Letter('ه', 'هدية', '🎁', 'هاء'),
  Letter('و', 'وردة', '🌹', 'واو'), Letter('ي', 'يد', '✋', 'ياء'),
];

/// كلمات بسيطة للقراءة والتكوين.
const arWords = [
  Word('باب', '🚪'), Word('قمر', '🌙'), Word('شمس', '☀️'), Word('وردة', '🌹'),
  Word('بيت', '🏠'), Word('قلم', '✏️'), Word('كتاب', '📚'), Word('سمكة', '🐟'),
  Word('جمل', '🐪'), Word('نحلة', '🐝'), Word('تفاح', '🍎'), Word('موز', '🍌'),
  Word('عنب', '🍇'), Word('حليب', '🥛'), Word('ماء', '💧'), Word('سيارة', '🚗'),
  Word('طائرة', '✈️'), Word('مفتاح', '🔑'), Word('ساعة', '⌚'), Word('فيل', '🐘'),
];

const enLetters = [
  Letter('A', 'Apple', '🍎'), Letter('B', 'Ball', '⚽'), Letter('C', 'Cat', '🐱'),
  Letter('D', 'Dog', '🐶'), Letter('E', 'Elephant', '🐘'), Letter('F', 'Fish', '🐟'),
  Letter('G', 'Giraffe', '🦒'), Letter('H', 'House', '🏠'), Letter('I', 'Ice cream', '🍦'),
  Letter('J', 'Juice', '🧃'), Letter('K', 'Kite', '🪁'), Letter('L', 'Lion', '🦁'),
  Letter('M', 'Moon', '🌙'), Letter('N', 'Nose', '👃'), Letter('O', 'Orange', '🍊'),
  Letter('P', 'Pizza', '🍕'), Letter('Q', 'Queen', '👑'), Letter('R', 'Rainbow', '🌈'),
  Letter('S', 'Sun', '☀️'), Letter('T', 'Tree', '🌳'), Letter('U', 'Umbrella', '☂️'),
  Letter('V', 'Violin', '🎻'), Letter('W', 'Watch', '⌚'), Letter('X', 'Xylophone', '🎹'),
  Letter('Y', 'Yacht', '⛵'), Letter('Z', 'Zebra', '🦓'),
];

const enNumbers = [
  Word('One', '1️⃣'), Word('Two', '2️⃣'), Word('Three', '3️⃣'), Word('Four', '4️⃣'),
  Word('Five', '5️⃣'), Word('Six', '6️⃣'), Word('Seven', '7️⃣'), Word('Eight', '8️⃣'),
  Word('Nine', '9️⃣'), Word('Ten', '🔟'),
];

const enColors = [
  Word('Red', '🔴'), Word('Blue', '🔵'), Word('Green', '🟢'), Word('Yellow', '🟡'),
  Word('Orange', '🟠'), Word('Purple', '🟣'), Word('Black', '⚫'), Word('White', '⚪'),
  Word('Brown', '🟤'), Word('Pink', '🩷'),
];

const enAnimals = [
  Word('Cat', '🐱'), Word('Dog', '🐶'), Word('Lion', '🦁'), Word('Elephant', '🐘'),
  Word('Monkey', '🐵'), Word('Bird', '🐦'), Word('Fish', '🐟'), Word('Horse', '🐴'),
  Word('Cow', '🐮'), Word('Sheep', '🐑'), Word('Duck', '🦆'), Word('Bear', '🐻'),
];

const enDaily = [
  Word('Hello', '👋'), Word('Water', '💧'), Word('Food', '🍽️'), Word('School', '🏫'),
  Word('Book', '📚'), Word('Car', '🚗'), Word('Home', '🏠'), Word('Mother', '👩'),
  Word('Father', '👨'), Word('Friend', '🧒'), Word('Sleep', '😴'), Word('Happy', '😊'),
];
