/// مولّدات السكون والتنوين (أولى ابتدائي، الترم التاني).
///
/// التنوين: بٌ بٍ بًا — تنوين الفتح بيتكتب بألف بعده (حروفنا مفيهاش ة ولا ء).
/// السكون: كلمات مشكولة كاملة فيها حرف ساكن واحد في النص وتنوين ضم في الآخر (كَلْبٌ).
/// المقاطع والكلمات بتتسجّل مشكولة زي ما هي، والحرف الساكن لوحده بيتنطق باسمه ("لام ساكنة").
library;

import '../../content/language_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';
import 'arabic_generators.dart' show arPool;
import 'harakat_generators.dart' show harakat;

/// (العلامة، اسمها).
const tanweens = [('ً', 'تنوين فتح'), ('ٌ', 'تنوين ضم'), ('ٍ', 'تنوين كسر')];

/// المقطع بالتنوين: بًا (بألف)، بٌ، بٍ.
String tanweenSyl(String letter, String mark) => mark == 'ً' ? '$letterًا' : '$letter$mark';

/// كل حركة وتنوينها: فتحة ↔ تنوين فتح… عشان المشتت الأقرب يبقى موجود.
const _pairs = {'فتحة': 'تنوين فتح', 'ضمة': 'تنوين ضم', 'كسرة': 'تنوين كسر'};

List<Letter> _pool(int lv) => arPool(lv).where((l) => l.letter != 'أ').toList();

const _tanweenHint = 'التنوين علامتين: فتحتين، أو ضمتين، أو كسرتين ☝️';

/// ١ — اسم التنوين: بٌ ← تنوين ضم.
Question arTanween(int lv, Rng r, {String? focus}) {
  final l = r.sample(_pool(lv));
  final (mark, name) = tanweens.where((t) => t.$2 == focus).firstOrNull ?? r.sample(tanweens);
  final syl = tanweenSyl(l.letter, mark);
  return Question(
    type: 'ar_tanween', mode: QMode.choice, skill: 'tanween:$name', numeric: false, wide: true,
    ask: 'إيه نوع التنوين؟',
    speak: 'إيه نوع التنوين؟',
    visuals: [BigLetterVisual(syl)],
    choices: r.shuffle([for (final t in tanweens) t.$2]),
    answer: name,
    hint: _tanweenHint,
    sayRight: syl,
  );
}

/// ٢ — حركة ولا تنوين؟ العلامة على الحرف من الست (فتحة … تنوين كسر)، ومعاها أختها دايمًا.
Question arMarks(int lv, Rng r, {String? focus}) {
  final l = r.sample(_pool(lv));
  final all = [...harakat, ...tanweens];
  final (mark, name) = r.sample(all);
  final isTanween = tanweens.any((t) => t.$1 == mark);
  final syl = isTanween ? tanweenSyl(l.letter, mark) : '${l.letter}$mark';
  final sister = isTanween ? _pairs.entries.firstWhere((e) => e.value == name).key : _pairs[name]!;
  final others = r.shuffle([for (final (_, n) in all) if (n != name && n != sister) n]);
  return Question(
    type: 'ar_marks', mode: QMode.choice, skill: 'mark:$name', numeric: false, wide: true,
    ask: 'إيه العلامة اللي على الحرف؟',
    speak: 'إيه العلامة اللي على الحرف؟',
    visuals: [BigLetterVisual(syl)],
    choices: r.shuffle([name, sister, ...others.take(lv <= 2 ? 1 : 2)]),
    answer: name,
    hint: 'علامة واحدة = حركة (فتحة أو ضمة أو كسرة). علامتين = تنوين ☝️',
    sayRight: syl,
  );
}

class SukunWord {
  const SukunWord(this.word, this.emoji);

  /// مشكولة كاملة: حرف ساكن واحد، وتنوين في الآخر.
  final String word;
  final String emoji;

