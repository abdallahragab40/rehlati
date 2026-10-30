/// اقرأ وافهم (رابعة لسادسة): قطعة قصيرة وسؤال عليها — بالعربي وبالإنجليزي.
///
/// القطع بالفصحى من غير تشكيل كامل زي كتب الصفوف دي (التنوين بس لما يفرق في القراية).
/// كل قطعة عليها تلات أسئلة: اتنين من النص مباشرة، وواحد "ليه/لماذا" محتاج فهم.
/// الاختيارات الغلط مش مذكورة في القطعة. محتاجة مراجعة مدرّس — tool/CONTENT_EXPANSION_REVIEW.md.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

class Passage {
  const Passage(this.title, this.text, this.questions);
  final String title;
  final String text;

  /// (السؤال، الإجابة، اختيارين غلط).
  final List<(String, String, List<String>)> questions;
}

const arPassages = [
  Passage('في السوق', 'ذهبت سلمى مع والدها إلى السوق يوم الجمعة. اشترت تفاحًا أحمر وبرتقالًا. '
      'وفي طريق العودة ساعدت جارتها العجوز في حمل أكياسها، فشكرتها الجارة ودعت لها.', [
    ('إلى أين ذهبت سلمى؟', 'إلى السوق', ['إلى المدرسة', 'إلى الحديقة']),
    ('متى ذهبت سلمى إلى السوق؟', 'يوم الجمعة', ['يوم السبت', 'يوم الاثنين']),
    ('ماذا فعلت سلمى في طريق العودة؟', 'ساعدت جارتها', ['لعبت بالكرة', 'نامت في السيارة']),
  ]),
  Passage('النحلة', 'النحلة حشرة صغيرة نافعة. تطير من زهرة إلى زهرة لتجمع الرحيق، '
      'ثم تعود إلى الخلية لتصنع العسل. والعسل غذاء مفيد للناس.', [
    ('ماذا تجمع النحلة من الأزهار؟', 'الرحيق', ['الماء', 'الأوراق']),
    ('أين تصنع النحلة العسل؟', 'في الخلية', ['في البحر', 'في البيت']),
    ('لماذا نقول إن النحلة نافعة؟', 'لأنها تصنع العسل', ['لأنها كبيرة', 'لأنها سريعة']),
  ]),
  Passage('صباح عمر', 'استيقظ عمر مبكرًا، فتوضأ وصلى الفجر. ثم تناول فطوره مع أسرته، '
      'وحمل حقيبته وذهب إلى المدرسة ماشيًا لأنها قريبة من بيته.', [
    ('ماذا فعل عمر بعد أن صلى الفجر؟', 'تناول فطوره', ['عاد إلى النوم', 'شاهد التلفاز']),
    ('كيف ذهب عمر إلى المدرسة؟', 'ماشيًا', ['بالسيارة', 'بالقطار']),
    ('لماذا ذهب عمر إلى المدرسة ماشيًا؟', 'لأن المدرسة قريبة من بيته', ['لأنه تأخر', 'لأن الجو حار']),
  ]),
  Passage('نهر النيل', 'النيل من أطول الأنهار في العالم. يجري في مصر من الجنوب إلى الشمال '
      'حتى يصب في البحر المتوسط. يشرب المصريون من مائه، ويزرعون على ضفتيه القمح والقطن.', [
    ('أين يصب نهر النيل؟', 'في البحر المتوسط', ['في البحر الأحمر', 'في بحيرة صغيرة']),
    ('في أي اتجاه يجري النيل في مصر؟', 'من الجنوب إلى الشمال', ['من الشمال إلى الجنوب', 'من الشرق إلى الغرب']),
    ('ماذا يزرع المصريون على ضفتي النيل؟', 'القمح والقطن', ['التفاح والعنب', 'الأشجار فقط']),
  ]),
  Passage('مشمشة', 'كان عند كريم قطة صغيرة اسمها مشمشة. وفي يوم من الأيام اختفت مشمشة، '
      'فبحث عنها كريم في كل مكان. وأخيرًا وجدها نائمة تحت السرير، ففرح كثيرًا.', [
    ('ما اسم قطة كريم؟', 'مشمشة', ['لولو', 'بسبوسة']),
    ('أين وجد كريم القطة؟', 'تحت السرير', ['فوق الشجرة', 'في المطبخ']),
    ('بماذا شعر كريم عندما وجد القطة؟', 'فرح كثيرًا', ['حزن', 'غضب']),
  ]),
  Passage('فصل الشتاء', 'في فصل الشتاء يكون الجو باردًا، وتسقط الأمطار، ويقصر النهار ويطول الليل. '
      'لذلك نلبس الملابس الثقيلة ونشرب المشروبات الدافئة.', [
    ('كيف يكون الجو في فصل الشتاء؟', 'باردًا', ['حارًا', 'جافًا دائمًا']),
    ('ماذا يحدث للنهار في الشتاء؟', 'يقصر', ['يطول', 'لا يتغير']),
    ('لماذا نلبس الملابس الثقيلة في الشتاء؟', 'لأن الجو بارد', ['لأنها جميلة', 'لأن النهار طويل']),
  ]),
];

