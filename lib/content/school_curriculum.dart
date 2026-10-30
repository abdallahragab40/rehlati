/// دروس كتب الوزارة لأولى وتانية ابتدائي (٢٠٢٥/٢٠٢٦) — أسماء الوحدات والدروس بس، من فهرس كل كتاب
/// (tool/SCHOOL_CURRICULUM_INDEX.md). الأسئلة نفسها من مراحل التطبيق: كل درس بيقول أنهي مراحل
/// بتدرّب عليه، ولو حرف أو عدد معيّن يبقى [LessonItem.focus].
///
/// الدرس اللي [SchoolLesson.items] فاضية لسه مالوش مراحل — بيظهر «قريبًا».
/// مفتاح الدرس بيتحسب من مكانه (الكتاب، الوحدة، الدرس) وبيتخزّن في نتايج الطفل،
/// فدرس جديد يتضاف في آخر وحدته مش في النص.
library;

import 'basics_data.dart' show phonics;
import 'language_data.dart';

class LessonItem {
  const LessonItem(this.stage, {this.focus, this.minLevel = 1});

  /// مرحلة من lib/domain/stages.dart.
  final String stage;

  /// الحرف أو العدد اللي الأسئلة بتتركّز عليه.
  final String? focus;

  /// أقل مستوى يطلع فيه [focus] (الحروف بتتفتح بالترتيب مع المستوى).
  final int minLevel;
}

class SchoolLesson {
  const SchoolLesson(this.title, this.items);
  final String title;
  final List<LessonItem> items;

  bool get ready => items.isNotEmpty;
}

class SchoolUnit {
  const SchoolUnit(this.title, this.lessons);
  final String title;
  final List<SchoolLesson> lessons;
}

class SchoolBook {
  const SchoolBook(this.grade, this.term, this.subject, this.units);

  /// 'p1' أو 'p2' (زي schoolGrades).
  final String grade;
  final int term;

  /// 'arabic' أو 'math' أو 'english' — نفس أسماء العوالم.
  final String subject;
  final List<SchoolUnit> units;

  String get id => '$grade-t$term-$subject';
}

LessonItem _i(String stage, [String? focus]) => LessonItem(stage, focus: focus);

/// درس حرف عربي: اختيار الحرف، الحرف والصورة، وأشكاله في الكلمة.
SchoolLesson _arLetter(String letter) {
  final i = arLetters.indexWhere((l) => l.letter == letter);
  final l = arLetters[i];
  // arPool: أول ١٠ حروف في المستوى ١، و١٨ في ٢، وكلهم من ٣
  final lv = i < 10 ? 1 : (i < 18 ? 2 : 3);
  return SchoolLesson('حرف ال${l.name}', [
    LessonItem('ar_pick', focus: letter, minLevel: lv),
    LessonItem('ar_match', focus: letter, minLevel: lv),
    _i('ar_forms', letter),
  ]);
}

/// درس حروف إنجليزي: الحرف والصورة، وصوته لو الحرف في [phonics].
SchoolLesson _enLetters(List<String> letters) => SchoolLesson('Letters ${letters.join(', ')}', [
      for (final l in letters) ...[
        LessonItem('en_pick', focus: l, minLevel: 3),
        LessonItem('en_match', focus: l, minLevel: 3),
        if (phonics.any((p) => p.$1 == l)) LessonItem('en_phonics', focus: l, minLevel: 2),
      ],
    ]);

SchoolLesson _soon(String title) => SchoolLesson(title, const []);