  /// كل حرف بعلاماته: كَلْبٌ ← كَ، لْ، بٌ.
  List<String> get parts {
    final out = <String>[];
    for (final ch in word.split('')) {
      final mark = ch.codeUnitAt(0) >= 0x064B && ch.codeUnitAt(0) <= 0x0652;
      if (mark && out.isNotEmpty) {
        out.last += ch;
      } else {
        out.add(ch);
      }
    }
    return out;
  }

  String get sakin => parts.singleWhere((p) => p.endsWith('ْ'));
}

/// الكلمات اللي فيها سكون — مشكولة على الطريقة اللي في كتب أولى ابتدائي (اسم نكرة مرفوع).
const sukunWords = [
  SukunWord('كَلْبٌ', '🐕'), SukunWord('بَحْرٌ', '🌊'), SukunWord('شَمْسٌ', '☀️'),
  SukunWord('قِرْدٌ', '🐒'), SukunWord('نَهْرٌ', '🏞️'), SukunWord('بَيْتٌ', '🏠'),
  SukunWord('بِنْتٌ', '👧'), SukunWord('قَلْبٌ', '❤️'), SukunWord('صَقْرٌ', '🦅'),
  SukunWord('خُبْزٌ', '🍞'), SukunWord('زَهْرَةٌ', '🌸'), SukunWord('وَرْدَةٌ', '🌹'),
  SukunWord('مَلْعَبٌ', '🏟️'), SukunWord('ثَعْلَبٌ', '🦊'), SukunWord('أَرْنَبٌ', '🐇'),
];

Map<String, String> get _letterNames => {for (final l in arLetters) l.letter: l.name!};

/// ٣ — فين الحرف الساكن؟ الكلمة مشكولة، والطفل يختار الحرف اللي عليه سكون.
Question arSukun(int lv, Rng r, {String? focus}) {
  final pool = lv <= 2 ? sukunWords.where((w) => w.parts.length == 3).toList() : sukunWords;
  final w = pool.where((x) => x.word == focus).firstOrNull ?? r.sample<SukunWord>(pool);
  final parts = w.parts;
  final sakin = w.sakin;
  return Question(
    type: 'ar_sukun', mode: QMode.choice, skill: 'sukun:${w.word}', numeric: false, bigChoices: true,
    ask: 'فين الحرف الساكن؟',
    speak: 'فين الحرف الساكن؟',
    visuals: [PicsVisual(w.emoji, 1), WordLineVisual.text(w.word, big: true)],
    choices: r.shuffle([...parts]),
    answer: sakin,
    // الحرف الساكن لوحده مالوش صوت واضح، فبيتنطق باسمه
    choiceSay: {sakin: '${_letterNames[sakin[0]] ?? sakin[0]} ساكنة'},
    hint: 'السكون دايرة صغيرة فوق الحرف (ْ) — الحرف الساكن مالوش حركة 🔵',
    sayRight: w.word,
  );
}

/// ٤ — اسمع واختار التنوين (محتاجة الصوت). من المستوى التالت: حرف تاني بنفس التنوين كمان.
Question arTanweenListen(int lv, Rng r, {String? focus}) {
  final pool = _pool(lv);
  final l = r.sample(pool);
  final (mark, name) = r.sample(tanweens);
  final syl = tanweenSyl(l.letter, mark);
  final other = r.sample(pool.where((x) => x.letter != l.letter).toList());
  return Question(
    type: 'ar_tanween_listen', mode: QMode.choice, skill: 'tanween_listen:$name', numeric: false, bigChoices: true,
    ask: 'اسمع المقطع كويس… واختاره 👂',
    speak: syl,
    clips: [say(syl)],
    visuals: [ListenVisual(syl)],
    choices: r.shuffle([
      for (final (m, _) in tanweens) tanweenSyl(l.letter, m),
      if (lv >= 3) tanweenSyl(other.letter, mark),
    ]),
    answer: syl,
    hint: 'اضغط 🔊 واسمع تاني: آخر المقطع "ـن" — بص على العلامتين',
    speakHint: 'اسمع تاني بالراحة',
    sayRight: syl,
  );
}
