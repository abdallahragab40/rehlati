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

// درس لسه مالوش مراحل («قريبًا») — كل دروس أولى لتالتة جاهزة دلوقتي، وده للكتب الجاية.
// ignore: unused_element
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
    SchoolUnit('تكوين أشكال', [SchoolLesson('تكوين أشكال', [_i('composeShapes')])]),
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
    SchoolUnit('Seasons', [SchoolLesson('Months, seasons and weather', [_i('en_months'), _i('en_seasons'), _i('en_weather')]), SchoolLesson('Short vowels a, e', [_i('en_cvc')])]),
    SchoolUnit('My House', [SchoolLesson('Rooms at home', [_i('en_rooms')]), SchoolLesson('Short vowels i, o', [_i('en_cvc')])]),
    SchoolUnit('Neighborhood', [
      SchoolLesson('Places and transport', [_i('en_places'), _i('en_transport')]),
      SchoolLesson('Short vowel u', [_i('en_cvc')]),
      SchoolLesson('Blends cl, bl, fl, sl', [_i('en_sounds', 'blendL')]),
    ]),
  ]),
  SchoolBook('p2', 1, 'english', [
    SchoolUnit("Let's Get Started!", [
      SchoolLesson('Classroom things', [_i('en_daily')]),
      SchoolLesson('Short vowels a, e, i', [_i('en_cvc')]),
    ]),
    SchoolUnit('Colors, Shapes, and Numbers', [
      SchoolLesson('Colors, shapes and numbers', [_i('en_colors'), _i('en_shapes'), _i('en_numbers')]),
      SchoolLesson('Numbers 11–20', [_i('en_count100', 'to20')]),
    ]),
    SchoolUnit('Classroom Actions & Routines', [
      SchoolLesson('Classroom actions', [_i('en_actions')]),
      SchoolLesson('First sounds', [_i('en_firstsound')]),
    ]),
    SchoolUnit('Everyday Life', [
      SchoolLesson('My family', [_i('en_family')]),
      SchoolLesson('Long vowels o, u and th', [_i('en_sounds', 'long'), _i('en_sounds', 'digraph')]),
    ]),
    SchoolUnit('My Home', [SchoolLesson('My home', [_i('en_rooms'), _i('en_prep')]), SchoolLesson('sh and th', [_i('en_sounds', 'digraph')])]),
    SchoolUnit('Rooms at Home', [SchoolLesson('Rooms at home', [_i('en_rooms')]), SchoolLesson('ch', [_i('en_sounds', 'digraph')])]),
  ]),
  SchoolBook('p2', 2, 'english', [
    SchoolUnit('Our Environment', [SchoolLesson('There is / There are', [_i('en_isare')]), SchoolLesson('Long vowels a, i', [_i('en_sounds', 'long')])]),
    SchoolUnit('At the Store', [SchoolLesson('Clothes', [_i('en_clothes')]), SchoolLesson('Long vowels u, o', [_i('en_sounds', 'long')])]),
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
    ]),
    SchoolUnit('صفاتي الجميلة', [
      SchoolLesson('المفرد والمثنى والجمع', [_i('ar_number')]),
      SchoolLesson('التنوين', [_i('ar_tanween'), _i('ar_marks')]),
      SchoolLesson('أسلوب النفي (لم – لن)', [_i('ar_negation')]),
    ]),
    SchoolUnit('أحب بلدي', [
      SchoolLesson('حروف الجر (عن – على)', [_i('ar_particles', 'jarr2')]),
      SchoolLesson('التاء المفتوحة والمربوطة', [_i('ar_taa')]),
      SchoolLesson('حروف العطف (ثم – ف)', [_i('ar_particles', 'atf2')]),
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
    ]),
    SchoolUnit('الآلاف والضرب', [
      SchoolLesson('الآلاف', [_i('thousands')]),
      SchoolLesson('المصفوفات ومفهوم الضرب', [_i('mulGroups')]),
      SchoolLesson('خاصية الإبدال في الضرب', [_i('times2510')]),
    ]),
    SchoolUnit('الضرب والقسمة والوقت', [
      SchoolLesson('مضاعفات ٢ و٣ و٤', [_i('times2510'), _i('times34')]),
      SchoolLesson('مضاعفات ٥ و١٠', [_i('times2510')]),
      SchoolLesson('الوقت', [_i('clockQuarter')]),
      SchoolLesson('مفهوم القسمة', [_i('divisionExact')]),
      SchoolLesson('العلاقة بين الضرب والقسمة', [_i('divisionMissing')]),
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
      SchoolLesson('الوقت المنقضي', [_i('clockQuarter')]),
      SchoolLesson('التمثيلات البيانية', [_i('barGraph')]),
    ]),
  ]),
  SchoolBook('p3', 1, 'english', [
    SchoolUnit("Let's Learn Together!", [
      SchoolLesson('Greetings', [_i('en_phrases')]),
      SchoolLesson('I am, you are, he is', [_i('en_isare')]),
    ]),
    SchoolUnit('My Family and I', [SchoolLesson('Family', [_i('en_family')]), SchoolLesson('my, his, her', [_i('en_possessive')])]),
    SchoolUnit('New Adventures', [
      SchoolLesson('Places', [_i('en_places')]),
      SchoolLesson('in, on, under', [_i('en_prep')]),
      SchoolLesson('Past tense: walked, played', [_i('en_past', 'regular')]),
    ]),
    SchoolUnit("Let's Tell Stories!", [SchoolLesson('Feelings', [_i('en_feelings')]), SchoolLesson('Past simple stories', [_i('en_past', 'irregular')])]),
    SchoolUnit('Together Is Better', [SchoolLesson('Actions', [_i('en_actions')])]),
  ]),
  SchoolBook('p3', 2, 'english', [
    SchoolUnit('Safety', [SchoolLesson("Stop! Don't touch!", [_i('en_safety')]), SchoolLesson('Blends sl, st, gr, tr', [_i('en_sounds', 'blendS')])]),
    SchoolUnit('Food and Health', [SchoolLesson('a, an', [_i('en_a_an')]), SchoolLesson('Food words', [_i('en_food')])]),
    SchoolUnit('Heroes Around Us', [SchoolLesson('Magic e', [_i('en_sounds', 'long')])]),
    SchoolUnit('Living with Technology', [SchoolLesson('and, or, but', [_i('en_conj')])]),
    SchoolUnit('Animals & Habitats', [SchoolLesson('Animals', [_i('en_animals')]), SchoolLesson("can, can't", [_i('en_can')])]),
  ]),
];
