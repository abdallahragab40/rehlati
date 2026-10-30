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

  /// فين القطة؟: القطة تحت كوباية والأكواب بتتبدّل، والطفل يختار الكوباية.
  cups,

  /// متاهة: حرّك الأرنب بالأسهم لحد الجزرة.
  maze,

  /// ارسم بصباعك: تتبّع الحرف أو الرقم.
  trace,

  /// سودوكو: اختار خانة وبعدين الرقم أو الصورة.
  sudoku,

  /// برج هانوي: انقل الحلقات من عمود لعمود.
  hanoi,

  /// البازل المنزلق: زحلق الأرقام للخانة الفاضية.
  slide,
}

/// شكل الاختيارات لو مش نص.
enum ChoiceLook {
  text,

  /// ظل الإيموجي (أسود بالكامل) — ظل الصورة.
  shadow,

  /// "big|🐘" ← صورة بتوصف صفة (الأضداد): كبير/صغير، فوق/تحت، مليان/فاضي…
  opposite,

  /// "fruit" ← سلة فيها صورتين من النوع واسمه (صنّف).
  category,

  /// إيموجي وتحته اسمه من [Question.choiceSay] (خطوات الوضوء).
  picName,

  /// "5" ← قلم بطول ٥ (القياس).
  bar,

  /// "🍎|4" ← مجموعة من ٤ صور (أكتر وأقل).
  group,

  /// "h" ← عملة أو ورقة فلوس (ربع، نص، جنيه، ٥، ١٠).
  coin,

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
  const PatternVisual(this.items, {this.hole});
  final List<String> items;

  /// مكان الـ "؟" جوه الصف (الصورة الناقصة) — من غيره الـ "؟" في الآخر.
  final int? hole;
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
  const ListenVisual(this.say, {this.en = false});
  final String say;

  /// بيتنطق بالإنجليزي (Phonics و sight words).
  final bool en;
}

/// صورة كبيرة لوحدها (إيموجي) — ومن غير عدّ باللمس زي PicsVisual.
class EmojiVisual extends Visual {
  const EmojiVisual(this.emoji, {this.caption});
  final String emoji;

  /// سطر تحت الصورة (موقف «ده يصح ولا لأ؟»).
  final String? caption;
}

/// شكل هندسي كبير ("circle"، "triangle"، "square"، "rect").
class ShapeVisual extends Visual {
  const ShapeVisual(this.shape);
  final String shape;
}

/// طابور صور ورا علم 🏁 من اليمين (الأعداد الترتيبية).
class QueueVisual extends Visual {
  const QueueVisual(this.items, {this.flag = true});
  final List<String> items;

  /// علم البداية على اليمين (الطابور). من غيره الصف بيتعد من اليمين أو الشمال.
  final bool flag;
}

/// [count] صورة متقسّمة أزواج — الفردي بيفضل واحد لوحده (زوجي وفردي).
class PairsVisual extends Visual {
  const PairsVisual(this.emoji, this.count);
  final String emoji;
  final int count;
}

/// فلوس صغيرة بمفاتيح العملات ('q'، 'h'، '1'، '5'، '10').
class CoinsVisual extends Visual {
  const CoinsVisual(this.coins);
  final List<String> coins;
}

/// رسم بياني بالصور: عمود لكل صورة بعددها.
/// مستوى إحداثي من ٠ لـ ٦، وعليه نقط (الاسم، س، ص).
class CoordVisual extends Visual {
  const CoordVisual(this.points);
  final List<(String, int, int)> points;
}

/// صندوق من مكعبات (طول × عرض × ارتفاع)، و[labels] الأبعاد مكتوبة جنبه.
class BoxVisual extends Visual {
  const BoxVisual(this.l, this.w, this.h, {this.labels = true});
  final int l, w, h;
  final bool labels;
}

/// دايرة مقسومة قطاعات بالأتمان، كل قطاع بلون (أحمر، أزرق، أصفر، أخضر بالترتيب).
class PieVisual extends Visual {
  const PieVisual(this.eighths);
  final List<int> eighths;
}

/// زاوية مرسومة بشعاعين وقوس، و[degrees] قياسها.
class AngleVisual extends Visual {
  const AngleVisual(this.degrees);
  final int degrees;
}

/// خطين: ٠ متوازيان، ١ متعامدان، ٢ متقاطعان (مش عمودي).
class LinesVisual extends Visual {
  const LinesVisual(this.kind);
  final int kind;
}

