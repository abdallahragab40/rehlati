/// المرحلة الدراسية — التطبيق بيغطي من KG1 لحد سادسة ابتدائي، والمحتوى كله بيتعرض على قد المرحلة.
///
/// ولي الأمر بيختار المرحلة في شاشة البداية (إجباري)، والسن مابقاش بيتسأل: الألعاب والمستويات
/// بتاخد السن المعتاد للمرحلة ([gradeAge]).
library;

/// المراحل بالترتيب: KG1 و KG2، وابتدائي من أولى لسادسة.
const schoolGrades = ['kg1', 'kg2', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6'];

/// اسم المرحلة كامل: "KG1"، "تالتة ابتدائي".
String gradeName(String grade) => switch (grade) {
      'kg1' => 'KG1',
      'kg2' => 'KG2',
      'p1' => 'أولى ابتدائي',
      'p2' => 'تانية ابتدائي',
      'p3' => 'تالتة ابتدائي',
      'p4' => 'رابعة ابتدائي',
      'p5' => 'خامسة ابتدائي',
      'p6' => 'سادسة ابتدائي',
      _ => grade,
    };

/// اسم قصير لزرار المرحلة: "KG1"، "تالتة".
String gradeShort(String grade) => switch (grade) {
      'kg1' || 'kg2' => grade.toUpperCase(),
      _ => gradeName(grade).split(' ').first,
    };

bool isKg(String? grade) => grade == 'kg1' || grade == 'kg2';

/// ترتيب المرحلة في [schoolGrades] — -1 لو مش متحددة.
int gradeIndex(String? grade) => grade == null ? -1 : schoolGrades.indexOf(grade);

/// السن المعتاد للمرحلة في مصر (KG1 من ٤ سنين وأولى ابتدائي من ٦) — للألعاب ومستوى الأسئلة.
int? gradeAge(String? grade) => switch (gradeIndex(grade)) {
      -1 => null,
      final i => 4 + i,
    };

/// المرحلة المعتادة لسن — للتقدّم القديم اللي اتسجّل بالسن بس (٣ سنين بقت KG1).
String? gradeForAge(int? age) => switch (age) {
      null => null,
      <= 4 => 'kg1',
      >= 11 => 'p6',
      final a => schoolGrades[a - 4],
    };

/// "رابعة – سادسة"، "KG2 – تانية" — مدى مراحل للعرض.
String gradeRange(String from, String to) => from == to ? gradeShort(from) : '${gradeShort(from)} – ${gradeShort(to)}';