final schoolBooks = <SchoolBook>[
  // ---------------------------------------------------------------- عربي
  SchoolBook('p1', 1, 'arabic', [
    SchoolUnit('أسرتي', [for (final l in ['أ', 'ب', 'م', 'ح', 'ج', 'د', 'خ', 'ت']) _arLetter(l)]),
    SchoolUnit('حيواناتي', [for (final l in ['ل', 'س', 'ن', 'ر', 'ف', 'ك', 'ق']) _arLetter(l)]),
    SchoolUnit('أجزاء جسمي', [for (final l in ['ي', 'ع', 'ش', 'و', 'ه', 'ذ', 'ظ']) _arLetter(l)]),
    SchoolUnit('مدرستي', [for (final l in ['ز', 'ط', 'ص', 'ض', 'ث', 'غ']) _arLetter(l)]),
  ]),
  SchoolBook('p1', 2, 'arabic', [
    SchoolUnit('ماذا أرى؟', [
      SchoolLesson('المذكر والمؤنث', [_i('ar_gender')]),
      SchoolLesson('المد بالألف', [_i('madd_alif')]),
      SchoolLesson('المفرد والجمع', [_i('ar_number')]),
      SchoolLesson('المد بالواو', [_i('madd_waw')]),
    ]),
    SchoolUnit('أخلاقنا الجميلة', [
      _soon('أنا – نحن'),
      SchoolLesson('المد بالياء', [_i('madd_yaa')]),
      SchoolLesson('هذا – هذه', [_i('ar_this')]),
      SchoolLesson('التنوين', [_i('ar_tanween'), _i('ar_marks')]),
    ]),
    SchoolUnit('في السوق', [
      _soon('أنتَ – أنتِ'),
      SchoolLesson('الشدة', [_i('ar_shadda')]),
      _soon('الفعل الماضي والمضارع'),
      SchoolLesson('مراجعة القواعد الإملائية', [_i('madd_types'), _i('ar_tanween'), _i('ar_shadda')]),
    ]),
  ]),
  SchoolBook('p2', 1, 'arabic', [
    SchoolUnit('المعاملة الطيبة', [
      SchoolLesson('المفرد والمثنى', [_i('ar_number')]),
      SchoolLesson('تحليل الكلمات إلى مقاطع', [_i('ar_analyze'), _i('ar_syllable')]),
      SchoolLesson('أسماء الإشارة', [_i('ar_this')]),
    ]),
    SchoolUnit('عادات صحية', [
      SchoolLesson('ذلك – تلك', [_i('ar_far')]),
      SchoolLesson('اللام الشمسية واللام القمرية', [_i('ar_al')]),
      SchoolLesson('ظرف الزمان وظرف المكان', [_i('ar_adverb')]),
    ]),
    SchoolUnit('الرياضة والتكنولوجيا', [
      SchoolLesson('الأمر والنهي', [_i('ar_command')]),
      SchoolLesson('الحروف المتشابهة في النطق', [_i('ar_similar')]),
      SchoolLesson('الأسماء الموصولة', [_i('ar_relative')]),
    ]),
  ]),
  SchoolBook('p2', 2, 'arabic', [
    SchoolUnit('من حولي', [
      _soon('ضمائر الغائب'),
      _soon('التاء المربوطة والتاء المفتوحة'),
      _soon('أسلوب النداء'),
    ]),
    SchoolUnit('في مدرستي', [
      _soon('أسلوب التعجب'),
      SchoolLesson('الشدة مع التنوين', [_i('ar_shadda'), _i('ar_tanween')]),
      _soon('أسلوب الاستفهام'),
    ]),
    SchoolUnit('أماكن جميلة', [
      _soon('حروف الجر'),
      _soon('حروف العطف'),
    ]),
  ]),

  // ---------------------------------------------------------------- حساب
  SchoolBook('p1', 1, 'math', [
    SchoolUnit('الأعداد حتى ١٠', [
      SchoolLesson('كم العدد؟', [_i('counting'), _i('chooseNumber')]),
      SchoolLesson('الأعداد من ١ إلى ٥', [for (var n = 1; n <= 5; n++) _i('counting', '$n')]),
      SchoolLesson('مكونات العدد ٥', [_i('numBonds', '5')]),
      SchoolLesson('الأعداد من ٦ إلى ١٠', [for (var n = 6; n <= 10; n++) _i('counting', '$n')]),
      for (final (n, name) in [(6, '٦'), (7, '٧'), (8, '٨'), (9, '٩'), (10, '١٠')])
        SchoolLesson('مكونات العدد $name', [_i('numBonds', '$n')]),
      SchoolLesson('هيا نقارن الأعداد', [_i('comparison')]),
      SchoolLesson('العدد صفر', [_i('zeroEvenOdd')]),
    ]),
    SchoolUnit('ما هو الموقع؟', [
      SchoolLesson('حدد الموقع', [_i('ordinals'), _i('position')]),
      SchoolLesson('أين هو؟', [_i('position')]),
    ]),
    SchoolUnit('الجمع', [
      SchoolLesson('الجمع', [_i('addition')]),
      SchoolLesson('قصص الجمع', [_i('wordProblem')]),
    ]),
    SchoolUnit('الطرح', [
      SchoolLesson('الطرح', [_i('subtraction')]),
      SchoolLesson('قصص الطرح', [_i('wordProblem')]),
    ]),
    SchoolUnit('مقارنة الأطوال', [SchoolLesson('أيهما أطول؟', [_i('measure')])]),
    SchoolUnit('تمثيل البيانات', [SchoolLesson('تمثيل البيانات بالصور', [_i('picGraph')])]),
    SchoolUnit('الأعداد الأكبر من ١٠', [
      SchoolLesson('عشرة وعدد ما', [_i('tensOnes')]),
      SchoolLesson('خط الأعداد', [_i('sequence'), _i('nextNumber')]),
      SchoolLesson('جمع وطرح الأعداد', [_i('addition'), _i('subtraction')]),
    ]),
    SchoolUnit('قراءة الساعة', [SchoolLesson('قراءة الوقت على الساعة', [_i('clockQuarter')])]),
    SchoolUnit('العمليات بثلاثة أعداد', [SchoolLesson('جمع وطرح ثلاثة أعداد', [_i('threeNumbers')])]),
  ]),
  SchoolBook('p1', 2, 'math', [
    SchoolUnit('أشكال مختلفة', [SchoolLesson('أشكال مختلفة', [_i('geometry')])]),
    SchoolUnit('كيف نقارن؟', [SchoolLesson('أيهما أكثر؟ وأيهما أكبر؟', [_i('measure'), _i('comparison')])]),
    SchoolUnit('الجمع بتكوين ١٠', [SchoolLesson('الجمع بتكوين ١٠', [_i('numBonds', '10'), _i('addition')])]),
    SchoolUnit('الطرح باستخدام ١٠', [SchoolLesson('الطرح باستخدام ١٠', [_i('subtraction')])]),
    SchoolUnit('الآحاد والعشرات والمئات', [
      SchoolLesson('الآحاد والعشرات', [_i('tensOnes')]),
      SchoolLesson('ترتيب الأعداد حتى ١٠٠', [_i('compare100'), _i('ascending')]),
      SchoolLesson('خط الأعداد حتى ١٠٠', [_i('skipCount')]),
      SchoolLesson('جمع وطرح الآحاد والعشرات', [_i('add100'), _i('sub100')]),
      SchoolLesson('الأعداد الأكبر من ١٠٠', [_i('hundreds')]),
    ]),
    SchoolUnit('تكوين أشكال', [_soon('تكوين أشكال')]),
    SchoolUnit('ما الوقت؟', [SchoolLesson('ما الوقت؟', [_i('clockQuarter')])]),
    SchoolUnit('الجمع والطرح', [SchoolLesson('الجمع والطرح', [_i('addition'), _i('subtraction'), _i('wordProblem')])]),
  ]),
  SchoolBook('p2', 1, 'math', [
    SchoolUnit('البيانات', [
      SchoolLesson('التمثيل البياني بالصور', [_i('picGraph')]),
      SchoolLesson('التمثيل البياني بالأعمدة', [_i('barGraph')]),
    ]),
    SchoolUnit('الجمع والطرح', [
      SchoolLesson('الجمع والطرح', [_i('add100'), _i('sub100')]),
      SchoolLesson('مسائل كلامية', [_i('wordProblem')]),
    ]),
    SchoolUnit('الأعداد المكوّنة من ٣ أرقام', [SchoolLesson('الأعداد من ٣ أرقام', [_i('hundreds')])]),
    SchoolUnit('الجمع والطرح بإعادة التجميع', [
      SchoolLesson('الجمع والطرح بإعادة التجميع', [_i('add100'), _i('sub100')]),
      SchoolLesson('تقدير نواتج الجمع والطرح', [_i('rounding')]),
    ]),
    SchoolUnit('الأشكال والقياس', [
      SchoolLesson('الأشكال الهندسية', [_i('geometry')]),
      SchoolLesson('قياس الأطوال', [_i('measure')]),
    ]),
    SchoolUnit('الكتلة والوقت', [
      SchoolLesson('الكتلة', [_i('measure')]),
      SchoolLesson('الوقت', [_i('clockQuarter')]),
    ]),
  ]),
  SchoolBook('p2', 2, 'math', [
    SchoolUnit('النقود', [SchoolLesson('النقود', [_i('coins'), _i('moneyCount'), _i('moneyChange')])]),
    SchoolUnit('الأنماط والمصفوفات', [
      SchoolLesson('الزوجي والفردي', [_i('zeroEvenOdd')]),
      SchoolLesson('الأنماط العددية', [_i('sequence'), _i('skipCount')]),
      SchoolLesson('المصفوفات والجمع المتكرر', [_i('mulGroups')]),
    ]),
    SchoolUnit('الجمع', [
      SchoolLesson('الجمع بإعادة التجميع', [_i('add100')]),
      SchoolLesson('التقدير والتقريب', [_i('rounding')]),
    ]),
    SchoolUnit('الطرح', [SchoolLesson('الطرح ومسائله', [_i('sub100'), _i('wordProblem')])]),
    SchoolUnit('الكسور', [SchoolLesson('الكسور', [_i('fractionOfNumber')])]),
    SchoolUnit('البيانات', [SchoolLesson('قراءة البيانات', [_i('picGraph')])]),
  ]),

  // ---------------------------------------------------------------- English (Connect)
  SchoolBook('p1', 1, 'english', [
    SchoolUnit('Welcome to My School', [
      SchoolLesson('Greetings & classroom', [_i('en_phrases'), _i('en_daily')]),
      _enLetters(['T', 'I']),
    ]),
    SchoolUnit('The Garden of Colors and Shapes', [
      SchoolLesson('Colors and shapes', [_i('en_colors'), _i('en_shapes')]),
      _enLetters(['S', 'A']),
    ]),
    SchoolUnit('I Love My Family', [
      SchoolLesson('My family and numbers 1–5', [_i('en_family'), _i('en_numbers')]),
      _enLetters(['N', 'P', 'H', 'D']),
    ]),
    SchoolUnit('My Body and My Senses', [
      SchoolLesson('My body', [_i('en_body')]),
      _enLetters(['R', 'E', 'C', 'K']),
    ]),
    SchoolUnit('On the Farm', [
      SchoolLesson('Farm animals and numbers 6–10', [_i('en_animals'), _i('en_numbers')]),
      _enLetters(['M', 'G', 'O', 'F']),
    ]),
    SchoolUnit('Animals Around Me', [
      SchoolLesson('Animals', [_i('en_animals')]),
      _soon('in, on, under'),
      _enLetters(['B', 'L', 'U', 'J']),
    ]),
  ]),
  SchoolBook('p1', 2, 'english', [
    SchoolUnit('My Week', [_soon('Days of the week'), _enLetters(['W', 'Q', 'V', 'Z'])]),
    SchoolUnit('Feelings', [_soon('Feelings and pronouns'), _enLetters(['Y', 'X'])]),
    SchoolUnit('Seasons', [_soon('Months, seasons and weather'), SchoolLesson('Short vowels a, e', [_i('en_cvc')])]),
    SchoolUnit('My House', [_soon('Rooms and furniture'), SchoolLesson('Short vowels i, o', [_i('en_cvc')])]),
    SchoolUnit('Neighborhood', [_soon('Places and transport'), SchoolLesson('Short vowel u', [_i('en_cvc')])]),
  ]),
  SchoolBook('p2', 1, 'english', [
    SchoolUnit("Let's Get Started!", [
      SchoolLesson('Classroom things', [_i('en_daily')]),
      SchoolLesson('Short vowels a, e, i', [_i('en_cvc')]),
    ]),
    SchoolUnit('Colors, Shapes, and Numbers', [
      SchoolLesson('Colors, shapes and numbers', [_i('en_colors'), _i('en_shapes'), _i('en_numbers')]),
    ]),
    SchoolUnit('Classroom Actions & Routines', [
      _soon('Classroom actions'),
      SchoolLesson('First sounds', [_i('en_firstsound')]),
    ]),
    SchoolUnit('Everyday Life', [SchoolLesson('My family', [_i('en_family')])]),
    SchoolUnit('My Home', [_soon('My home')]),
    SchoolUnit('Rooms at Home', [_soon('Rooms at home')]),
  ]),
  SchoolBook('p2', 2, 'english', [
    SchoolUnit('Our Environment', [SchoolLesson('There is / There are', [_i('en_isare')])]),
    SchoolUnit('At the Store', [_soon('Shopping and clothes')]),
    SchoolUnit('Sports', [SchoolLesson('Plural with s', [_i('en_plural')]), _soon('Counting to 50')]),
    SchoolUnit('Transportation', [_soon('Transportation')]),
    SchoolUnit('The Pyramids', [_soon('The Pyramids')]),
  ]),
];
