/// دروس العربي والحساب والإنجليزي من أولى لسادسة ابتدائي (٢٠٢٥/٢٠٢٦) — أسماء الوحدات والدروس بس، من فهرس كل كتاب
/// (tool/SCHOOL_CURRICULUM_INDEX.md). الأسئلة نفسها من مراحل التطبيق: كل درس بيقول أنهي مراحل
/// بتدرّب عليه، ولو حرف أو عدد معيّن يبقى [LessonItem.focus].
///
/// مطابقة أولى وتانية ترم أول مع طبعة ٢٠٢٦/٢٠٢٧ في tool/curriculum/p1-t1.json وp2-t1.json.
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
  const SchoolLesson(this.title, this.items) : explainOnly = false;

  /// درس شرح بس (استماع، نشيد، قراءة — assets/lessons/): مالوش جولة أسئلة ولا بيدخل في امتحان الوحدة.
  const SchoolLesson.explain(this.title)
      : items = const [],
        explainOnly = true;

  final String title;
  final List<LessonItem> items;
  final bool explainOnly;

  /// ليه جولة أسئلة.
  bool get ready => items.isNotEmpty;
}

class SchoolUnit {
  const SchoolUnit(this.title, this.lessons);
  final String title;
  final List<SchoolLesson> lessons;
}

class SchoolBook {
  const SchoolBook(this.grade, this.term, this.subject, this.units);

