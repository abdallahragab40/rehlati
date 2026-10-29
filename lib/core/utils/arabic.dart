/// أدوات الأرقام العربية — العرض بالأرقام الهندية والنطق بالكلام المصري.
library;

const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// إعداد ولي الأمر: الأرقام 123 بدل ١٢٣ — التطبيق بيظبطه من الإعدادات (RehlatiApp).
bool westernDigits = false;

/// يحوّل أي أرقام لاتينية داخل النص إلى ٠١٢٣٤٥٦٧٨٩ — القيم الداخلية تفضل أرقام عادية.
String ar(Object? v) => westernDigits
    ? '$v'
    : '$v'.replaceAllMapped(RegExp('[0-9]'), (m) => _arDigits[int.parse(m[0]!)]);

/// كلمة معدودة بصيغها: لواحد، لاتنين، جمع (٣–١٠)، ومفرد (١١ وفوق، والصفر).
typedef Counted = ({String one, String two, String few, String many});

/// العدد مع المعدود صح: "آية واحدة"، "آيتين"، "٥ آيات"، "٢٤ آية"، "١٠٣ آيات".
/// آخر رقمين بس اللي بيحددوا الصيغة (١٠٣ زي ٣).
String countOf(int n, Counted w) {
  if (n == 1) return w.one;
  if (n == 2) return w.two;
  final r = n % 100;
  return '${ar(n)} ${r >= 3 && r <= 10 ? w.few : w.many}';
}

const ayahWord = (one: 'آية واحدة', two: 'آيتين', few: 'آيات', many: 'آية');
const surahWord = (one: 'سورة واحدة', two: 'سورتين', few: 'سور', many: 'سورة');
const starWord = (one: 'نجمة واحدة', two: 'نجمتين', few: 'نجوم', many: 'نجمة');
const dayWord = (one: 'يوم واحد', two: 'يومين', few: 'أيام', many: 'يوم');
const minuteWord = (one: 'دقيقة واحدة', two: 'دقيقتين', few: 'دقايق', many: 'دقيقة');
const hourWord = (one: 'ساعة', two: 'ساعتين', few: 'ساعات', many: 'ساعة');
const gameWord = (one: 'لعبة واحدة', two: 'لعبتين', few: 'ألعاب', many: 'لعبة');
const timesWord = (one: 'مرة واحدة', two: 'مرتين', few: 'مرات', many: 'مرة');
const pieceWord = (one: 'قطعة واحدة', two: 'قطعتين', few: 'قطع', many: 'قطعة');
const situationWord = (one: 'موقف واحد', two: 'موقفين', few: 'مواقف', many: 'موقف');
const damagedFileWord = (one: 'ملف تالف', two: 'ملفين تالفين', few: 'ملفات تالفة', many: 'ملف تالف');

const _ones = [
  'صفر', 'واحد', 'اتنين', 'تلاتة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'تمانية', 'تسعة', 'عشرة',
  'حداشر', 'اتناشر', 'تلاتاشر', 'أربعتاشر', 'خمستاشر', 'ستاشر', 'سبعتاشر', 'تمنتاشر', 'تسعتاشر', 'عشرين',
];
const _tens = {
  20: 'عشرين', 30: 'تلاتين', 40: 'أربعين', 50: 'خمسين',
  60: 'ستين', 70: 'سبعين', 80: 'تمانين', 90: 'تسعين',
};

/// الأرقام تُنطق بالحروف العربية حتى لا تعتمد على لغة الصوت المثبّت.
String arNum(num n) {
  if (n is double && !n.isFinite) return '$n';
  final i = n.toInt();
  if (i >= 0 && i <= 20) return _ones[i];
  if (i == 100) return 'مية';
  if (i < 0 || i > 100) return '$i';
  final t = (i ~/ 10) * 10, o = i % 10;
  return o != 0 ? '${_ones[o]} و${_tens[t]}' : _tens[t]!;
}

/// قائمة منطوقة: الأرقام بالكلام والباقي كما هو.
String arList(Iterable<Object> items) =>
    items.map((v) => v is num ? arNum(v) : '$v').join('، ');

const signWord = {'>': 'أكبر من', '<': 'أصغر من', '=': 'يساوي'};
const signClip = {'>': 'gt', '<': 'lt', '=': 'eq'};

/// مفتاح مقطع الرقم — المسجّل عندنا من ٠ لـ ٢٢ (أكبر اختيار في الجمع).
String? nk(Object? n) => (n is int && n >= 0 && n <= 22) ? 'n$n' : null;
