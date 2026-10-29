/// مسارات التعلّم: أربع أسابيع، في كل أسبوع دروس، وكل درس كام نشاط من المراحل الموجودة.
///
/// الدروس بتتفتح بالترتيب. النشاط بيتحسب للدرس الحالي بس لما الطفل ينجح فيه (٨٠٪+)، من أي مكان
/// اتلعب منه. المسارات بتغطي مهارات من KG2 للابتدائي، مع بداية للقسمة والكسور لسن ٩–١٢.
/// أهداف الأسابيع محتاجة مراجعة مدرّس.
library;

import 'progress/progress_data.dart';
import 'stages.dart';

class PathLesson {
  const PathLesson(this.id, this.title, this.stages);

  /// ثابت حتى لو العنوان اتغيّر — التقدّم متسجّل بيه.
  final String id;
  final String title;

  /// المراحل بالترتيب (ids من [packs]).
  final List<String> stages;
}

class PathWeek {
  const PathWeek(this.title, this.goal, this.lessons);
  final String title;

  /// هدف الأسبوع — لولي الأمر.
  final String goal;
  final List<PathLesson> lessons;
}

class LearningPath {
  const LearningPath({
    required this.id,
    required this.world,
    required this.icon,
    required this.name,
    required this.ages,
    required this.desc,
    required this.weeks,
  });

  final String id;
  final String world;
  final String icon;
  final String name;

  /// السن المقصود — للعرض بس، المسار مفتوح لأي طفل.
  final String ages;
  final String desc;
  final List<PathWeek> weeks;

  List<PathLesson> get lessons => [for (final w in weeks) ...w.lessons];

  PathWeek weekOf(PathLesson l) => weeks.firstWhere((w) => w.lessons.contains(l));

  // ---------------------------------------------------------------- التقدّم

  Set<String> _done(ProgressData p) => p.pathDone[id] ?? const {};

  bool stepDone(ProgressData p, PathLesson l, String stage) => _done(p).contains('${l.id}:$stage');

  bool lessonDone(ProgressData p, PathLesson l) => l.stages.every((s) => stepDone(p, l, s));

  /// أول درس لسه ما خلصش — null = المسار خلص.
  PathLesson? current(ProgressData p) => lessons.where((l) => !lessonDone(p, l)).firstOrNull;

  int lessonsDone(ProgressData p) => lessons.where((l) => lessonDone(p, l)).length;

  bool started(ProgressData p) => _done(p).isNotEmpty;

  bool complete(ProgressData p) => current(p) == null;
}

/// الطفل نجح في مرحلة (٨٠٪+): بتتعلّم في الدرس الحالي لكل مسار هي فيه.
void markPathStage(ProgressData p, String stage) {
  for (final path in learningPaths) {
    final l = path.current(p);
    if (l != null && l.stages.contains(stage)) p.pathDone.putIfAbsent(path.id, () => {}).add('${l.id}:$stage');
  }
}

LearningPath? pathById(String id) => learningPaths.where((p) => p.id == id).firstOrNull;

/// كل مراحل الدرس موجودة وبتتلعب بنتيجة (لوحة الحروف مالهاش نتيجة).
bool lessonPlayable(PathLesson l) => l.stages.every((s) => packs[s] != null && !packs[s]!.isLearn);

const learningPaths = [readingPath, mathPath, math100Path, timesPath, lifePath, upperPrimaryPath];