const enPassages = [
  Passage('My Family', 'My name is Sara. I live in Cairo with my mother, my father and my little brother, Adam. '
      'Adam is five years old. He likes playing football in the garden.', [
    ('Where does Sara live?', 'In Cairo', ['In London', 'In a village']),
    ('How old is Adam?', 'Five', ['Seven', 'Ten']),
    ('What does Adam like?', 'Playing football', ['Reading books', 'Swimming']),
  ]),
  Passage('At the Zoo', 'On Friday, Omar went to the zoo with his class. He saw a tall giraffe and two big elephants. '
      'The monkeys were funny, and they made everyone laugh.', [
    ('When did Omar go to the zoo?', 'On Friday', ['On Monday', 'On Sunday']),
    ('How many elephants did he see?', 'Two', ['One', 'Five']),
    ('Why did everyone laugh?', 'The monkeys were funny', ['The giraffe was tall', 'It was raining']),
  ]),
  Passage('A Rainy Day', 'It was raining, so Mona could not go to the park. She stayed at home and drew a picture of a rainbow. '
      'When the rain stopped, she showed the picture to her grandmother.', [
    ('Why did Mona stay at home?', 'It was raining', ['She was ill', 'The park was closed']),
    ('What did Mona draw?', 'A rainbow', ['A cat', 'A house']),
    ('Who saw the picture?', 'Her grandmother', ['Her teacher', 'Her friend']),
  ]),
  // وحدة The Pyramids في كتاب تانية (الترم التاني) — النص من عندنا
  Passage('The Pyramids', 'Hana and her family took a trip to the Pyramids. They saw the Sphinx with its big lion body. '
      'Hana rode a camel, and her dad took pictures. The Pyramids are very old and very big!', [
    ('Where did Hana go?', 'To the Pyramids', ['To the beach', 'To the zoo']),
    ('What did Hana ride?', 'A camel', ['A horse', 'A bus']),
    ('Who took pictures?', 'Her dad', ['Her mom', 'Her teacher']),
  ]),
  Passage('Healthy Food', 'Ali eats fruit and vegetables every day. He drinks milk in the morning and water when he is thirsty. '
      'He does not eat many sweets because they are bad for his teeth.', [
    ('What does Ali drink in the morning?', 'Milk', ['Juice', 'Tea']),
    ('What does Ali drink when he is thirsty?', 'Water', ['Milk', 'Soda']),
    ('Why does Ali not eat many sweets?', 'They are bad for his teeth', ['They are expensive', 'He does not like them']),
  ]),
];

/// سؤال من قطعة: القطعة كلها ظاهرة والسؤال فوقها.
Question _reading(String type, List<Passage> pool, int lv, Rng r, String? focus, {required bool en}) {
  final p = pool.where((x) => x.title == focus).firstOrNull ?? r.sample<Passage>(pool);
  // المستوى الأول والتاني: أسئلة من النص مباشرة؛ "ليه" من التالت
  final qs = lv <= 2 ? p.questions.take(2).toList() : p.questions;
  final (q, answer, wrong) = r.sample(qs);
  return Question(
    type: type, mode: QMode.choice, skill: '$type:${p.title}', numeric: false, wide: true,
    lang: en ? 'en' : 'ar', ltr: en,
    ask: q,
    speak: q,
    clips: en ? null : [say(q)],
    visuals: [PassageVisual(p.title, p.text, ltr: en)],
    choices: r.shuffle([answer, ...wrong]),
    answer: answer,
    hint: en ? 'Read the story again and look for the answer.' : 'ارجع للقطعة ودوّر على الإجابة 🔍',
    speakHint: en ? 'Read the story again' : 'ارجع للقطعة ودوّر على الإجابة',
    sayRight: answer,
  );
}

Question arReading(int lv, Rng r, {String? focus}) => _reading('ar_reading', arPassages, lv, r, focus, en: false);
Question enReading(int lv, Rng r, {String? focus}) => _reading('en_reading', enPassages, lv, r, focus, en: true);
