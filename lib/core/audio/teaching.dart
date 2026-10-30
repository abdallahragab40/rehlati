/// مقاطع التعليم بالفصحى (tool/teaching.tsv): اسم الحرف، صوته بالحركات، وكلماته.
/// أي جزء جملة هو حرف لوحده أو مقطع (بَ) أو كلمة من كلمات التطبيق بيتنطق من هنا
/// بنطق مشكول — عشان ث وذ وظ وق والحركات يتسمعوا صح.
library;

import '../../content/language_data.dart';

/// مفتاح الحرف في tool/teaching.tsv (`l_<slug>_name` …).
const _slug = {
  'أ': 'alif', 'ب': 'ba', 'ت': 'ta', 'ث': 'tha', 'ج': 'jim', 'ح': 'ha', 'خ': 'kha',
  'د': 'dal', 'ذ': 'dhal', 'ر': 'ra', 'ز': 'zay', 'س': 'sin', 'ش': 'shin', 'ص': 'sad',
  'ض': 'dad', 'ط': 'taa', 'ظ': 'dha', 'ع': 'ayn', 'غ': 'ghayn', 'ف': 'fa', 'ق': 'qaf',
  'ك': 'kaf', 'ل': 'lam', 'م': 'mim', 'ن': 'nun', 'ه': 'haa', 'و': 'waw', 'ي': 'ya',
};

/// أشكال الألف كلها بتتنطق "ألف"، والهمزة على كرسي "همزة".
const _alias = {'ا': 'أ', 'إ': 'أ', 'آ': 'أ', 'ى': 'أ'};
const _extraNames = {'ء': 'l_hamza_name', 'ئ': 'l_hamza_name', 'ؤ': 'l_hamza_name', 'ة': 'l_tamarbuta_name'};

const _harakat = {'َ': 'fatha', 'ُ': 'damma', 'ِ': 'kasra'};
const _tanween = {'ً': 'tanween_fath', 'ٌ': 'tanween_damm', 'ٍ': 'tanween_kasr'};

/// كلمات السكون مشكولة كاملة بتنوينها — مقاطعها منفصلة عن كلمات القراءة بالوقف (شمس ≠ شَمْسٌ).
const sukunTeachingWords = {
  'كَلْبٌ': 'kalb', 'بَحْرٌ': 'bahr', 'شَمْسٌ': 'shams', 'قِرْدٌ': 'qird',
  'نَهْرٌ': 'nahr', 'بَيْتٌ': 'bayt', 'بِنْتٌ': 'bint', 'قَلْبٌ': 'qalb',
  'صَقْرٌ': 'saqr', 'خُبْزٌ': 'khubz', 'زَهْرَةٌ': 'zahra', 'وَرْدَةٌ': 'warda',
  'مَلْعَبٌ': 'malab', 'ثَعْلَبٌ': 'thalab', 'أَرْنَبٌ': 'arnab',
};

/// كلمات القراءة (arWords) ← مفاتيحها.
const _readingWords = {
  'باب': 'w_bab', 'قمر': 'w_qamar', 'شمس': 'w_shams', 'وردة': 'w_warda', 'بيت': 'w_bayt',
  'قلم': 'w_qalam', 'كتاب': 'w_kitab', 'سمكة': 'w_samaka', 'جمل': 'w_jamal', 'نحلة': 'w_nahla',
  'تفاح': 'w_tuffah', 'موز': 'w_mawz', 'عنب': 'w_inab', 'حليب': 'w_halib', 'ماء': 'w_maa',
  'سيارة': 'w_sayyara', 'طائرة': 'w_taira', 'مفتاح': 'w_miftah', 'ساعة': 'w_saa', 'فيل': 'w_fil',
};

String? _slugOf(String ch) => _slug[_alias[ch] ?? ch];

/// مقطع التعليم لجزء جملة، أو null لو مش حرف/مقطع/كلمة بنعلّمها.
String? teachKey(String part) {
  if (part.length == 1) {
    final s = _slugOf(part);
    return s != null ? 'l_${s}_name' : _extraNames[part];
  }
  if (part.length == 2 && _harakat.containsKey(part[1])) {
    final s = _slugOf(part[0]);
    if (s != null) return 'l_${s}_${_harakat[part[1]]}';
  }
  if (part.length == 2 || part.length == 3) {
    final mark = part[1];
    final s = _slugOf(part[0]);
    if (s != null && part[0] != 'أ' && _tanween.containsKey(mark) &&
        (mark == 'ً' ? part.length == 3 && part[2] == 'ا' : part.length == 2)) {
      return 'l_${s}_${_tanween[mark]}';
    }
  }
  if (part == 'ةٌ') return 'l_tamarbuta_tanween_damm';
  final word = sukunTeachingWords[part];
  if (word != null) return 'sukun_$word';
  if (part.endsWith(' ساكنة')) {
    final name = part.substring(0, part.length - ' ساكنة'.length);
    final letter = arLetters.where((l) => l.name == name).firstOrNull;
    if (letter != null) return 'l_${_slug[letter.letter]}_sakin_name';
  }
  return _pictureWords[part] ?? _readingWords[part];
}

final _pictureWords = {for (final l in arLetters) l.word: 'l_${_slug[l.letter]}_word'};

/// لوحة الحروف: الاسم وبعدين الكلمة — "باء … بطة". الحركات ليها مراحلها لوحدها.
List<String> letterLesson(Letter l) {
  final s = _slug[l.letter]!;
  return ['l_${s}_name', 'pause', 'l_${s}_word'];
}