const readingPath = LearningPath(
  id: 'reading1',
  world: 'arabic',
  icon: '📖',
  name: 'رحلة القراءة الأولى',
  ages: '٦–٨ سنين',
  desc: 'من الحروف وأصواتها والحركات لحد قراءة كلمات فيها مدود، في ٤ أسابيع.',
  weeks: [
    PathWeek('الحروف وأصواتها', 'يعرف الـ٢٨ حرف بشكلهم، ويربط الحرف بأول صوت في اسم الصورة.', [
      PathLesson('r1', 'أشكال الحروف', ['ar_pick', 'ar_table']),
      PathLesson('r2', 'الحرف والصورة', ['ar_match', 'ar_pick']),
      PathLesson('r3', 'جدول الحروف', ['ar_table', 'ar_match']),
      PathLesson('r4', 'مراجعة الأسبوع', ['ar_pick', 'ar_match', 'ar_table']),
    ]),
    // اسمع واختار المقطع مش هنا: محتاجة الصوت، والمسار لازم يشتغل من غيره
    PathWeek('الحركات والكلمة', 'يعرف الفتحة والضمة والكسرة ويقرأ الحرف بيها، ويكوّن كلمة من حروفها.', [
      PathLesson('r5', 'الفتحة والضمة والكسرة', ['ar_haraka', 'ar_haraka_pick']),
      PathLesson('r6', 'الحرف وحركته', ['ar_haraka_pick', 'ar_build']),
      PathLesson('r7', 'كوّن الكلمة', ['ar_haraka', 'ar_compose']),
      PathLesson('r8', 'مراجعة الأسبوع', ['ar_haraka', 'ar_haraka_pick', 'ar_complete']),
    ]),
    PathWeek('المدود', 'يقرأ المد بالألف والواو والياء، ويفرّق بينهم في المقطع.', [
      PathLesson('r9', 'المد بالألف والواو', ['madd_alif', 'madd_waw']),
      PathLesson('r10', 'المد بالياء', ['madd_yaa', 'madd_types']),
      PathLesson('r11', 'المقاطع', ['madd_complete', 'madd_compose']),
      PathLesson('r12', 'المد جوه الكلمة', ['madd_find', 'madd_types']),
    ]),
    PathWeek('أقرأ كلمات', 'يقرأ كلمات قصيرة فيها مدود، ويختار الكلمة المناسبة للصورة.', [
      PathLesson('r13', 'أقرأ الكلمة', ['madd_read', 'ar_choose_word']),
      PathLesson('r14', 'الكلمة والصورة', ['ar_match_word', 'madd_mamdoud']),
      PathLesson('r15', 'كلمات أطول', ['ar_choose_word', 'madd_read']),
      PathLesson('r16', 'المراجعة الكبيرة', ['ar_connect', 'madd_find', 'ar_match_word']),
    ]),
  ],
);

const mathPath = LearningPath(
  id: 'math1',
  world: 'math',
  icon: '🔢',
  name: 'رحلة الأرقام',
  ages: '٦–٨ سنين',
  desc: 'الأعداد لحد ٢٠، والترتيب والمقارنة، والجمع والطرح، في ٤ أسابيع.',
  weeks: [
    PathWeek('الأعداد لحد ٢٠', 'يعد لحد ٢٠، ويعرف العدد اللي قبل واللي بعد أي عدد.', [
      PathLesson('m1', 'العد', ['counting', 'chooseNumber']),
      PathLesson('m2', 'قبل وبعد', ['nextNumber', 'previousNumber']),
      PathLesson('m3', 'الجيران والتسلسل', ['neighbors', 'sequence']),
      PathLesson('m4', 'مراجعة الأسبوع', ['chooseNumber', 'neighbors', 'sequence']),
    ]),
    PathWeek('الترتيب والمقارنة', 'يقارن عددين، ويرتّب الأعداد تصاعدي وتنازلي، ويكمّل جدول الأعداد.', [
      PathLesson('m5', 'أكبر وأصغر', ['comparison', 'ascending']),
      PathLesson('m6', 'من الكبير للصغير', ['descending', 'comparison']),
      PathLesson('m7', 'جدول الأعداد', ['completeTable', 'sequence']),
      PathLesson('m8', 'مراجعة الأسبوع', ['ascending', 'descending', 'completeTable']),
    ]),
    PathWeek('الجمع', 'يجمع عددين مجموعهم لحد ٢٠، بالصور وبعدين بالأرقام.', [
      PathLesson('m9', 'نجمع بالصور', ['addition', 'completeTable']),
      PathLesson('m10', 'نجمع ونكتب', ['addition', 'emptyTable']),
      PathLesson('m11', 'الجمع والمقارنة', ['addition', 'comparison']),
      PathLesson('m12', 'مراجعة الأسبوع', ['addition', 'sequence', 'emptyTable']),
    ]),
    PathWeek('الطرح', 'يطرح من أعداد لحد ٢٠، ويفرّق بين مسائل الجمع والطرح.', [
      PathLesson('m13', 'نطرح بالصور', ['subtraction', 'previousNumber']),
      PathLesson('m14', 'جمع ولا طرح؟', ['subtraction', 'addition']),
      PathLesson('m15', 'نطرح ونكتب', ['subtraction', 'emptyTable']),
      PathLesson('m16', 'المراجعة الكبيرة', ['addition', 'subtraction', 'comparison']),
    ]),
  ],
);