/// شكل على شبكة مربعات: [cells] المربعات الملوّنة (x, y) من تحت على الشمال.
/// من غير شبكة ([grid] = false) الشكل بيترسم مستطيل وعليه [sides] (الطول، العرض).
class GridAreaVisual extends Visual {
  const GridAreaVisual(this.cols, this.rows, this.cells, {this.grid = true, this.sides});
  final int cols, rows;
  final List<(int, int)> cells;
  final bool grid;
  final (int, int)? sides;
}

/// تمثيل بالنقاط: (الرقم تحت، عدد النقط فوقه).
class DotPlotVisual extends Visual {
  const DotPlotVisual(this.rows);
  final List<(int, int)> rows;
}

/// شكل متقسّم قطع ملوّنة (مثلثات ومربعات). كل قطعة نقط (x, y) على شبكة والـ y لفوق.
/// [apart] = القطع متفرّقة عن بعض (قبل ما تتجمع).
class ComposeVisual extends Visual {
  const ComposeVisual(this.pieces, {this.apart = false});
  final List<List<(double, double)>> pieces;
  final bool apart;
}

/// حاجة جوه مكان أو فوقه أو تحته (in / on / under).
class PrepVisual extends Visual {
  const PrepVisual(this.thing, this.place, this.prep);
  final String thing, place, prep;
}

/// تمثيل بالأعمدة: (صورة، قيمة)، وخطوط الشبكة كل [scale] — أول عمود على اليمين.
class BarGraphVisual extends Visual {
  const BarGraphVisual(this.rows, this.scale);
  final List<(String, int)> rows;
  final int scale;
}

class PicGraphVisual extends Visual {
  const PicGraphVisual(this.rows);
  final List<(String, int)> rows;
}

/// نبات بأجزائه، والجزء [highlight] عليه سهم (أجزاء النبات).
class PlantVisual extends Visual {
  const PlantVisual(this.highlight);
  final String? highlight;
}

/// صورة صفة من الأضداد ("big|🐘") — نفس رسمة اختيارات [ChoiceLook.opposite].
class OppositeVisual extends Visual {
  const OppositeVisual(this.spec);
  final String spec;
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
  const SortBox(this.key, this.label, {this.color});
  final String key;
  final String label;

  /// لون الصندوق لو مش صندوق مدود (ودّي الحاجة مكانها).
  final int? color;
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
/// حيطان خانة المتاهة.
const mazeN = 1, mazeE = 2, mazeS = 4, mazeW = 8;

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
    this.lights = false,
    this.cupCount = 0,
    this.catCup = 0,
    this.cupSwaps = 0,
    this.cupStepMs = 0,
    this.mazeSize = 0,
    this.mazeWalls = const [],
    this.mazeStart = 0,
    this.mazeGoal = 0,
    this.trace,
    this.gridSize = 0,
    this.boxRows = 0,
    this.boxCols = 0,
    this.solution = const [],
    this.givens = const [],
    this.symbols = const [],
    this.discs = 0,
    this.slideSize = 0,
    this.slideStart = const [],
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

  /// كرر الألوان: نفس «كرر الإيقاع» بس الطبول ألوان بتنوّر من غير صوت.
  final bool lights;

  /// فين القطة؟: عدد الأكواب، الكوباية اللي تحتها القطة، عدد التبديلات ومدة كل تبديلة.
  final int cupCount;
  final int catCup;
  final int cupSwaps;
  final int cupStepMs;

  /// المتاهة: ضلع الشبكة، والحيطان لكل خانة (صف ورا صف) بالبتات [mazeN]…[mazeW]،
  /// وخانة الأرنب وخانة الجزرة.
  final int mazeSize;
  final List<int> mazeWalls;
  final int mazeStart;
  final int mazeGoal;

  /// ارسم بصباعك: الحرف أو الرقم اللي الطفل يتتبّعه.
  final String? trace;

  /// سودوكو: ضلع الشبكة ومقاس المربع، والحل (١…n صف ورا صف)، والخانات الظاهرة، وشكل كل رقم.
  final int gridSize;
  final int boxRows;
  final int boxCols;
  final List<int> solution;
  final List<bool> givens;
  final List<String> symbols;

  /// برج هانوي: عدد الحلقات.
  final int discs;

  /// البازل المنزلق: ضلع الشبكة وترتيب البداية (٠ = الخانة الفاضية).
  final int slideSize;
  final List<int> slideStart;

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