  /// من 'p1' إلى 'p6' (زي schoolGrades).
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

// درس لسه مالوش مراحل («قريبًا») — كل دروس أولى لتالتة جاهزة دلوقتي، وده للكتب الجاية.
// ignore: unused_element
SchoolLesson _soon(String title) => SchoolLesson(title, const []);

final schoolBooks = <SchoolBook>[
  // ---------------------------------------------------------------- عربي
  SchoolBook('p1', 1, 'arabic', [
    SchoolUnit('أسرتي', [
      for (final l in ['أ', 'ب', 'م', 'ح', 'ج', 'د', 'خ', 'ت']) _arLetter(l),
      const SchoolLesson.explain('استماع: يوم الجمعة'),
      const SchoolLesson.explain('نشيد: ما أجمل أسرتي'),
      const SchoolLesson.explain('اقرا: تاج ماما'),
    ]),
    SchoolUnit('حيواناتي', [
      for (final l in ['ل', 'س', 'ن', 'ر', 'ف', 'ك', 'ق']) _arLetter(l),
      const SchoolLesson.explain('استماع: في حديقة الحيوان'),
      const SchoolLesson.explain('نشيد: حيواناتي'),
      const SchoolLesson.explain('اقرا: سمك ونمل'),
    ]),
    SchoolUnit('أجزاء جسمي', [
      for (final l in ['ي', 'ع', 'ش', 'و', 'ه', 'ذ', 'ظ']) _arLetter(l),
      const SchoolLesson.explain('استماع: يوسف النضيف'),
      const SchoolLesson.explain('نشيد: جسمي'),
      const SchoolLesson.explain('اقرا: وجه نظيف'),
    ]),
    SchoolUnit('مدرستي', [
      for (final l in ['ز', 'ط', 'ص', 'ض', 'ث', 'غ']) _arLetter(l),
      const SchoolLesson.explain('استماع: أول يوم في المدرسة'),
      const SchoolLesson.explain('نشيد: مدرستي'),
      const SchoolLesson.explain('اقرا: قلم وكتاب'),
    ]),
  ]),
  SchoolBook('p1', 2, 'arabic', [
    SchoolUnit('ماذا أرى؟', [
      SchoolLesson('المذكر والمؤنث', [_i('ar_gender')]),
      SchoolLesson('المد بالألف', [_i('madd_alif')]),
      SchoolLesson('المفرد والجمع', [_i('ar_number')]),
      SchoolLesson('المد بالواو', [_i('madd_waw')]),
    ]),
    SchoolUnit('أخلاقنا الجميلة', [
      SchoolLesson('أنا – نحن', [_i('ar_pronoun', 'ana')]),
      SchoolLesson('المد بالياء', [_i('madd_yaa')]),
      SchoolLesson('هذا – هذه', [_i('ar_this')]),
      SchoolLesson('التنوين', [_i('ar_tanween'), _i('ar_marks')]),
    ]),
    SchoolUnit('في السوق', [
      SchoolLesson('أنتَ – أنتِ', [_i('ar_pronoun', 'anta')]),
      SchoolLesson('الشدة', [_i('ar_shadda')]),
      SchoolLesson('الفعل الماضي والمضارع', [_i('ar_tense')]),
      SchoolLesson('هو – هي', [_i('ar_pronoun', 'huwa')]),
      SchoolLesson('مراجعة القواعد الإملائية', [_i('madd_types'), _i('ar_tanween'), _i('ar_shadda')]),
    ]),
  ]),
  SchoolBook('p2', 1, 'arabic', [
    SchoolUnit('المعاملة الطيبة', [
      SchoolLesson('المفرد والمثنى', [_i('ar_number')]),
      SchoolLesson('تحليل الكلمات إلى مقاطع', [_i('ar_analyze'), _i('ar_syllable')]),
      SchoolLesson('أسماء الإشارة', [_i('ar_this')]),

      const SchoolLesson.explain('اقرأ: قلم لصديقي'),
      const SchoolLesson.explain('اقرأ: مكان للجميع'),
      const SchoolLesson.explain('استماع: الهدية الصغيرة'),
      const SchoolLesson.explain('نشيد: أقول شكرًا'),
      const SchoolLesson.explain('تحدث: كلمة لطيفة'),
      const SchoolLesson.explain('تحدث: أرحب بصديق'),
      const SchoolLesson.explain('كتابة: مشهد في الحديقة'),
      const SchoolLesson.explain('كتابة: مشهد في الفصل'),
      const SchoolLesson.explain('مراجعة: أستعد لتانية'),
    ]),
    SchoolUnit('عادات صحية', [
      SchoolLesson('ذلك – تلك', [_i('ar_far')]),
      SchoolLesson('اللام الشمسية واللام القمرية', [_i('ar_al')]),
      SchoolLesson('ظرف الزمان وظرف المكان', [_i('ar_adverb')]),

      const SchoolLesson.explain('اقرأ: ابتسامة نظيفة'),
      const SchoolLesson.explain('اقرأ: صندوق الغداء'),
      const SchoolLesson.explain('استماع: صباح بلا عجلة'),
      const SchoolLesson.explain('نشيد: جسمي نشيط'),
      const SchoolLesson.explain('تحدث: أحكي عن فرشاتي'),
      const SchoolLesson.explain('تحدث: وجبتي المتنوعة'),
      const SchoolLesson.explain('كتابة: بطاقتي'),
      const SchoolLesson.explain('كتابة: بطاقة لصديق خيالي'),
    ]),
    SchoolUnit('الرياضة والتكنولوجيا', [
      SchoolLesson('الأمر والنهي', [_i('ar_command')]),
      SchoolLesson('الحروف المتشابهة في النطق', [_i('ar_similar')]),
      SchoolLesson('الأسماء الموصولة', [_i('ar_relative')]),

      const SchoolLesson.explain('اقرأ: وقت للشاشة'),
      const SchoolLesson.explain('اقرأ: نتعاون في الملعب'),
      const SchoolLesson.explain('استماع: لعبة تناسبنا'),
      const SchoolLesson.explain('نشيد: نلعب معًا'),
      const SchoolLesson.explain('تحدث: أستخدم الحاسوب'),
      const SchoolLesson.explain('تحدث: نشاط أحبه'),
      const SchoolLesson.explain('كتابة: مشهد اللعب'),
      const SchoolLesson.explain('كتابة: بطاقة بطل خيالي'),
    ]),
  ]),
  SchoolBook('p2', 2, 'arabic', [
    SchoolUnit('من حولي', [
      SchoolLesson('ضمائر الغائب', [_i('ar_pronoun', 'ghaib')]),
      SchoolLesson('التاء المربوطة والتاء المفتوحة', [_i('ar_taa')]),
      SchoolLesson('أسلوب النداء', [_i('ar_style', 'nida')]),
    ]),
    SchoolUnit('في مدرستي', [
      SchoolLesson('أسلوب التعجب', [_i('ar_style', 'taajjub')]),
      SchoolLesson('الشدة مع التنوين', [_i('ar_shadda'), _i('ar_tanween')]),
      SchoolLesson('أسلوب الاستفهام', [_i('ar_style', 'istifham')]),
    ]),
    SchoolUnit('أماكن جميلة', [
      SchoolLesson('حروف الجر', [_i('ar_particles', 'jarr')]),
      SchoolLesson('حروف العطف', [_i('ar_particles', 'atf')]),
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
      SchoolLesson('قصص الجمع', [_i('wordProblem', 'add')]),
    ]),
    SchoolUnit('الطرح', [
      SchoolLesson('الطرح', [_i('subtraction')]),
      SchoolLesson('قصص الطرح', [_i('wordProblem', 'sub')]),
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
    SchoolUnit('تكوين أشكال', [SchoolLesson('تكوين أشكال', [_i('composeShapes')])]),
    SchoolUnit('ما الوقت؟', [SchoolLesson('ما الوقت؟', [_i('clockQuarter')])]),
    SchoolUnit('الجمع والطرح', [SchoolLesson('الجمع والطرح', [_i('addition'), _i('subtraction'), _i('wordProblem')])]),
  ]),
  SchoolBook('p2', 1, 'math', [
    SchoolUnit('البيانات', [
      SchoolLesson('التمثيل البياني بالصور', [_i('picGraph')]),
      SchoolLesson('التمثيل البياني بالأعمدة', [_i('barGraph')]),

      const SchoolLesson.explain('مقارنة رسمين بيانيين'),
    ]),
    SchoolUnit('الجمع والطرح', [
      SchoolLesson('الجمع والطرح', [_i('add100'), _i('sub100')]),
      SchoolLesson('مسائل كلامية', [_i('wordProblem')]),

      const SchoolLesson.explain('جمع عدد من رقمين وعدد من رقم واحد'),
      const SchoolLesson.explain('الجمع عندما تكتمل عشرة'),
      const SchoolLesson.explain('تبديل ترتيب العددين في الجمع'),
      const SchoolLesson.explain('الطرح الرأسي بدون إعادة تجميع'),
      const SchoolLesson.explain('طرح عدد من رقم واحد'),
      const SchoolLesson.explain('الطرح بفك عشرة'),
      const SchoolLesson.explain('طرح رقم واحد بفك عشرة'),
      const SchoolLesson.explain('العلاقة بين الجمع والطرح'),
    ]),
    SchoolUnit('الأعداد المكوّنة من ٣ أرقام', [
      SchoolLesson('الأعداد من ٣ أرقام', [_i('hundreds')]),
      const SchoolLesson.explain('الصفر في العدد'),
      const SchoolLesson.explain('القيمة المكانية للأعداد'),
      const SchoolLesson.explain('العشرات داخل المئات'),
      const SchoolLesson.explain('قراءة خط أعداد كبير'),
      const SchoolLesson.explain('العدد ألف'),
      const SchoolLesson.explain('جمع وطرح العشرات والمئات'),
      const SchoolLesson.explain('المئات مع العشرات والآحاد'),
      const SchoolLesson.explain('مقارنة الأعداد الكبيرة'),
      const SchoolLesson.explain('مقارنة عدد بناتج عملية'),
    ]),
    SchoolUnit('الجمع والطرح بإعادة التجميع', [
      const SchoolLesson('الجمع والطرح بإعادة التجميع', [
        LessonItem('add100', minLevel: 4),
        LessonItem('sub100', minLevel: 4),
      ]),
      SchoolLesson('تقدير نواتج الجمع والطرح', [_i('rounding')]),

      const SchoolLesson.explain('جمع ينتج مئات'),
      const SchoolLesson.explain('جمع بإعادة تجميع مرتين'),
      const SchoolLesson.explain('طرح بفك مئة'),
      const SchoolLesson.explain('طرح بفك مئة وعشرة'),
      const SchoolLesson.explain('الطرح عبر صفر'),
      const SchoolLesson.explain('الجمع والطرح من ثلاثة أرقام'),
    ]),
    SchoolUnit('الأشكال والقياس', [
      SchoolLesson('الأشكال الهندسية', [_i('geometry')]),
      SchoolLesson('قياس الأطوال', [_i('measure')]),

      const SchoolLesson.explain('الملليمتر'),
      const SchoolLesson.explain('الخط المستقيم وتحويل الأطوال'),
      const SchoolLesson.explain('رسم خط مستقيم بالمسطرة'),
      const SchoolLesson.explain('حساب الأطوال'),
    ]),
    SchoolUnit('الكتلة والوقت', [
      SchoolLesson('الكتلة', [_i('measure')]),
      SchoolLesson('الوقت', [_i('clockQuarter')]),

      const SchoolLesson.explain('صباحًا ومساءً'),
    ]),
    const SchoolUnit('وحدات السعة', [
      SchoolLesson.explain('الديسيلتر والسعة'),
      SchoolLesson.explain('اللتر والسعة'),
      SchoolLesson.explain('الملليلتر والسعة'),
    ]),
    const SchoolUnit('طرق الحساب الذهني', [
      SchoolLesson.explain('الحساب الذهني بتغيير الترتيب'),
      SchoolLesson.explain('الحساب الذهني بتفكيك عدد'),
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
    SchoolUnit('الطرح', [SchoolLesson('الطرح ومسائله', [_i('sub100'), _i('wordProblem', 'sub')])]),
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
      SchoolLesson('in, on, under', [_i('en_prep')]),
      _enLetters(['B', 'L', 'U', 'J']),
    ]),
  ]),
  SchoolBook('p1', 2, 'english', [
    SchoolUnit('My Week', [SchoolLesson('Days of the week', [_i('en_days')]), _enLetters(['W', 'Q', 'V', 'Z'])]),
    SchoolUnit('Feelings', [
      SchoolLesson('Feelings', [_i('en_feelings')]),
      _enLetters(['Y', 'X']),
      SchoolLesson('I, he, she, it, they', [_i('en_pronouns')]),
      SchoolLesson('Blends sk, sn, st, sw', [_i('en_sounds', 'blendS')]),
    ]),
    SchoolUnit('Seasons', [SchoolLesson('Months, seasons and weather', [_i('en_months'), _i('en_seasons'), _i('en_weather')]), SchoolLesson('Short vowels a, e', [_i('en_cvc', 'vowels:ae')])]),
    SchoolUnit('My House', [SchoolLesson('Rooms at home', [_i('en_rooms')]), SchoolLesson('Short vowels i, o', [_i('en_cvc', 'vowels:io')])]),
    SchoolUnit('Neighborhood', [
      SchoolLesson('Places and transport', [_i('en_places'), _i('en_transport')]),
      SchoolLesson('Short vowel u', [_i('en_cvc', 'vowels:u')]),
      SchoolLesson('Blends cl, bl, fl, sl', [_i('en_sounds', 'blendL')]),
    ]),
  ]),
  SchoolBook('p2', 1, 'english', [
    SchoolUnit("Let's Get Started!", [
      SchoolLesson('Classroom things', [_i('en_daily')]),
      SchoolLesson('Short vowels a, e, i', [_i('en_cvc', 'vowels:aei')]),

      const SchoolLesson.explain('Greetings and introductions'),
    ]),
    SchoolUnit('Colors, Shapes, and Numbers', [
      SchoolLesson('Colors, shapes and numbers', [_i('en_colors'), _i('en_shapes'), _i('en_numbers')]),
      SchoolLesson('Numbers 11–20', [_i('en_count100', 'to20')]),

      const SchoolLesson.explain('Short o, short u and long a'),
      const SchoolLesson.explain('Counting by tens'),
    ]),
    SchoolUnit('Classroom Actions & Routines', [
      SchoolLesson('Classroom actions', [_i('en_actions')]),
      SchoolLesson('First sounds', [_i('en_firstsound')]),
    ]),
    SchoolUnit('Everyday Life', [
      SchoolLesson('My family', [_i('en_family')]),
      SchoolLesson('Long vowels o, u and th', [_i('en_sounds', 'long:o,u'), _i('en_sounds', 'digraph:th')]),

      const SchoolLesson.explain('Daily routines'),
    ]),
    SchoolUnit('My Home', [
      SchoolLesson('My home', [_i('en_rooms'), _i('en_prep')]),
      SchoolLesson('sh and th', [_i('en_sounds', 'digraph:sh,th')]),
      const SchoolLesson.explain('Helping at home'),
    ]),
    SchoolUnit('Rooms at Home', [
      SchoolLesson('Rooms at home', [_i('en_rooms')]),
      SchoolLesson('ch', [_i('en_sounds', 'digraph:ch')]),
      const SchoolLesson.explain('There is and There are'),
    ]),
  ]),
  SchoolBook('p2', 2, 'english', [
    SchoolUnit('Our Environment', [SchoolLesson('There is / There are', [_i('en_isare')]), SchoolLesson('Long vowels a, i', [_i('en_sounds', 'long:a,i')])]),
    SchoolUnit('At the Store', [SchoolLesson('Clothes', [_i('en_clothes')]), SchoolLesson('Long vowels u, o', [_i('en_sounds', 'long:u,o')])]),
    SchoolUnit('Sports', [SchoolLesson('Plural with s', [_i('en_plural')]), SchoolLesson('Counting to 50', [_i('en_count100', 'to50')]), SchoolLesson('Sports', [_i('en_sports')]),
      SchoolLesson('Final blends', [_i('en_sounds', 'final')])]),
    SchoolUnit('Transportation', [SchoolLesson('Transportation', [_i('en_transport'), _i('en_places')])]),
    SchoolUnit('The Pyramids', [
      SchoolLesson('The Pyramids', [_i('en_reading', 'The Pyramids')]),
      SchoolLesson('Counting to 100', [_i('en_count100', 'to100')]),
    ]),
  ]),
  // ---------------------------------------------------------------- تالتة ابتدائي (من غير مراحل جديدة لسه)
  SchoolBook('p3', 1, 'arabic', [
    SchoolUnit('العمل والأمل', [
      SchoolLesson('أدوات الاستفهام', [_i('ar_style', 'istifham')]),
      SchoolLesson('المقاطع الصوتية', [_i('ar_analyze'), _i('ar_syllable')]),
      SchoolLesson('هؤلاء – أولئك', [_i('ar_far', 'plural')]),
      const SchoolLesson.explain('استماع: البذرة الصغيرة'),
      const SchoolLesson.explain('اقرأ: الطائرة الورقية'),
      const SchoolLesson.explain('اقرأ: البطل المجهول'),
      const SchoolLesson.explain('نشيد: أحاول وأنجح'),
      const SchoolLesson.explain('تحدث: أحكي عن محاولة'),
      const SchoolLesson.explain('تحدث: أشكر من ساعدني'),
      const SchoolLesson.explain('كتابة: قصة مصورة'),
      const SchoolLesson.explain('كتابة: أكمل القصة المصورة'),
    ]),
    SchoolUnit('صفاتي الجميلة', [
      SchoolLesson('المفرد والمثنى والجمع', [_i('ar_number')]),
      SchoolLesson('التنوين', [_i('ar_tanween'), _i('ar_marks')]),
      SchoolLesson('أسلوب النفي (لم – لن)', [_i('ar_negation')]),
      const SchoolLesson.explain('استماع: النحلة والوردة'),
      const SchoolLesson.explain('اقرأ: جارتنا الطيبة'),
      const SchoolLesson.explain('اقرأ: أول من تطوع'),
      const SchoolLesson.explain('نشيد: أخلاقي'),
      const SchoolLesson.explain('تحدث: أساعد غيري'),
      const SchoolLesson.explain('تحدث: أنا مبادر'),
      const SchoolLesson.explain('كتابة: نهاية جديدة لقصة'),
      const SchoolLesson.explain('كتابة: نهاية أخرى للقصة'),
    ]),
    SchoolUnit('أحب بلدي', [
      SchoolLesson('حروف الجر (عن – على)', [_i('ar_particles', 'jarr2')]),
      SchoolLesson('التاء المفتوحة والمربوطة', [_i('ar_taa')]),
      SchoolLesson('حروف العطف (ثم – ف)', [_i('ar_particles', 'atf2')]),
      const SchoolLesson.explain('استماع: الحمامة الشجاعة'),
      const SchoolLesson.explain('اقرأ: صندوق الأفكار'),
      const SchoolLesson.explain('اقرأ: يوم في المتحف'),
      const SchoolLesson.explain('نشيد: مصر بلدي'),
      const SchoolLesson.explain('تحدث: مكان جميل في بلدي'),
      const SchoolLesson.explain('تحدث: في المتحف'),
      const SchoolLesson.explain('كتابة: قصة مصورة عن رحلة'),
      const SchoolLesson.explain('كتابة: نهاية جديدة لقصة المتحف'),
    ]),
  ]),
  SchoolBook('p3', 2, 'arabic', [
    SchoolUnit('قصص من بلادي', [
      SchoolLesson('أنواع الجمع', [_i('ar_number')]),
      SchoolLesson('علامات الترقيم', [_i('ar_punct')]),
      SchoolLesson('أنواع الكلمة', [_i('ar_wordType')]),
    ]),
    SchoolUnit('أخلاق جميلة', [
      SchoolLesson('أنواع الفعل', [_i('ar_tense'), _i('ar_command')]),
      SchoolLesson('الهمزة المتطرفة بعد المد', [_i('ar_hamza')]),
    ]),
    SchoolUnit('كل منا له دور', [
      SchoolLesson('الجملة الاسمية والجملة الفعلية', [_i('ar_sentenceKind')]),
      SchoolLesson('المقاطع الصوتية', [_i('ar_analyze'), _i('ar_syllable')]),
      SchoolLesson('الأسماء الموصولة', [_i('ar_relative')]),
    ]),
  ]),
  SchoolBook('p3', 1, 'math', [
    SchoolUnit('الأنماط والبيانات والقياس', [
      SchoolLesson('الأنماط', [_i('sequence'), _i('skipCount')]),
      SchoolLesson('التمثيل البياني بالأعمدة', [_i('barGraph')]),
      SchoolLesson('التمثيل البياني بالنقاط', [_i('dotPlot')]),
      SchoolLesson('قياس الأطوال', [_i('measure')]),
      const SchoolLesson.explain('المسافة وأقصر مسافة'),
      const SchoolLesson.explain('علامات العد والجداول'),
      const SchoolLesson.explain('رسم الأعمدة البيانية'),
      const SchoolLesson.explain('تنظيم البيانات في جداول'),
    ]),
    SchoolUnit('الآلاف والضرب', [
      SchoolLesson('الآلاف', [_i('thousands')]),
      SchoolLesson('المصفوفات ومفهوم الضرب', [_i('mulGroups')]),
      SchoolLesson('خاصية الإبدال في الضرب', [_i('times2510')]),
      const SchoolLesson.explain('الضرب في صفر'),
      const SchoolLesson.explain('الأعداد الكبيرة على خط الأعداد'),
      const SchoolLesson.explain('الضرب في ١٠ والقسمة على ١٠'),
    ]),
    SchoolUnit('الضرب والقسمة والوقت', [
      SchoolLesson('مضاعفات ٢ و٣ و٤', [_i('times2510'), _i('times34')]),
      SchoolLesson('مضاعفات ٥ و١٠', [_i('times2510')]),
      SchoolLesson('الوقت', [_i('clockQuarter')]),
      SchoolLesson('مفهوم القسمة', [_i('divisionExact')]),
      SchoolLesson('العلاقة بين الضرب والقسمة', [_i('divisionMissing')]),
      const SchoolLesson.explain('المدة الزمنية'),
      const SchoolLesson.explain('الدقيقة والثانية'),
      const SchoolLesson.explain('التوزيع والقسمة'),
      const SchoolLesson.explain('حالات استخدام القسمة'),
      const SchoolLesson.explain('القسمة للمقارنة'),
    ]),
    SchoolUnit('المضلعات والمساحة', [
      SchoolLesson('المضلعات والأشكال الرباعية', [_i('geometry')]),
      SchoolLesson('المساحة', [_i('areaPerimeter', 'area')]),
    ]),
    SchoolUnit('المحيط والمساحة', [
      SchoolLesson('المحيط والمساحة', [_i('areaPerimeter')]),
      SchoolLesson('الضرب في مضاعفات ١٠', [_i('mulStrategies', 'tens')]),
    ]),
    SchoolUnit('استراتيجيات الضرب والجمع والطرح', [
      SchoolLesson('الضرب في ٩', [_i('times6789')]),
      SchoolLesson('مقارنة وترتيب الأعداد', [_i('hundreds')]),
      SchoolLesson('الجمع والطرح', [_i('add100'), _i('sub100')]),
      SchoolLesson('السعة', [_i('measure')]),
      const SchoolLesson.explain('طرح الأعداد الكبيرة'),
      const SchoolLesson.explain('الطرح عبر الأصفار'),
      const SchoolLesson.explain('مسائل الجمع والطرح'),
    ]),
    const SchoolUnit('الحساب الذهني', [
      SchoolLesson.explain('الحساب الذهني للجمع'),
      SchoolLesson.explain('الحساب الذهني للطرح'),
    ]),
    const SchoolUnit('القسمة مع الباقي', [
      SchoolLesson.explain('القسمة مع الباقي'),
      SchoolLesson.explain('التحقق من الإجابة'),
      SchoolLesson.explain('استخدام القسمة مع الباقي'),
      SchoolLesson.explain('مسائل القسمة مع الباقي'),
    ]),
    const SchoolUnit('الضرب الرأسي', [
      SchoolLesson.explain('الضرب في العشرات والمئات'),
      SchoolLesson.explain('ضرب عدد من رقمين في رقم'),
      SchoolLesson.explain('ضرب عدد من ٣ أرقام في رقم'),
      SchoolLesson.explain('قواعد الضرب الرأسي'),
      SchoolLesson.explain('استخدام الضرب'),
    ]),
  ]),
  SchoolBook('p3', 2, 'math', [
    SchoolUnit('خواص الضرب', [
      SchoolLesson('خاصية التجميع والتوزيع', [_i('mulStrategies', 'props')]),
      SchoolLesson('تقدير ناتج الضرب', [_i('mulStrategies', 'estimate')]),
      SchoolLesson('الضرب والقسمة', [_i('timesAll'), _i('divisionExact')]),
      SchoolLesson('محيط المربع والمستطيل', [_i('areaPerimeter', 'perimeter')]),
      SchoolLesson('مسائل كلامية', [_i('wordProblem')]),
    ]),
    SchoolUnit('الكسور', [SchoolLesson('كسور الوحدة', [_i('fractionOfNumber')])]),
    SchoolUnit('الكسور على خط الأعداد', [SchoolLesson('مقارنة الكسور', [_i('fractionEquivalent')])]),
    SchoolUnit('الكسور المتكافئة والقسمة', [
      SchoolLesson('الكسور المتكافئة', [_i('fractionEquivalent')]),
      SchoolLesson('القسمة', [_i('divisionExact'), _i('divisionMissing')]),
    ]),
    SchoolUnit('حقائق الضرب والمحيط والمساحة', [
      SchoolLesson('حقائق الضرب', [_i('timesAll')]),
      SchoolLesson('المحيط والمساحة', [_i('areaPerimeter')]),
    ]),
    SchoolUnit('الكسور والوقت والبيانات', [
      SchoolLesson('تكوين أنصاف', [_i('fractionOfNumber')]),
      SchoolLesson('الوقت المنقضي', [_i('unitConvert', 'elapsed'), _i('clockQuarter')]),
      SchoolLesson('التمثيلات البيانية', [_i('barGraph')]),
    ]),
  ]),
  SchoolBook('p3', 1, 'english', [
    SchoolUnit("Let's Learn Together!", [
      SchoolLesson('Greetings', [_i('en_phrases')]),
      SchoolLesson('I am, you are, he is', [_i('en_isare')]),
      const SchoolLesson.explain('Digraph wh'),
    ]),
    SchoolUnit('My Family and I', [
      SchoolLesson('Family', [_i('en_family')]),
      SchoolLesson('my, his, her', [_i('en_possessive')]),
      const SchoolLesson.explain('ph and x'),
    ]),
    SchoolUnit('New Adventures', [
      SchoolLesson('Places', [_i('en_places')]),
      SchoolLesson('in, on, under', [_i('en_prep')]),
      SchoolLesson('Past tense: walked, played', [_i('en_past', 'regular')]),
      const SchoolLesson.explain('zz, ss, ll and ck'),
    ]),
    SchoolUnit("Let's Tell Stories!", [
      SchoolLesson('Feelings', [_i('en_feelings')]),
      SchoolLesson('Past simple stories', [_i('en_past', 'irregular')]),
      const SchoolLesson.explain('Hard and soft c'),
    ]),
    SchoolUnit('Together Is Better', [
      SchoolLesson('Actions', [_i('en_actions')]),
      const SchoolLesson.explain('Hard and soft g'),
      const SchoolLesson.explain('Chores'),
    ]),
    const SchoolUnit('Dare to Dream', [
      SchoolLesson.explain('Present continuous'),
      SchoolLesson.explain('spr, spl, scr'),
      SchoolLesson.explain('Goals and success'),
    ]),
  ]),
  SchoolBook('p3', 2, 'english', [
    SchoolUnit('Safety', [SchoolLesson("Stop! Don't touch!", [_i('en_safety')]), SchoolLesson('Blends sl, st, gr, tr', [_i('en_sounds', 'blendS')])]),
    SchoolUnit('Food and Health', [SchoolLesson('a, an', [_i('en_a_an')]), SchoolLesson('Food words', [_i('en_food')])]),
    SchoolUnit('Heroes Around Us', [SchoolLesson('Magic e', [_i('en_sounds', 'long')])]),
    SchoolUnit('Living with Technology', [SchoolLesson('and, or, but', [_i('en_conj')])]),
    SchoolUnit('Animals & Habitats', [SchoolLesson('Animals', [_i('en_animals')]), SchoolLesson("can, can't", [_i('en_can')])]),
  ]),
  // ---------------------------------------------------------------- رابعة ابتدائي
  SchoolBook('p4', 1, 'arabic', [
    SchoolUnit('أنا وحلمي', [
      SchoolLesson('أنواع الكلمة وعلامات الاسم', [_i('ar_wordType'), _i('ar_nounSigns')]),
      SchoolLesson('دخول فـ بـ كـ لـ على «ال»', [_i('ar_alPrefix')]),
      SchoolLesson('المفرد والمثنى والجمع', [_i('ar_number')]),
      const SchoolLesson.explain('استماع: حلم مريم'),
      const SchoolLesson.explain('اقرأ: دفتر الأحلام'),
      const SchoolLesson.explain('اقرأ: أنا أستطيع'),
      const SchoolLesson.explain('نشيد: مصر بلادي'),
      const SchoolLesson.explain('تحدث: أحكي عن حلمي'),
      const SchoolLesson.explain('تحدث: أواجه تحديًا'),
      const SchoolLesson.explain('كتابة: رسالة شخصية'),
      const SchoolLesson.explain('كتابة: رسالة إلى صديق'),
    ]),
    SchoolUnit('أخلاقي حياتي', [
      SchoolLesson('الضمائر', [_i('ar_pronoun')]),
      SchoolLesson('علامات الترقيم', [_i('ar_punct')]),
      SchoolLesson('ركنا الجملة الاسمية', [_i('ar_mubtada', 'single')]),
      const SchoolLesson.explain('استماع: الكلمة الطيبة'),
      const SchoolLesson.explain('اقرأ: الهدية التي لا تُشترى'),
      const SchoolLesson.explain('اقرأ: لحظة تفكير'),
      const SchoolLesson.explain('نشيد: أخلاقي نور'),
      const SchoolLesson.explain('تحدث: موقف لطيف رأيته'),
      const SchoolLesson.explain('تحدث: أهدأ قبل أن أتكلم'),
      const SchoolLesson.explain('كتابة: مناقشة فكرة'),
      const SchoolLesson.explain('كتابة: أناقش فكرة أخرى'),
    ]),
    SchoolUnit('رسالة من أطفال مصر', [
      SchoolLesson('المبتدأ والخبر المثنى', [_i('ar_mubtada', 'dual')]),
      SchoolLesson('حروف تُنطق ولا تُكتب', [_i('ar_hiddenAlif')]),
      SchoolLesson('المبتدأ والخبر جمع المذكر السالم', [_i('ar_mubtada', 'plural')]),
      const SchoolLesson.explain('استماع: النهر يتكلم'),
      const SchoolLesson.explain('اقرأ: الحديقة التي عادت'),
      const SchoolLesson.explain('اقرأ: خطوات صغيرة لكوكب كبير'),
      const SchoolLesson.explain('نشيد: بستاني الأخضر'),
      const SchoolLesson.explain('تحدث: رسالة إلى الطبيعة'),
      const SchoolLesson.explain('تحدث: أنا صديق البيئة'),
      const SchoolLesson.explain('كتابة: رسالة شخصية عن البيئة'),
      const SchoolLesson.explain('كتابة: أناقش فكرة عن البيئة'),
    ]),
  ]),
  SchoolBook('p4', 2, 'arabic', [
    SchoolUnit('أخلاقي تصنع عالمي', [
      SchoolLesson('مراجعة المبتدأ والخبر', [_i('ar_mubtada')]),
      SchoolLesson('الألف اللينة في الحروف', [_i('ar_alifLayyina', 'harf')]),
      SchoolLesson('الجملة الفعلية: الفعل والفاعل', [_i('ar_fail', 'single')]),
    ]),
    SchoolUnit('أحلم وأخطط', [
      SchoolLesson('الفاعل: المفرد وجمع التكسير وجمع المؤنث', [_i('ar_fail', 'single')]),
      SchoolLesson('الألف اللينة في الأسماء', [_i('ar_alifLayyina', 'ism')]),
      SchoolLesson('الفاعل: المثنى وجمع المذكر السالم', [_i('ar_fail', 'dual')]),
    ]),
    SchoolUnit('نعيش في سلام', [
      SchoolLesson('إفراد الفعل مع فاعله', [_i('ar_fail', 'agree')]),
      SchoolLesson('الألف اللينة في الأفعال', [_i('ar_alifLayyina', 'fiil')]),
      SchoolLesson('الضمائر والفاعل الضمير', [_i('ar_pronoun')]),
    ]),
  ]),
  SchoolBook('p4', 1, 'math', [
    SchoolUnit('القيمة المكانية', [
      SchoolLesson('الأعداد الكبيرة والقيمة المكانية', [_i('thousands')]),
      SchoolLesson('مقارنة وترتيب الأعداد', [_i('thousands')]),
      SchoolLesson('قواعد التقريب', [_i('roundLarge')]),
      const SchoolLesson.explain('تغيير القيم المكانية'),
      const SchoolLesson.explain('صيغ كتابة الأعداد'),
      const SchoolLesson.explain('تكوين الأعداد وتحليلها'),
      const SchoolLesson.explain('مقارنة الأعداد في صيغ مختلفة'),
      const SchoolLesson.explain('ترتيب الأعداد تصاعديًا وتنازليًا'),
    ]),
    SchoolUnit('استراتيجيات الجمع والطرح', [
      SchoolLesson('الجمع والطرح بإعادة التسمية', [_i('bigAddSub')]),
      SchoolLesson('المسائل متعددة الخطوات', [_i('bigAddSub'), _i('wordProblem')]),
      const SchoolLesson.explain('خواص عملية الجمع'),
      const SchoolLesson.explain('النماذج الشريطية والمسائل الكلامية'),
      const SchoolLesson.explain('الطرح مع إعادة التسمية'),
    ]),
    SchoolUnit('مفاهيم القياس', [
      SchoolLesson('الطول والكتلة والسعة', [_i('unitConvert')]),
      SchoolLesson('قياس الوقت والوقت المنقضي', [_i('unitConvert', 'elapsed'), _i('clockQuarter')]),
      const SchoolLesson.explain('قياس الكتلة'),
      const SchoolLesson.explain('وحدات قياس السعة'),
      const SchoolLesson.explain('الوقت المنقضي'),
      const SchoolLesson.explain('تطبيقات القياس 1'),
      const SchoolLesson.explain('تطبيقات القياس 2'),
    ]),
    SchoolUnit('المساحة والمحيط', [
      SchoolLesson('المحيط', [_i('areaPerimeter', 'perimeter')]),
      SchoolLesson('المساحة', [_i('areaPerimeter', 'area')]),
      SchoolLesson('أبعاد مجهولة والأشكال المركبة', [_i('areaPerimeter')]),
      const SchoolLesson.explain('الأشكال الهندسية المركبة'),
    ]),
    SchoolUnit('الضرب كعلاقة', [
      SchoolLesson('المقارنة باستخدام الضرب', [_i('mulCompare')]),
      SchoolLesson('خواص الضرب وأنماطه', [_i('mulCompare'), _i('mulStrategies', 'props')]),
      const SchoolLesson.explain('معادلات المقارنة بالضرب'),
      const SchoolLesson.explain('العنصر المحايد والضرب في صفر'),
      const SchoolLesson.explain('خاصية الدمج في الضرب'),
      const SchoolLesson.explain('تطبيق الأنماط في الضرب'),
    ]),
    SchoolUnit('العوامل والمضاعفات', [
      SchoolLesson('العوامل والأعداد الأولية', [_i('factors', 'factors')]),
      SchoolLesson('المضاعفات', [_i('factors', 'multiples')]),
      const SchoolLesson.explain('العامل المشترك الأكبر'),
      const SchoolLesson.explain('المضاعفات المشتركة'),
      const SchoolLesson.explain('العلاقات بين العوامل والمضاعفات'),
    ]),
    SchoolUnit('الضرب والقسمة', [
      SchoolLesson('الضرب في عدد من رقم أو رقمين', [_i('longMulDiv', 'mul'), _i('mulStrategies', 'tens')]),
      SchoolLesson('القسمة على عدد من رقم واحد', [_i('longMulDiv', 'div')]),
      const SchoolLesson.explain('إستراتيجية نموذج مساحة المستطيل'),
      const SchoolLesson.explain('خاصية التوزيع'),
      const SchoolLesson.explain('خوارزمية الضرب بالتجزئة'),
      const SchoolLesson.explain('استكشاف باقي القسمة'),
      const SchoolLesson.explain('الأنماط في عملية القسمة'),
      const SchoolLesson.explain('القسمة باستخدام نموذج مساحة المستطيل'),
      const SchoolLesson.explain('خوارزمية خارج القسمة بالتجزئة'),
      const SchoolLesson.explain('خوارزمية القسمة المعيارية'),
      const SchoolLesson.explain('القسمة والضرب'),
    ]),
    SchoolUnit('ترتيب العمليات', [
      SchoolLesson('ترتيب العمليات', [_i('orderOps')]),
      const SchoolLesson.explain('ترتيب العمليات والمسائل الكلامية'),
    ]),
  ]),
  SchoolBook('p4', 2, 'math', [
    SchoolUnit('الكسور الاعتيادية', [
      SchoolLesson('كسور الوحدة وتحليل الكسور', [_i('fractionOfNumber'), _i('fractionOps', 'addsub')]),
      SchoolLesson('الأعداد الكسرية', [_i('fractionOps', 'mixed')]),
      SchoolLesson('جمع وطرح الكسور', [_i('fractionOps', 'addsub')]),
      SchoolLesson('مقارنة الكسور', [_i('fractionOps', 'compare')]),
      SchoolLesson('الكسور المتكافئة', [_i('fractionEquivalent')]),
      SchoolLesson('ضرب كسر في عدد', [_i('fractionOps', 'times')]),
    ]),
    SchoolUnit('الكسور العشرية', [
      SchoolLesson('الأعشار والأجزاء من مئة', [_i('decimals')]),
      SchoolLesson('مقارنة وجمع الكسور العشرية', [_i('decimals')]),
    ]),
    SchoolUnit('بيانات تحتوي على كسور', [
      SchoolLesson('التمثيل البياني بالنقاط', [_i('dotPlot')]),
      SchoolLesson('تحليل التمثيل البياني', [_i('barGraph')]),
    ]),
    SchoolUnit('الهندسة', [
      SchoolLesson('النقاط والخطوط والتوازي والتعامد', [_i('geometry4', 'lines')]),
      SchoolLesson('تصنيف الزوايا', [_i('geometry4', 'angles')]),
      SchoolLesson('تصنيف المثلثات والأشكال الرباعية', [_i('geometry4', 'shapes')]),
    ]),
    SchoolUnit('الزوايا والدائرة', [SchoolLesson('قياس الزوايا', [_i('geometry4', 'angles')])]),
  ]),
  SchoolBook('p4', 1, 'english', [
    SchoolUnit('The Five Senses', [
      SchoolLesson('Present simple', [_i('en_present', 'affirm')]),
      SchoolLesson('My senses', [_i('en_body')]),
      const SchoolLesson.explain('Short and long vowels'),
      const SchoolLesson.explain('Healthy habits'),
    ]),
    SchoolUnit('My Community', [
      SchoolLesson("don't, doesn't, Do, Does", [_i('en_present', 'negq')]),
      SchoolLesson('Places', [_i('en_places')]),
      const SchoolLesson.explain('Sounds f and v'),
      const SchoolLesson.explain('Helping the community'),
      const SchoolLesson.explain('Writing a diary entry'),
    ]),
    SchoolUnit('Animals in Our World', [
      SchoolLesson('bigger, taller', [_i('en_compare', 'comp')]),
      SchoolLesson('Animals', [_i('en_animals')]),
      const SchoolLesson.explain('Blends fr, dr, pl'),
      const SchoolLesson.explain('Endangered animals'),
    ]),
    SchoolUnit('Egypt – My Homeland', [
      SchoolLesson('next to, between', [_i('en_prep2')]),
      SchoolLesson('in, on, under', [_i('en_prep')]),
      const SchoolLesson.explain('Places in Egypt'),
      const SchoolLesson.explain('Sounds p and b'),
      const SchoolLesson.explain('Writing a blog post'),
    ]),
    SchoolUnit('A Day at Work', [
      SchoolLesson('Jobs', [_i('en_jobs')]),
      SchoolLesson('the biggest, the tallest', [_i('en_compare', 'super')]),
      const SchoolLesson.explain('Silent e'),
      const SchoolLesson.explain('Heroes at work'),
    ]),
    SchoolUnit('The Hundred Dresses', [
      SchoolLesson('Reading: Kind Words', [_i('en_reading', 'Kind Words')]),
      const SchoolLesson.explain('Story elements'),
      const SchoolLesson.explain('Words about kindness'),
      const SchoolLesson.explain('Writing a reply letter'),
    ]),
  ]),
  SchoolBook('p4', 2, 'english', [
    SchoolUnit('This is Where I Live', [
      SchoolLesson('Places and environments', [_i('en_environment')]),
      SchoolLesson('Past simple', [_i('en_past')]),
    ]),
    SchoolUnit('Our World, Our Responsibility', [
      SchoolLesson('and, or, but', [_i('en_conj')]),
      SchoolLesson('Going green', [_i('en_environment')]),
    ]),
    SchoolUnit("What's in the Package?", [SchoolLesson('a bottle of, a slice of', [_i('en_containers')])]),
    SchoolUnit("Let's Celebrate", [SchoolLesson('Celebrations', [_i('en_celebrate')])]),
    SchoolUnit('Exploring Wonders in Egypt', [SchoolLesson("should, shouldn't", [_i('en_should')])]),
    SchoolUnit('Story Time: The Lost Kite', [SchoolLesson('Reading: The Lost Kite', [_i('en_reading', 'The Lost Kite')])]),
  ]),
  // ---------------------------------------------------------------- خامسة ابتدائي
  SchoolBook('p5', 1, 'arabic', [
    SchoolUnit('نيلنا أمانة', [
      SchoolLesson('المفعول به', [_i('ar_mafool', 'single')]),
      SchoolLesson('همزة القطع وألف الوصل', [_i('ar_hamzaQat')]),
      SchoolLesson('المفعول به: المفرد وجمع التكسير', [_i('ar_mafool', 'single')]),
      const SchoolLesson.explain('استماع: النيل شريان الحياة'),
      const SchoolLesson.explain('اقرأ: النهر يشكو'),
      const SchoolLesson.explain('اقرأ: بطلة حل المشكلات'),
      const SchoolLesson.explain('نشيد: عطاء النيل'),
      const SchoolLesson.explain('تحدث: أقدّم عرضًا عن النيل'),
      const SchoolLesson.explain('تحدث: خطوات حل المشكلات'),
      const SchoolLesson.explain('كتابة: رسالة رسمية'),
      const SchoolLesson.explain('كتابة: رسالة رسمية عن مشكلة'),
    ]),
    SchoolUnit('فن التواصل', [
      SchoolLesson('المفعول به: جمع المؤنث السالم', [_i('ar_mafool', 'fem')]),
      SchoolLesson('الهمزة المتطرفة على السطر', [_i('ar_hamzaEnd', 'line')]),
      SchoolLesson('المفعول به: المثنى وجمع المذكر السالم', [_i('ar_mafool', 'dual')]),
      const SchoolLesson.explain('استماع: جسر من الكلمات'),
      const SchoolLesson.explain('اقرأ: لغة تحمي الوطن'),
      const SchoolLesson.explain('اقرأ: رسالة عبر الزمن'),
      const SchoolLesson.explain('نشيد: أخي الإنسان'),
      const SchoolLesson.explain('تحدث: سحر اللغات'),
      const SchoolLesson.explain('تحدث: وسائل التواصل عبر العصور'),
      const SchoolLesson.explain('كتابة: اكتب يومياتك'),
      const SchoolLesson.explain('كتابة: يومية عن موقف تواصل'),
    ]),
    SchoolUnit('جمال الاختلاف', [
      SchoolLesson('المفعول لأجله', [_i('ar_mafaeel', 'ajlih')]),
      SchoolLesson('الهمزة المتطرفة على الألف', [_i('ar_hamzaEnd', 'alif')]),
      SchoolLesson('إعراب ظرفي الزمان والمكان', [_i('ar_mafaeel', 'zarf'), _i('ar_adverb')]),
      const SchoolLesson.explain('استماع: التنوع حياة'),
      const SchoolLesson.explain('اقرأ: كيف يصبح العالم أجمل؟'),
      const SchoolLesson.explain('اقرأ: حائرة أمام بائع الزهور'),
      const SchoolLesson.explain('نشيد: ألوان قوس قزح'),
      const SchoolLesson.explain('تحدث: مهرجان الأطعمة التقليدية'),
      const SchoolLesson.explain('تحدث: الاختلاف قوة'),
      const SchoolLesson.explain('كتابة: رسالة رسمية للمشاركة في مهرجان'),
      const SchoolLesson.explain('كتابة: يومية عن يوم مختلف'),
    ]),
  ]),
  SchoolBook('p5', 2, 'arabic', [
    SchoolUnit('الاختيار والمسئولية', [
      SchoolLesson('المفعول المطلق', [_i('ar_mafaeel', 'mutlaq')]),
      SchoolLesson('الهمزة المتطرفة على الواو', [_i('ar_hamzaEnd', 'waw')]),
      SchoolLesson('الاسم المجرور', [_i('ar_majrur', 'jar')]),
    ]),
    SchoolUnit('أخلاقيات التواصل', [
      SchoolLesson('الاسم المجرور: المثنى وجمع المذكر السالم', [_i('ar_majrur', 'jar')]),
      SchoolLesson('الهمزة المتطرفة على الياء', [_i('ar_hamzaEnd', 'yaa')]),
      SchoolLesson('المضاف والمضاف إليه', [_i('ar_majrur', 'idafa')]),
    ]),
    SchoolUnit('أنا وصورتي في أعين الآخرين', [
      SchoolLesson('المضاف إليه بأنواعه', [_i('ar_majrur', 'idafa')]),
      SchoolLesson('تنوين الهمزة المتطرفة', [_i('ar_hamzaEnd')]),
    ]),
  ]),
  SchoolBook('p5', 1, 'math', [
    SchoolUnit('القيمة المكانية للأعداد العشرية', [
      SchoolLesson('الكسور العشرية حتى جزء من الألف', [_i('decimals5', 'place')]),
      SchoolLesson('مقارنة وتقريب الكسور العشرية', [_i('decimals5', 'round'), _i('decimals')]),
      SchoolLesson('جمع وطرح الكسور العشرية', [_i('decimals5', 'addsub')]),
      const SchoolLesson.explain('تغيير القيم المكانية'),
      const SchoolLesson.explain('تكوين الكسور العشرية وتحليلها'),
      const SchoolLesson.explain('تقريب الكسور العشرية'),
      const SchoolLesson.explain('تقدير مجموع الأعداد العشرية'),
      const SchoolLesson.explain('تقدير الفرق بين عددين عشريين'),
      const SchoolLesson.explain('طرح الكسور العشرية حتى جزء من الألف'),
      const SchoolLesson.explain('مسائل كلامية على الكسور العشرية'),
    ]),
    SchoolUnit('العلاقات بين الأعداد', [
      SchoolLesson('التعبيرات والمعادلات والمتغيرات', [_i('equations')]),
      SchoolLesson('العوامل الأولية والعامل المشترك الأكبر', [_i('divisibility', 'prime'), _i('factors', 'gcf')]),
      SchoolLesson('المضاعفات والمضاعف المشترك الأصغر', [_i('factors', 'multiples'), _i('factors', 'common')]),
      const SchoolLesson.explain('المتغيرات في المعادلات'),
      const SchoolLesson.explain('القصص والأعداد'),
      const SchoolLesson.explain('عوامل أم مضاعفات؟'),
    ]),
    SchoolUnit('ضرب الأعداد الصحيحة', [
      SchoolLesson('الضرب في عدد من رقمين', [_i('longMulDiv', 'mul'), _i('mulStrategies', 'props')]),
      const SchoolLesson.explain('نموذج مساحة المستطيل في الضرب'),
      const SchoolLesson.explain('خاصية التوزيع في الضرب'),
      const SchoolLesson.explain('ضرب الأعداد متعددة الأرقام'),
      const SchoolLesson.explain('مسائل كلامية على الضرب'),
    ]),
    SchoolUnit('القسمة على أعداد صحيحة', [
      SchoolLesson('القسمة وتقدير خارج القسمة', [_i('longMulDiv', 'div')]),
      const SchoolLesson.explain('القسمة باستخدام نموذج مساحة المستطيل'),
      const SchoolLesson.explain('خوارزمية القسمة على عدد من رقمين'),
      const SchoolLesson.explain('علاقة القسمة بالضرب'),
      const SchoolLesson.explain('مسائل القسمة متعددة الخطوات'),
    ]),
    SchoolUnit('الضرب والقسمة مع الكسور العشرية', [
      SchoolLesson('الضرب والقسمة على قوى العدد ١٠', [_i('decimals5', 'powers')]),
      SchoolLesson('ضرب الكسور العشرية', [_i('decimals5', 'mul')]),
      SchoolLesson('الكسور العشرية والنظام المتري', [_i('unitConvert')]),
      const SchoolLesson.explain('ضرب الكسور العشرية في أعداد صحيحة'),
      const SchoolLesson.explain('ضرب الأجزاء من عشرة في أجزاء من عشرة'),
      const SchoolLesson.explain('ضرب الكسور العشرية باستخدام نموذج مساحة المستطيل'),
      const SchoolLesson.explain('ضرب الكسور العشرية حتى جزء من الألف'),
      const SchoolLesson.explain('القياس والكسور العشرية وقوى العدد 10'),
      const SchoolLesson.explain('حل مسائل كلامية متعددة الخطوات'),
      const SchoolLesson.explain('الأنماط والعلاقات في قوى العدد 10'),
      const SchoolLesson.explain('قسمة كسور عشرية على أعداد صحيحة'),
      const SchoolLesson.explain('قسمة كسور عشرية على كسور عشرية'),
    ]),
    SchoolUnit('التعبيرات العددية والأنماط', [
      SchoolLesson('ترتيب العمليات والأقواس', [_i('orderOps')]),
      SchoolLesson('الأنماط العددية', [_i('sequence'), _i('skipCount')]),
      const SchoolLesson.explain('كتابة تعبير عددي لتمثيل موقف'),
    ]),
  ]),
  SchoolBook('p5', 2, 'math', [
    SchoolUnit('جمع الكسور وطرحها', [SchoolLesson('الكسور غير متحدة المقام', [_i('fractions5', 'addsub')])]),
    SchoolUnit('الأعداد الكسرية', [SchoolLesson('جمع وطرح الأعداد الكسرية', [_i('fractions5', 'mixed'), _i('fractionOps', 'mixed')])]),
    SchoolUnit('ضرب الكسور وقسمتها', [
      SchoolLesson('ضرب الكسور', [_i('fractions5', 'mul'), _i('fractionOps', 'times')]),
      SchoolLesson('قسمة كسور الوحدة', [_i('fractions5', 'div')]),
    ]),
    SchoolUnit('الأشكال الهندسية والمستوى الإحداثي', [
      SchoolLesson('تصنيف الأشكال والمثلثات', [_i('geometry4', 'shapes')]),
      SchoolLesson('المساحة', [_i('areaPerimeter', 'area')]),
      SchoolLesson('المستوى الإحداثي', [_i('coordinates')]),
    ]),
    SchoolUnit('الحجم', [SchoolLesson('الحجم والسعة', [_i('volume')])]),
    SchoolUnit('القطاعات الدائرية', [SchoolLesson('القطاعات الدائرية', [_i('pieChart')])]),
  ]),
  SchoolBook('p5', 1, 'english', [
    SchoolUnit('Food, Nature, and Culture', [
      SchoolLesson('always, sometimes, never', [_i('en_frequency')]),
      SchoolLesson('Food', [_i('en_food')]),
      const SchoolLesson.explain('Consonant clusters'),
      const SchoolLesson.explain('Life along the Nile'),
      const SchoolLesson.explain('Writing a recipe and a flyer'),
    ]),
    SchoolUnit('My Healthy Body', [
      SchoolLesson('a, an, some, any', [_i('en_someAny'), _i('en_a_an')]),
      SchoolLesson('My body', [_i('en_body')]),
      const SchoolLesson.explain('One-syllable words'),
      const SchoolLesson.explain('Your amazing heart'),
      const SchoolLesson.explain('My health goals'),
    ]),
    SchoolUnit('When Nature Changes', [
      SchoolLesson("Did you…? I didn't", [_i('en_did')]), SchoolLesson('Weather', [_i('en_nature'), _i('en_weather')]),
      const SchoolLesson.explain('Vowel digraphs'),
      const SchoolLesson.explain('When the storm came'),
      const SchoolLesson.explain('Writing a story in the past'),
    ]),
    SchoolUnit('My Community', [
      SchoolLesson('in, on, at (time)', [_i('en_inOnAt')]),
      SchoolLesson('Places', [_i('en_places')]),
      const SchoolLesson.explain('Trigraphs'),
      const SchoolLesson.explain('Old and new cities'),
      const SchoolLesson.explain('Writing a first-person story'),
    ]),
    SchoolUnit('Our World, Our Resources', [
      SchoolLesson('bigger, taller', [_i('en_compare', 'comp')]),
      const SchoolLesson.explain('Prefixes'),
      const SchoolLesson.explain("Egypt's natural resources"),
      const SchoolLesson.explain('An object tells its story'),
    ]),
    SchoolUnit('The Talking Earth', [
      SchoolLesson('Reading: The Talking Earth', [_i('en_reading', 'The Talking Earth')]),
      const SchoolLesson.explain('Story elements: nature and feelings'),
      const SchoolLesson.explain('Words from the wetland'),
      const SchoolLesson.explain('Writing a reflection'),
    ]),
  ]),
  SchoolBook('p5', 2, 'english', [
    SchoolUnit('Hobbies Make Us Shine', [SchoolLesson('Hobbies', [_i('en_hobbies')]), SchoolLesson('can, could', [_i('en_could')])]),
    SchoolUnit("At the Doctor's", [SchoolLesson("At the doctor's", [_i('en_health')]), SchoolLesson('have to, must', [_i('en_haveTo'), _i('en_safety')])]),
    SchoolUnit('Suitcase Stories', [SchoolLesson('going to', [_i('en_goingTo')])]),
    SchoolUnit('Jobs in the Animal Kingdom', [SchoolLesson('Present simple or continuous', [_i('en_continuous')])]),
    SchoolUnit('Our Solar System', [SchoolLesson('Space', [_i('en_space')]), SchoolLesson('bigger, the biggest', [_i('en_compare')])]),
    SchoolUnit('Offline but Happy', [SchoolLesson('Reading: Offline but Happy', [_i('en_reading', 'Offline but Happy')])]),
  ]),
  // ---------------------------------------------------------------- سادسة ابتدائي
  SchoolBook('p6', 1, 'arabic', [
    SchoolUnit('أطور ذاتي', [
      SchoolLesson('الاسم النكرة والاسم المعرفة', [_i('ar_nakira', 'nakira')]),
      SchoolLesson('الهمزة المتوسطة على الألف', [_i('ar_hamzaMid', 'alif')]),
      SchoolLesson('أنواع المعارف', [_i('ar_nakira', 'types')]),
      const SchoolLesson.explain('استماع: ساعة واحدة كل يوم'),
      const SchoolLesson.explain('اقرأ: الوقت كنز'),
      const SchoolLesson.explain('اقرأ: قرار ليلى'),
      const SchoolLesson.explain('نشيد: يا شباب الغد'),
      const SchoolLesson.explain('تحدث: الوقت من ذهب'),
      const SchoolLesson.explain('تحدث: أصنع قراري'),
      const SchoolLesson.explain('كتابة: نص معلوماتي'),
      const SchoolLesson.explain('كتابة: نص معلوماتي عن مهارة'),
    ]),
    SchoolUnit('أنا مسئول', [
      SchoolLesson('الأسماء الخمسة وعلاماتها الإعرابية', [_i('ar_asmaa5')]),
      SchoolLesson('الهمزة المتوسطة على الياء (النبرة)', [_i('ar_hamzaMid', 'yaa')]),
      SchoolLesson('أنواع الخبر', [_i('ar_khabarType')]),
      const SchoolLesson.explain('استماع: سر الناجحين'),
      const SchoolLesson.explain('اقرأ: قوة الكلمة'),
      const SchoolLesson.explain('اقرأ: سر القوة والنجاح'),
      const SchoolLesson.explain('نشيد: بناة الغد'),
      const SchoolLesson.explain('تحدث: أثر الكلمة'),
      const SchoolLesson.explain('تحدث: كن مسئولًا'),
      const SchoolLesson.explain('كتابة: التقرير'),
      const SchoolLesson.explain('كتابة: تقرير عن مسئولية'),
    ]),
    SchoolUnit('العلم والخيال والمستقبل', [
      SchoolLesson('كان وأخواتها', [_i('ar_kana', 'kana')]),
      SchoolLesson('الهمزة المتوسطة على الواو', [_i('ar_hamzaMid', 'waw')]),
      SchoolLesson('إن وأخواتها', [_i('ar_kana', 'inna')]),
      const SchoolLesson.explain('استماع: من الخيال إلى الواقع'),
      const SchoolLesson.explain('اقرأ: من وراء الكاميرا؟'),
      const SchoolLesson.explain('اقرأ: رحلة إلى المستقبل'),
      const SchoolLesson.explain('نشيد: سعادة الأوطان'),
      const SchoolLesson.explain('تحدث: التكنولوجيا في حياتي'),
      const SchoolLesson.explain('تحدث: حلم يصنع المستقبل'),
      const SchoolLesson.explain('كتابة: نص معلوماتي عن اختراع'),
      const SchoolLesson.explain('كتابة: تقرير عن معرض علمي'),
    ]),
  ]),
  SchoolBook('p6', 2, 'arabic', [
    SchoolUnit('أنا ومصر.. قصة حضارة وهوية', [
      SchoolLesson('النعت المفرد', [_i('ar_naat', 'naat')]),
      SchoolLesson('الهمزة المتوسطة على السطر', [_i('ar_hamzaMid', 'line')]),
      SchoolLesson('الحال المفردة', [_i('ar_naat', 'hal')]),
    ]),
    SchoolUnit('قيم تبني الإنسان', [
      SchoolLesson('الفعل الصحيح الآخر والمعتل الآخر', [_i('ar_mudari', 'illa')]),
      SchoolLesson('تطبيقات على الهمزة المتطرفة', [_i('ar_hamzaEnd')]),
      SchoolLesson('جزم الفعل المضارع', [_i('ar_mudari', 'jazm')]),
    ]),
    SchoolUnit('العلم يصنع المستقبل', [
      SchoolLesson('رفع الفعل المضارع', [_i('ar_mudari', 'raf')]),
      SchoolLesson('الأفعال الخمسة', [_i('ar_mudari', 'five')]),
    ]),
  ]),
  SchoolBook('p6', 1, 'math', [
    SchoolUnit('قابلية القسمة والعوامل والمضاعفات', [
      SchoolLesson('قابلية القسمة والعوامل الأولية', [_i('divisibility')]),
      SchoolLesson('العامل المشترك الأكبر والمضاعف المشترك الأصغر', [_i('factors', 'gcf'), _i('factors', 'common')]),
      const SchoolLesson.explain('تحليل العدد إلى عوامله الأولية'),
      const SchoolLesson.explain('كتابة تعبيرات عددية باستخدام ع.م.أ'),
    ]),
    SchoolUnit('الأعداد النسبية', [
      SchoolLesson('خط الأعداد ومقارنة الأعداد', [_i('integers', 'numberLine')]),
      SchoolLesson('القيمة المطلقة', [_i('integers', 'abs')]),
      const SchoolLesson.explain('استخدام خط الأعداد لوصف البيانات'),
      const SchoolLesson.explain('تحليل الأعداد النسبية باستخدام النماذج'),
      const SchoolLesson.explain('مقارنة الأعداد النسبية وترتيبها'),
      const SchoolLesson.explain('مقارنة القيم المطلقة'),
    ]),
    SchoolUnit('المقادير الجبرية', [
      SchoolLesson('التعبيرات والمقادير الجبرية', [_i('algebra6', 'expression')]),
      SchoolLesson('ترتيب العمليات والأسس', [_i('algebra6', 'power'), _i('orderOps')]),
      const SchoolLesson.explain('تحليل التعبيرات الرياضية'),
      const SchoolLesson.explain('كتابة مقادير جبرية'),
      const SchoolLesson.explain('إيجاد قيمة المقدار الجبري'),
      const SchoolLesson.explain('تطبيقات على المقادير الجبرية'),
      const SchoolLesson.explain('تحديد المقادير الجبرية المتكافئة'),
    ]),
    SchoolUnit('المعادلات والمتباينات', [
      SchoolLesson('حل المعادلات والمتباينات', [_i('algebra6', 'solve'), _i('equations')]),
      const SchoolLesson.explain('استكشاف المتباينات'),
      const SchoolLesson.explain('حل المتباينات'),
    ]),
    SchoolUnit('المتغيرات التابعة والمستقلة', [
      SchoolLesson('العلاقة بين متغيرين', [_i('algebra6', 'variables')]),
      const SchoolLesson.explain('تطبيقات على المتغيرات التابعة والمستقلة'),
      const SchoolLesson.explain('تحليل العلاقة بين المتغير التابع والمستقل'),
      const SchoolLesson.explain('التمثيل البياني للمتغيرات التابعة والمستقلة'),
    ]),
    SchoolUnit('توزيع البيانات', [
      SchoolLesson('تمثيل البيانات', [_i('dotPlot'), _i('barGraph')]),
      const SchoolLesson.explain('البيانات والأسئلة الإحصائية'),
      const SchoolLesson.explain('استكشاف المدرج التكراري'),
      const SchoolLesson.explain('استكشاف المخطط الصندوقي'),
      const SchoolLesson.explain('تطبيقات على التمثيلات البيانية'),
    ]),
    SchoolUnit('مقاييس النزعة المركزية والانتشار', [
      SchoolLesson('الوسط الحسابي والوسيط والمنوال', [_i('statistics', 'center')]),
      SchoolLesson('المدى', [_i('statistics', 'spread')]),
      const SchoolLesson.explain('استكشاف توازن مجموعات البيانات'),
      const SchoolLesson.explain('الوسيط والمنوال والقيم المتطرفة'),
    ]),
  ]),
  SchoolBook('p6', 2, 'math', [
    SchoolUnit('عمليات على الكسور', [SchoolLesson('ضرب وقسمة الكسور', [_i('fractionDiv6'), _i('fractions5', 'mul')])]),
    SchoolUnit('النسبة وتطبيقاتها', [
      SchoolLesson('النسبة والنسب المتكافئة', [_i('ratios', 'ratio'), _i('ratios', 'equiv')]),
    ]),
    SchoolUnit('معدل الوحدة والنسبة المئوية', [
      SchoolLesson('معدل الوحدة', [_i('ratios', 'rate')]),
      SchoolLesson('تحويل وحدات القياس', [_i('unitConvert')]),
      SchoolLesson('النسبة المئوية', [_i('ratios', 'percent')]),
    ]),
    SchoolUnit('المستوى الإحداثي', [SchoolLesson('المستوى الإحداثي والمسافة', [_i('quadrants'), _i('coordinates')])]),
    SchoolUnit('مساحة بعض المضلعات', [SchoolLesson('متوازي الأضلاع والمثلث وشبه المنحرف', [_i('area6', 'area')])]),
    SchoolUnit('مساحة السطح والحجم', [
      SchoolLesson('مساحة السطح', [_i('area6', 'surface')]),
      SchoolLesson('الحجم', [_i('volume')]),
    ]),
  ]),
  SchoolBook('p6', 1, 'english', [
    SchoolUnit('Amazing Places in Egypt', [
      SchoolLesson('Present simple', [_i('en_present')]),
      const SchoolLesson.explain('Amazing places'),
      const SchoolLesson.explain('Sounds ir, er, ur'),
      const SchoolLesson.explain('Writing an informal email'),
    ]),
    SchoolUnit('Our Nature', [
      SchoolLesson('Present continuous', [_i('en_continuous', 'continuous')]),
      SchoolLesson('Nature', [_i('en_nature')]),
      const SchoolLesson.explain('Sounds e and i'),
      const SchoolLesson.explain('Writing a narrative story'),
    ]),
    SchoolUnit('Community Builders', [
      SchoolLesson('Jobs', [_i('en_jobs6')]),
      SchoolLesson("can, can't, able to", [_i('en_ableTo'), _i('en_could')]),
      const SchoolLesson.explain('Two- and three-syllable words'),
      const SchoolLesson.explain('A famous Egyptian: Ahmed Zewail'),
      const SchoolLesson.explain('Writing a biography'),
    ]),
    SchoolUnit('Resources Around Us', [
      SchoolLesson('Materials', [_i('en_heritage')]),
      SchoolLesson('should, must', [_i('en_should'), _i('en_safety')]),
      const SchoolLesson.explain('Short and long oo'),
      const SchoolLesson.explain('Writing a story about a visit'),
    ]),
    SchoolUnit('Made in Egypt', [
      SchoolLesson('Travel', [_i('en_travel')]),
      SchoolLesson('Past simple', [_i('en_past'), _i('en_did')]),
      const SchoolLesson.explain('Past endings: d, t, id'),
      const SchoolLesson.explain('Writing an opinion paragraph'),
    ]),
    const SchoolUnit('Water Savers', [
      SchoolLesson.explain('The Water Savers'),
      SchoolLesson.explain('Water words'),
      SchoolLesson.explain('Retell and make a poster'),
    ]),
  ]),
  SchoolBook('p6', 2, 'english', [
    SchoolUnit('Celebrating Creativity', [SchoolLesson('Art', [_i('en_art')]), SchoolLesson('both, either, neither', [_i('en_bothEither')])]),
    SchoolUnit('Wonderful Inventions', [SchoolLesson('who, which, whose', [_i('en_whoWhich')])]),
    SchoolUnit('Hidden Gems of Egypt', [SchoolLesson('Present perfect', [_i('en_presentPerfect')])]),
    SchoolUnit('Egypt on the Move', [SchoolLesson('used to', [_i('en_usedTo')])]),
    SchoolUnit('Safe and Smart Transportation', [SchoolLesson('If …, will …', [_i('en_conditional')]), SchoolLesson('Transport', [_i('en_travel')])]),
  ]),
];