const math100Path = LearningPath(
  id: 'math2',
  world: 'math',
  icon: '🧱',
  name: 'رحلة الأرقام لحد ١٠٠',
  ages: '٧–٨ سنين',
  desc: 'الآحاد والعشرات، والعد بالقفز، والمقارنة، والجمع والطرح لحد ١٠٠، في ٤ أسابيع.',
  weeks: [
    PathWeek('الآحاد والعشرات', 'يعرف إن كل ١٠ آحاد = عشرة، ويقرأ أي عدد لحد ٩٩ كعشرات وآحاد، ويعد بالعشرات.', [
      PathLesson('h1', 'العيدان والمكعبات', ['tensOnes']),
      PathLesson('h2', 'نعد بالعشرات', ['skipCount', 'tensOnes']),
      PathLesson('h3', 'كام عشرة؟', ['tensOnes', 'skipCount']),
      PathLesson('h4', 'مراجعة الأسبوع', ['tensOnes', 'skipCount', 'completeTable']),
    ]),
    PathWeek('المقارنة لحد ١٠٠', 'يقارن عددين من رقمين: العشرات الأول، ولو زي بعض الآحاد.', [
      PathLesson('h5', 'أكبر وأصغر لحد ١٠٠', ['compare100', 'tensOnes']),
      PathLesson('h6', 'نقفز ونقارن', ['compare100', 'skipCount']),
      PathLesson('h7', 'الأرقام المقلوبة', ['compare100', 'tensOnes']),
      PathLesson('h8', 'مراجعة الأسبوع', ['compare100', 'skipCount', 'tensOnes']),
    ]),
    PathWeek('الجمع لحد ١٠٠', 'يجمع الآحاد مع الآحاد والعشرات مع العشرات، وبيبدأ يجمع بحمل.', [
      PathLesson('h9', 'نجمع العشرات', ['add100', 'tensOnes']),
      PathLesson('h10', 'نجمع رقمين', ['add100', 'skipCount']),
      PathLesson('h11', 'الجمع والمقارنة', ['add100', 'compare100']),
      PathLesson('h12', 'مراجعة الأسبوع', ['add100', 'tensOnes', 'compare100']),
    ]),
    PathWeek('الطرح لحد ١٠٠', 'يطرح الآحاد من الآحاد والعشرات من العشرات، وبيبدأ يطرح باستلاف.', [
      PathLesson('h13', 'نطرح العشرات', ['sub100', 'skipCount']),
      PathLesson('h14', 'جمع ولا طرح؟', ['sub100', 'add100']),
      PathLesson('h15', 'الطرح والمقارنة', ['sub100', 'compare100']),
      PathLesson('h16', 'المراجعة الكبيرة', ['add100', 'sub100', 'compare100']),
    ]),
  ],
);

