/// شكل السؤال الموحّد اللي كل المولّدات بترجّعه والمحرك بيفهمه.
///
/// في نسخة الويب كان `visual` نص HTML. هنا بقى بيانات مكتوبة (sealed classes)
/// والواجهة هي اللي بترسمها.
library;

enum QMode {
  /// اختار إجابة واحدة.
  choice,

  /// اضغط العناصر بالترتيب في خانات.
  order,

  /// املا خانات جدول (١–٢٠ أو الحروف) بالترتيب.
  grid,

  /// وصّل عمودين.
  pairs,

  /// لاقي كل تكرارات الحرف في الشبكة.
  find,

  /// لعبة ذاكرة — اقلب كارتين.
  memory,

  /// اقرأ وأكّد — مفيش إجابة غلط (المدود).
  read,

  /// صنّف البطاقات في صناديق (المدود).
  sort,

  /// بالونات طايرة — افرقع الصح (عالم الألعاب). الاختيارات = قيم البالونات.
  balloon,

  /// لوّن بالأرقام: اختار لون وبعدين الخانات اللي عليها رقمه.
  color,

  /// كرر الإيقاع: اسمع سلسلة الطبول وأعدها.
  rhythm,
}

/// شكل الاختيارات لو مش نص.
enum ChoiceLook {
  text,

  /// "circle|red" ← شكل ملوّن (الأشكال والألوان).
  shape,

  /// "3/4" ← كسر مرسوم البسط فوق المقام (مايتلخبطش في الكتابة من اليمين).
  fraction,
}

// ---------------------------------------------------------------------------
// المرئيات
// ---------------------------------------------------------------------------

sealed class Visual {
  const Visual();
}

/// صور متكررة للعد — `goneFrom` بيشطب الصور من الرقم ده وطالع (للطرح).
class PicsVisual extends Visual {
  const PicsVisual(this.emoji, this.count, {this.goneFrom, this.big = false});
  final String emoji;
  final int count;
  final int? goneFrom;
  final bool big;
}

/// تعبير رياضي أو تسلسل: بلاطات أرقام وعلامات — دايمًا من اليمين.
class ExprVisual extends Visual {
  const ExprVisual(this.parts, {this.fillFromPicked = false});
  final List<ExprPart> parts;

  /// وضع الترتيب: الخانات الفاضية نفسها بتتملا بإجابات الطفل بدل صف خانات منفصل.
  final bool fillFromPicked;
}

sealed class ExprPart {
  const ExprPart();
}

/// بلاطة رقم — `null` يعني خانة فاضية "؟".
class ExprTile extends ExprPart {
  const ExprTile(this.value, {this.mid = false});
  final Object? value;

  /// الرقم اللي في النص (السابق والتالي) — حدود بنفسجي.
  final bool mid;
}

/// خانة بعنوان صغير فوقها (السابق / الرقم / التالي).
class ExprCaption extends ExprPart {
  const ExprCaption(this.caption, this.inner);
  final String caption;
  final ExprPart inner;
}

class ExprOp extends ExprPart {
  const ExprOp(this.op, {this.separator = false});
  final String op;
  final bool separator;
}

/// مجموعة صور فوق رقمها (للجمع والمقارنة في المستويات الأولى).
class ExprSide extends ExprPart {
  const ExprSide(this.emoji, this.count, {this.number});
  final String emoji;
  final int count;
  final int? number;
}

class BigLetterVisual extends Visual {
  const BigLetterVisual(this.text);
  final String text;
}

/// سطر توضيحي صغير زي "؟ مثل أسد".
class CaptionVisual extends Visual {
  const CaptionVisual(this.text);
  final String text;
}

/// كلمة كاملة أو كلمة فيها حرف ناقص (`null` = الخانة الناقصة).
class WordLineVisual extends Visual {
  const WordLineVisual.text(String text, {this.big = false})
      : letters = null,
        word = text;
  const WordLineVisual.letters(List<String?> this.letters, {this.big = false}) : word = null;
  final String? word;
  final List<String?>? letters;
  final bool big;
}

/// حروف منفصلة بينها + (ك + ت + ب).
class LetterChipsVisual extends Visual {
  const LetterChipsVisual(this.letters);
  final List<String> letters;
}

