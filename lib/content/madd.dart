/// أنواع بيانات قسم المدود — البيانات نفسها في madd_data.g.dart (من data/madd.js في الويب).
library;

export 'madd_data.g.dart';

class MaddType {
  const MaddType({
    required this.key,
    required this.name,
    required this.box,
    required this.baseLetter,
    required this.maddLetter,
    required this.result,
    required this.harakaName,
    required this.harakaWord,
    required this.harakaMark,
    required this.letterName,
    required this.letterWord,
    required this.rule,
    required this.examples,
  });

  /// alif / waw / yaa
  final String key;
  final String name;

  /// مربّع اللون (🟦 🟩 🟨) — اللون + الشكل، مش اللون لوحده.
  final String box;
  final String baseLetter, maddLetter, result;
  final String harakaName, harakaWord, harakaMark;
  final String letterName, letterWord;
  final String rule;

  /// مقاطع زي بَا مَا سَا — المد دايمًا آخر حرف.
  final List<String> examples;

  String get label => '$box $name';
}

class MaddWord {
  const MaddWord({
    required this.plain,
    required this.w,
    required this.type,
    required this.madd,
    required this.parts,
    required this.e,
    required this.pic,
    required this.lvl,
  });

  /// الكلمة من غير تشكيل — مفتاح الإتقان.
  final String plain;

  /// الكلمة مشكولة.
  final String w;
  final String type;

  /// المقطع الممدود جوه الكلمة.
  final String madd;

  /// مقاطع الكلمة بالترتيب من اليمين.
  final List<String> parts;
  final String e;

  /// الصورة واضحة بما يكفي لمطابقتها بالكلمة.
  final bool pic;
  final int lvl;
}