const timesPath = LearningPath(
  id: 'math3',
  world: 'math',
  icon: '✖️',
  name: 'رحلة جدول الضرب',
  ages: '٨–٩ سنين',
  desc: 'الضرب كمجموعات متساوية، وبعدين جدول الضرب خطوة خطوة، في ٤ أسابيع.',
  weeks: [
    PathWeek('الضرب يعني مجموعات', 'يفهم الضرب كجمع مجموعات متساوية، ويحفظ جدول ٢ و ٥ و ١٠.', [
      PathLesson('g1', 'المجموعات المتساوية', ['mulGroups']),
      PathLesson('g2', 'نعد بالقفز', ['mulGroups', 'skipCount']),
      PathLesson('g3', 'جدول ٢ و ٥ و ١٠', ['times2510', 'mulGroups']),
      PathLesson('g4', 'مراجعة الأسبوع', ['times2510', 'skipCount', 'mulGroups']),
    ]),
    PathWeek('جدول ٣ و ٤', 'يحفظ جدول ٣ و ٤، ويعرف إن ٣ × ٤ زي ٤ × ٣.', [
      PathLesson('g5', 'جدول ٣ و ٤', ['times34', 'mulGroups']),
      PathLesson('g6', 'الجداول مع بعض', ['times34', 'times2510']),
      PathLesson('g7', 'نقفز بالتلاتات والأربعات', ['times34', 'skipCount']),
      PathLesson('g8', 'مراجعة الأسبوع', ['times34', 'times2510', 'mulGroups']),
    ]),
    PathWeek('جدول ٦ لـ ٩', 'يحفظ جدول ٦ و ٧ و ٨ و ٩، ويستخدم الجداول اللي حفظها قبل كده.', [
      PathLesson('g9', 'جدول ٦ و ٧', ['times6789', 'times34']),
      PathLesson('g10', 'جدول ٨ و ٩', ['times6789', 'mulGroups']),
      PathLesson('g11', 'الكبير والصغير', ['times6789', 'times2510']),
      PathLesson('g12', 'مراجعة الأسبوع', ['times6789', 'times34', 'times2510']),
    ]),
    PathWeek('الجدول كله', 'يجاوب أي سؤال من جدول الضرب، ويلاقي العامل الناقص (٣ × ؟ = ١٨).', [
      PathLesson('g13', 'الجدول كله', ['timesAll', 'times2510']),
      PathLesson('g14', 'العامل الناقص', ['timesAll', 'times34']),
      PathLesson('g15', 'الجداول الكبيرة', ['timesAll', 'times6789']),
      PathLesson('g16', 'المراجعة الكبيرة', ['timesAll', 'times6789', 'add100']),
    ]),
  ],
);

const lifePath = LearningPath(
  id: 'math4',
  world: 'math',
  icon: '💰',
  name: 'رحلة الفلوس والساعة',
  ages: '٨–٩ سنين',
  desc: 'يعدّ الفلوس ويحسب الباقي، ويقرا الساعة بالربع وبالدقايق، في ٤ أسابيع.',
  weeks: [
    PathWeek('نعدّ الفلوس', 'يعرف الجنيه والخمسة والعشرة والعشرين والخمسين، ويعدّ فلوس لحد ١٠٠.', [
      PathLesson('f1', 'الجنيه والخمسة والعشرة', ['moneyCount']),
      PathLesson('f2', 'نجمع الفلوس', ['moneyCount', 'add100']),
      PathLesson('f3', 'نعد بالقفز', ['moneyCount', 'skipCount']),
      PathLesson('f4', 'مراجعة الأسبوع', ['moneyCount', 'add100', 'tensOnes']),
    ]),
    PathWeek('الباقي كام؟', 'يحسب الباقي لما يدفع ورقة ويشتري حاجة.', [
      PathLesson('f5', 'الباقي من ١٠ و ٢٠', ['moneyChange', 'moneyCount']),
      PathLesson('f6', 'نطرح الفلوس', ['moneyChange', 'sub100']),
      PathLesson('f7', 'أغلى ولا أرخص؟', ['moneyChange', 'compare100']),
      PathLesson('f8', 'مراجعة الأسبوع', ['moneyChange', 'moneyCount', 'sub100']),
    ]),
    PathWeek('الساعة بالربع', 'يقرا الساعة تمام والنص والربع وإلا ربع.', [
      PathLesson('f9', 'تمام والنص', ['clockQuarter']),
      PathLesson('f10', 'والربع وإلا ربع', ['clockQuarter', 'moneyCount']),
      PathLesson('f11', 'الساعة والفلوس', ['clockQuarter', 'moneyChange']),
      PathLesson('f12', 'مراجعة الأسبوع', ['clockQuarter', 'skipCount']),
    ]),
    PathWeek('الساعة بالدقايق', 'يقرا الساعة بالخمس دقايق (والتلت، والنص إلا خمسة، إلا عشرة).', [
      PathLesson('f13', 'بالخمس دقايق', ['clockQuarter', 'skipCount']),
      PathLesson('f14', 'الساعة والطرح', ['clockQuarter', 'sub100']),
      PathLesson('f15', 'الفلوس كلها', ['moneyCount', 'moneyChange']),
      PathLesson('f16', 'المراجعة الكبيرة', ['clockQuarter', 'moneyCount', 'moneyChange']),
    ]),
  ],
);