/// جدول بخانات ناقصة — `null` = خانة بتتملا بالترتيب.
class TableVisual extends Visual {
  const TableVisual(this.cells, {required this.kind});
  final List<String?> cells;
  final TableKind kind;
}

enum TableKind { numbers, arLetters, enLetters }

/// مقطع أو كلمة مدّ — حرف المد ([hl]) بيتلوّن بلون نوعه.
class MaddTextVisual extends Visual {
  const MaddTextVisual(this.text, {this.hl, this.mamStart, this.typeKey, this.big = false, this.pop = false, this.say});
  final String text;

  /// بداية الحرف الممدود (لحد [hl]) — بيتعلّم بخط متقطع بنفسجي (درس المد والممدود).
  final int? mamStart;

  /// موضع حرف المد اللي بيتلوّن (null = من غير تلوين).
  final int? hl;
  final String? typeKey;
  final bool big;

  /// نطّة صغيرة لما المقطع يتكشف بعد الإجابة الصح.
  final bool pop;

  /// لو موجود بيظهر زرار 🔊 جنب النص بينطق ده.
  final String? say;
}

/// صف النمط وآخره "؟" (اتبع النمط).
class PatternVisual extends Visual {
  const PatternVisual(this.items);
  final List<String> items;
}

/// ساعة بعقارب (كام الساعة).
class ClockVisual extends Visual {
  const ClockVisual(this.hour, this.minute);
  final int hour;
  final int minute;
}

/// عيدان عشرات ومكعبات آحاد (الآحاد والعشرات) — العشرات على الشمال زي كتابة العدد.
class TensOnesVisual extends Visual {
  const TensOnesVisual(this.tens, this.ones);
  final int tens;
  final int ones;
}

/// مجموعات متساوية (الضرب): [groups] علبة في كل واحدة [each] صورة.
class GroupsVisual extends Visual {
  const GroupsVisual(this.emoji, this.groups, this.each);
  final String emoji;
  final int groups;
  final int each;
}

/// فلوس بالجنيه: ١ عملة، والباقي ورق (٥، ١٠، ٢٠، ٥٠، ١٠٠).
class MoneyVisual extends Visual {
  const MoneyVisual(this.pounds);
  final List<int> pounds;
}

/// قطعة قراءة بعنوانها (اقرأ وافهم) — خط أصغر من باقي المرئيات عشان تتقري كلها.
class PassageVisual extends Visual {
  const PassageVisual(this.title, this.text, {this.ltr = false});
  final String title;
  final String text;
  final bool ltr;
}

/// زرار 🔊 كبير لوحده (اسمع ثم اختر).
class ListenVisual extends Visual {
  const ListenVisual(this.say);
  final String say;
}

// ---------------------------------------------------------------------------
// أجزاء الأوضاع الخاصة
// ---------------------------------------------------------------------------

class FindCell {
  const FindCell(this.ch, {required this.hit});
  final String ch;
  final bool hit;
}

class SortBox {
  const SortBox(this.key, this.label);
  final String key;
  final String label;
}

class SortCard {
  const SortCard(this.text, this.say, this.type);
  final String text;
  final String say;
  final String type;
}

class MemoryCard {
  const MemoryCard(this.key, this.ch, {this.dots});
  final String key;
  final String ch;

  /// كارت العدد: دواير بدل النص (الرقم وصاحبه).
  final int? dots;
}

/// علبة لون في "لوّن بالأرقام".
class PaintPot {
  const PaintPot(this.n, this.color, this.name);
  final int n;
  final int color;
  final String name;
}

/// طبلة في "كرر الإيقاع" — [k] كمان رقم صوتها (SfxKind.pad0…).
class RhythmPad {
  const RhythmPad(this.k, this.icon, this.name, this.color);
  final int k;
  final String icon;
  final String name;
  final int color;
}

// ---------------------------------------------------------------------------
// السؤال
// ---------------------------------------------------------------------------