/// Introductory practice, not a complete grade 4–6 curriculum.
const upperPrimaryPath = LearningPath(
  id: 'math5', world: 'math', icon: '➗', name: 'رحلة القسمة والكسور', ages: '٩–١٢ سنة',
  desc: 'بداية تدريب للسن ده: القسمة وعلاقتها بالضرب، وكسر من عدد، والكسور المتكافئة، في ٤ أسابيع.',
  weeks: [
    PathWeek('القسمة عكس الضرب', 'يقسم أعدادًا من جدول الضرب من غير باقي، ويستخدم الضرب للتحقق.', [
      PathLesson('u1', 'نراجع جدول الضرب', ['timesAll']),
      PathLesson('u2', 'نقسم بالتساوي', ['divisionExact']),
      PathLesson('u3', 'نضرب ونتأكد', ['divisionExact', 'timesAll']),
      PathLesson('u4', 'مراجعة الأسبوع', ['divisionExact', 'timesAll']),
    ]),
    PathWeek('العدد اللي قسمناه', 'يلاقي المقسوم الناقص بضرب المقسوم عليه في ناتج القسمة.', [
      PathLesson('u5', 'العدد الناقص', ['divisionMissing']),
      PathLesson('u6', 'نقسم ونتحقق', ['divisionMissing', 'divisionExact']),
      PathLesson('u7', 'الضرب يساعدنا', ['divisionMissing', 'timesAll']),
      PathLesson('u8', 'مراجعة الأسبوع', ['divisionExact', 'divisionMissing']),
    ]),
    PathWeek('كسر من عدد', 'يقسم العدد إلى أجزاء متساوية، ويحسب قيمة جزء أو عدة أجزاء منه.', [
      PathLesson('u9', 'الأجزاء المتساوية', ['fractionOfNumber']),
      PathLesson('u10', 'القسمة والكسر', ['fractionOfNumber', 'divisionExact']),
      PathLesson('u11', 'نحسب الأجزاء', ['fractionOfNumber', 'divisionMissing']),
      PathLesson('u12', 'مراجعة الأسبوع', ['fractionOfNumber', 'divisionExact']),
    ]),
    PathWeek('الكسور المتكافئة', 'يختار كسرًا مكافئًا بضرب البسط والمقام في نفس العدد.', [
      PathLesson('u13', 'نفس القيمة', ['fractionEquivalent']),
      PathLesson('u14', 'البسط والمقام', ['fractionEquivalent', 'timesAll']),
      PathLesson('u15', 'نطبق الكسور', ['fractionEquivalent', 'fractionOfNumber']),
      PathLesson('u16', 'المراجعة الكبيرة', ['divisionExact', 'fractionOfNumber', 'fractionEquivalent']),
    ]),
  ],
);