class Question {
  const Question({
    required this.type,
    required this.mode,
    required this.ask,
    required this.speak,
    required this.hint,
    this.speakHint,
    this.lang = 'ar',
    this.clips,
    this.clipsHint,
    this.visuals = const [],
    this.choices = const [],
    this.answer,
    this.items = const [],
    this.right = const [],
    this.pairMap = const {},
    this.cells = const [],
    this.hits = 0,
    this.cards = const [],
    this.pairs = 0,
    this.skill,
    this.skillOf,
    this.numeric = true,
    this.ltr = false,
    this.wide = false,
    this.rtlSlots = false,
    this.orderHint,
    this.gentle = false,
    this.bigChoices = false,
    this.okMsg,
    this.sayRight,
    this.revealVisuals,
    this.yes,
    this.boxes = const [],
    this.sortCards = const [],
    this.mtype,
    this.mword,
    this.look = ChoiceLook.text,
    this.sizePic,
    this.track = false,
    this.puzzle,
    this.paintCells = const [],
    this.paintCols = 0,
    this.pots = const [],
    this.picName,
    this.beats = const [],
    this.pads = const [],
    this.choiceSay = const {},
  });

  final String type;
  final QMode mode;

  /// 'ar' أو 'en' — بيحدد صوت النطق.
  final String lang;

  final String ask;
  final String speak;
  final String hint;
  final String? speakHint;

  /// مفاتيح المقاطع المسجّلة للسؤال والتلميح — لو أي مفتاح ناقص بنرجع للـ TTS.
  final List<String?>? clips;
  final List<String?>? clipsHint;

  final List<Visual> visuals;

  /// وضع الاختيار.
  final List<Object> choices;

  /// قيمة (int/String) في وضع الاختيار، أو `List<Object>` في order/grid.
  final Object? answer;

  /// بنك العناصر في order/grid، والعمود الأول في pairs.
  final List<Object> items;

  /// العمود التاني في pairs والخريطة بينهم.
  final List<String> right;
  final Map<String, String> pairMap;

  /// وضع find.
  final List<FindCell> cells;
  final int hits;

  /// وضع memory.
  final List<MemoryCard> cards;
  final int pairs;

  /// المهارة للتعلّم المتكيّف — و`skillOf` لو المهارة بتتحدد بالعنصر نفسه.
  final String? skill;
  final String Function(String value)? skillOf;

  /// في order/grid: القيم أرقام ولا نصوص.
  final bool numeric;

  /// النص والاختيارات من الشمال لليمين (English).
  final bool ltr;

  /// اختيارات نصية طويلة — عمود واحد عريض.
  final bool wide;

  /// خانات الترتيب من اليمين.
  final bool rtlSlots;
  final String? orderHint;

  /// غلطة = تشجيع لطيف (💪) من غير ومضة حمرا.
  final bool gentle;

  /// اختيارات بخط أكبر (مقاطع مشكولة).
  final bool bigChoices;

  /// رسالة الفقاعة بعد الإجابة الصح بدل التشجيع العام.
  final String? okMsg;

  /// اللي يتنطق بعد الإجابة الصح بدل قيمة الإجابة.
  final String? sayRight;

  /// المرئيات بعد الإجابة الصح (المقطع بحرف المد ملوّن).
  final List<Visual>? revealVisuals;

  /// نص زرار التأكيد في وضع read.
  final String? yes;

  /// وضع sort.
  final List<SortBox> boxes;
  final List<SortCard> sortCards;

  /// نوع المد والكلمة — لإحصائيات المدود.
  final String? mtype;
  final String? mword;

  // ---------------------------------------------------------- عالم الألعاب

  final ChoiceLook look;

  /// رتّب بالحجم: العناصر أحجام ('1'، '1.55'…) والصورة دي بتترسم بالحجم ده.
  final String? sizePic;

  /// سباق الأرقام: مسار الطفل والسلحفاة فوق السؤال.
  final bool track;

  /// بازل الصورة: الصورة اللي بتتكشف قطعة مع كل إجابة صح.
  final String? puzzle;

  /// لوّن بالأرقام: رقم كل خانة (صف ورا صف) وعدد الأعمدة والألوان.
  final List<int> paintCells;
  final int paintCols;
  final List<PaintPot> pots;
  final String? picName;

  /// كرر الإيقاع: السلسلة (أرقام الطبول) والطبول المتاحة.
  final List<int> beats;
  final List<RhythmPad> pads;

  /// إزاي الاختيار يتنطق لو اتداس غلط أو صح — لما شكله مكتوب مايتقريش لوحده
  /// (الكسر "3/4" ← "تلاتة من أربعة"، الحرف الساكن "لْ" ← "لام ساكنة").
  final Map<Object, String> choiceSay;

  bool get isEnglish => lang == 'en';

  List<Object> get answerList => (answer as List).cast<Object>();
}
