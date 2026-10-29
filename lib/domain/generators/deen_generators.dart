/// عالم «الدين والأخلاق» (الأذكار، الوضوء والصلاة، الأركان، القصص، الأخلاق، الشهور) وعالم «اكتشف»
/// (البيئات، الفصول، أجزاء النبات، الحواس، الأكل الصحي).
library;

import '../../content/basics_data.dart';
import '../../content/deen_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

List<Object> _with(Rng r, Object answer, Iterable<Object> wrong, int n) =>
    r.shuffle([answer, ...r.shuffle({...wrong}.where((w) => w != answer).toList()).take(n - 1)]);

/// ﷺ بتتكتب في النص وبتتقال كاملة.
String _spoken(String t) => t.replaceAll('ﷺ', 'صلى الله عليه وسلم');

Map<Object, String> _names(Iterable<(String, String)> pics) => {for (final (e, n) in pics) e: n};

/// حتة متتالية من خطوات بترتيبها — بتطول مع المستوى.
List<(String, String)> _window(Rng r, List<(String, String)> steps, int lv, {int min = 3}) {
  final n = (min + lv - 1).clamp(min, steps.length);
  final from = r.rnd(0, steps.length - n);
  return steps.sublist(from, from + n);
}

Question _order(Rng r, String type, String skill, String ask, String speak, List<(String, String)> steps, String ok) {
  final seq = [for (final (e, _) in steps) e];
  return Question(
    type: type, mode: QMode.order, numeric: false, skill: skill, bigChoices: true, rtlSlots: true,
    look: ChoiceLook.picName,
    ask: ask, speak: speak, orderHint: 'اضغط الخطوات بالترتيب: الأولى ← الأخيرة',
    items: r.shuffle([...seq]), answer: seq, choiceSay: _names(steps),
    hint: 'إيه أول حاجة بنعملها؟ 🤔', speakHint: 'فكر، إيه أول حاجة بنعملها؟', okMsg: ok,
  );
}

// ================================================================ 🕌 الدين والأخلاق

/// الموقف والطفل يختار الذكر المناسب.
Question deenDua(int lv, Rng r, {String? focus}) {
  final (moment, pic, dua) = r.sample(adhkar);
  final wrong = [for (final a in adhkar) if (a.$3 != dua) a.$3];
  return Question(
    type: 'deen_dua', mode: QMode.choice, skill: 'dua:$moment', numeric: false, wide: true,
    ask: 'نقول إيه $moment؟', speak: 'نقول إيه $moment؟',
    visuals: [EmojiVisual(pic, caption: moment)],
    choices: _with(r, dua, wrong, lv <= 1 ? 2 : 3), answer: dua,
    hint: 'افتكر الدعاء اللي بنقوله $moment 🤲', speakHint: 'افتكر الدعاء اللي بنقوله',
  );
}

/// ردّد الذكر: يسمعه ويقوله ويدوس «قلتها» — مفيش غلط، زي الترديد في القرآن.
Question deenRepeat(int lv, Rng r, {String? focus}) {
  final (moment, pic, dua) = r.sample(adhkar);
  return Question(
    type: 'deen_repeat', mode: QMode.read, skill: 'repeat:$moment', numeric: false,
    ask: 'اسمع وردّد: ذكر $moment', speak: dua, clips: [say(dua)],
    visuals: [EmojiVisual(pic, caption: moment), WordLineVisual.text(dua, big: true), ListenVisual(dua)],
    yes: 'قلتها ⭐',
    hint: 'اضغط 🔊 واسمع، وبعدين قول الذكر بصوتك', speakHint: 'اسمع وبعدين قول بصوتك',
  );
}

Question deenWudu(int lv, Rng r, {String? focus}) => _order(r, 'deen_wudu', 'wudu', 'رتّب خطوات الوضوء',
    'رتب خطوات الوضوء بالترتيب', _window(r, wuduFull, lv, min: 4), '💧 وضوء مظبوط!');

Question deenSalah(int lv, Rng r, {String? focus}) => _order(r, 'deen_salah', 'salah', 'رتّب خطوات الصلاة',
    'رتب خطوات الصلاة بالترتيب', _window(r, salahSteps, lv, min: 3), '🕌 صلاة مظبوطة!');

/// أركان الإسلام والإيمان: عددهم، ترتيبهم، وده من أنهي واحدة.
Question deenPillars(int lv, Rng r, {String? focus}) {
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 3);
  switch (kind) {
    case 0:
      final islam = r.chance(.5);
      return Question(
        type: 'deen_pillars', mode: QMode.choice, skill: 'pillars:count', bigChoices: true,
        ask: islam ? 'أركان الإسلام كام؟' : 'أركان الإيمان كام؟', speak: islam ? 'أركان الإسلام كام؟' : 'أركان الإيمان كام؟',
        visuals: [EmojiVisual(islam ? '🕌' : '💛')],
        choices: r.shuffle([4, 5, 6]), answer: islam ? 5 : 6,
        hint: 'الإسلام ٥ أركان، والإيمان ٦ ☝️', speakHint: 'الإسلام خمسة أركان، والإيمان ستة',
      );
    case 1:
      final (pic, name) = r.sample(islamPillars);
      final wrong = ['الاعتكاف', 'العمرة', 'صلاة العيد', 'الصدقة'];
      return Question(
        type: 'deen_pillars', mode: QMode.choice, skill: 'pillars:islam', numeric: false, wide: true,
        ask: 'أنهي واحد من أركان الإسلام؟', speak: 'أنهي واحد من أركان الإسلام؟',
        choices: _with(r, name, wrong, lv <= 1 ? 2 : 3), answer: name,
        hint: 'الشهادتين، الصلاة، الزكاة، الصوم، الحج 🕋', speakHint: 'الشهادتين، الصلاة، الزكاة، الصوم، الحج',
        sayRight: name, okMsg: '$pic $name ركن من أركان الإسلام',
      );
    case 2:
      return _order(r, 'deen_pillars', 'pillars:order', 'رتّب أركان الإسلام', 'رتب أركان الإسلام بالترتيب',
          lv >= 4 ? islamPillars : islamPillars.take(4).toList(), '☪️ مظبوط!');
    default:
      final iman = r.chance(.5);
      final item = iman ? r.sample(imanPillars) : r.sample(islamPillars).$2;
      return Question(
        type: 'deen_pillars', mode: QMode.choice, skill: 'pillars:which', numeric: false, wide: true,
        ask: '«$item» من أركان الإسلام ولا الإيمان؟', speak: '$item، من أركان الإسلام ولا الإيمان؟',
        choices: const ['أركان الإسلام', 'أركان الإيمان'], answer: iman ? 'أركان الإيمان' : 'أركان الإسلام',
        hint: 'أركان الإسلام حاجات بنعملها، وأركان الإيمان حاجات بنصدّقها في قلبنا 💛',
        speakHint: 'أركان الإسلام حاجات بنعملها، وأركان الإيمان حاجات بنصدقها في قلبنا',
      );
  }
}

/// قصة نبي قصيرة وسؤال عنها.
Question deenProphets(int lv, Rng r, {String? focus}) {
  final (who, pic, story, q, a, wrong) = r.sample(prophetStories);
  return Question(
    type: 'deen_prophets', mode: QMode.choice, skill: 'prophet:$who', numeric: false, wide: true,
    ask: q, speak: _spoken('$story $q'), clips: [say(_spoken(story)), say(_spoken(q))],
    visuals: [EmojiVisual(pic), PassageVisual('📜 القصة', story)],
    choices: r.shuffle([a, ...wrong]), answer: a,
    hint: 'اقرا القصة تاني بالراحة 📜', speakHint: 'اسمع القصة تاني بالراحة',
  );
}

/// الصدق والأمانة وبر الوالدين: ✅ ولا ❌.
Question deenMorals(int lv, Rng r, {String? focus}) {
  final (emoji, text, ok, why) = r.sample(morals);
  return Question(
    type: 'deen_morals', mode: QMode.choice, skill: 'moral:$text', numeric: false, bigChoices: true, gentle: true,
    ask: 'ده يصح ولا لأ؟', speak: '$text. ده يصح ولا لأ؟', clips: [say(text), say('ده يصح ولا لأ؟')],
    visuals: [EmojiVisual(emoji, caption: text)],
    choices: const ['✅', '❌'], answer: ok ? '✅' : '❌',
    choiceSay: const {'✅': 'يصح', '❌': 'ما يصحش'},
    sayRight: why, okMsg: '${ok ? '👏' : '🙅'} $why',
    hint: 'فكّر: ربنا يحب كده؟ وماما وبابا يفرحوا؟ 💭', speakHint: 'فكر، ربنا يحب كده؟',
  );
}

/// الشهور الهجرية والأعياد ورمضان.
Question deenCalendar(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.4)) {
    final i = r.rnd(0, hijriMonths.length - 2);
    return Question(
      type: 'deen_calendar', mode: QMode.choice, skill: 'hijri', numeric: false, wide: true,
      ask: 'إيه الشهر اللي بعد ${hijriMonths[i]}؟', speak: 'إيه الشهر الهجري اللي بعد ${hijriMonths[i]}؟',
      choices: _with(r, hijriMonths[i + 1], hijriMonths, 3), answer: hijriMonths[i + 1],
      hint: '… رجب، شعبان، رمضان، شوّال … 📅', speakHint: 'رجب، شعبان، رمضان، شوال',
    );
  }
  final (q, pic, a, wrong) = r.sample(islamicDays);
  final digits = RegExp(r'^[٠-٩]+$');
  int num(String d) => int.parse([for (final c in d.split('')) '٠١٢٣٤٥٦٧٨٩'.indexOf(c)].join());
  return Question(
    type: 'deen_calendar', mode: QMode.choice, skill: 'days:$q', numeric: false, wide: true,
    ask: q, speak: q,
    visuals: [EmojiVisual(pic)],
    choices: r.shuffle([a, ...wrong]), answer: a,
    choiceSay: {for (final c in [a, ...wrong]) if (digits.hasMatch(c)) c: arNum(num(c))},
    hint: 'رمضان شهر الصيام، وبعده عيد الفطر في شوّال 🌙', speakHint: 'رمضان شهر الصيام، وبعده عيد الفطر',
  );
}

// ================================================================ 🌍 اكتشف

/// الحيوان بيعيش فين؟ اختيار، ومن المستوى التالت اسحب للبيئة.
Question discHabitat(int lv, Rng r, {String? focus}) {
  final keys = habitats.keys.toList();
  if (lv >= 3 && r.chance(.5)) {
    final two = r.shuffle([...keys]).take(2).toList();
    final cards = [
      for (final k in two) ...r.shuffle(habitatAnimals.where((a) => a.$3 == k).toList()).take(2),
    ];
    return Question(
      type: 'disc_habitat', mode: QMode.sort, skill: 'habitat:sort', skillOf: (k) => 'habitat:$k',
      ask: 'كل حيوان يروح بيته', speak: 'اسحب كل حيوان للمكان اللي بيعيش فيه',
      orderHint: 'اسحب الحيوان لبيته، أو اضغطه وبعدين اضغط المكان',
      boxes: [for (final (i, k) in two.indexed) SortBox(k, '${habitats[k]!.$2} ${habitats[k]!.$1}', color: [0xFF2B8A9E, 0xFFC0782B][i])],
      sortCards: [for (final a in r.shuffle(cards)) SortCard(a.$1, a.$2, a.$3)],
      hint: 'فكّر: الحيوان ده بيعيش فين؟ 🏡', speakHint: 'فكر، الحيوان ده بيعيش فين؟',
    );
  }
  final (pic, name, home) = r.sample(habitatAnimals);
  final shown = _with(r, home, keys, lv <= 1 ? 2 : 3).cast<String>();
  return Question(
    type: 'disc_habitat', mode: QMode.choice, skill: 'habitat:$home', numeric: false, wide: true,
    ask: 'فين بيت ال$name؟', speak: 'فين بيت ال$name؟',
    visuals: [EmojiVisual(pic)],
    choices: [for (final k in shown) '${habitats[k]!.$2} ${habitats[k]!.$1}'],
    answer: '${habitats[home]!.$2} ${habitats[home]!.$1}',
    choiceSay: {for (final k in keys) '${habitats[k]!.$2} ${habitats[k]!.$1}': habitats[k]!.$1},
    hint: 'فكّر في الجو اللي بيحبه 🌍', speakHint: 'فكر في الجو اللي بيحبه',
  );
}

/// الفصول الأربعة: الحاجة دي في أنهي فصل؟ وترتيب الفصول.
Question discSeasons(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.35)) {
    final start = r.rnd(0, 3);
    final steps = [for (var k = 0; k < 4; k++) seasons[(start + k) % 4]];
    return _order(r, 'disc_seasons', 'seasons:order', 'رتّب الفصول', 'رتب الفصول بالترتيب',
        [for (final s in steps) (s.$2, s.$1)], '🌍 الفصول مترتّبة!');
  }
  final (name, pic, things) = r.sample(seasons);
  final it = r.sample(things);
  return Question(
    type: 'disc_seasons', mode: QMode.choice, skill: 'season:$name', numeric: false, wide: true,
    ask: 'ده بيبقى في أنهي فصل؟', speak: 'ده بيبقى في أنهي فصل؟',
    visuals: [EmojiVisual(it)],
    choices: r.shuffle([for (final s in seasons) '${s.$2} ${s.$1}']), answer: '$pic $name',
    choiceSay: {for (final s in seasons) '${s.$2} ${s.$1}': s.$1},
    hint: 'الشتا برد ⛄، والصيف حر ☀️، والربيع ورد 🌸، والخريف ورق شجر واقع 🍂', speakHint: 'فكر، الجو بيبقى عامل إزاي؟',
  );
}

/// أجزاء النبات: الجزء اللي عليه السهم اسمه إيه؟ أو أنهي جزء بيعمل كذا؟
Question discPlant(int lv, Rng r, {String? focus}) {
  final parts = lv <= 1 ? plantParts.take(3).toList() : plantParts;
  final (key, name, job) = r.sample(parts);
  final byJob = lv >= 2 && r.chance(.5);
  return Question(
    type: 'disc_plant', mode: QMode.choice, skill: 'plant:$key', numeric: false, wide: true,
    ask: byJob ? 'أنهي جزء $job؟' : 'الجزء اللي عليه السهم اسمه إيه؟',
    speak: byJob ? 'أنهي جزء $job؟' : 'الجزء اللي عليه السهم اسمه إيه؟',
    visuals: [PlantVisual(byJob ? null : key)],
    choices: _with(r, name, [for (final p in parts) p.$2], lv <= 1 ? 3 : 4), answer: name,
    hint: 'الجذر تحت الأرض، والساق شايلة الورق، والزهرة فوق 🌱', speakHint: 'الجذر تحت الأرض، والساق شايلة الورق، والزهرة فوق',
    okMsg: '🌱 $name: $job',
  );
}

/// الحواس الخمس: بنحس بده بأنهي حاسة؟
Question discSenses(int lv, Rng r, {String? focus}) {
  final (organ, sense, things) = r.sample(senses);
  final it = r.sample(things);
  final shown = _with(r, organ, [for (final s in senses) s.$1], lv <= 1 ? 3 : 5).cast<String>();
  return Question(
    type: 'disc_senses', mode: QMode.choice, skill: 'sense:$sense', numeric: false, bigChoices: true,
    ask: 'بنعرف ده بأنهي حاسة؟', speak: 'بنعرف ده بأنهي حاسة؟',
    visuals: [EmojiVisual(it)],
    choices: shown, answer: organ,
    choiceSay: {for (final s in senses) s.$1: s.$2},
    hint: 'عينينا بتشوف، وودانا بتسمع، ومناخيرنا بتشم، ولساننا بيدوق، وإيدنا بتلمس ✋',
    speakHint: 'عينينا بتشوف، وودانا بتسمع، ومناخيرنا بتشم، ولساننا بيدوق، وإيدنا بتلمس',
  );
}

/// أكل بيقوّينا كل يوم، وأكل بناكل منه شوية بس — اختيار أو سلّتين.
Question discHealth(int lv, Rng r, {String? focus}) {
  if (lv >= 2) {
    final good = r.shuffle([...healthyFood]).take(lv >= 3 ? 3 : 2), sweet = r.shuffle([...treatFood]).take(lv >= 3 ? 3 : 2);
    return Question(
      type: 'disc_health', mode: QMode.sort, skill: 'health:sort', skillOf: (k) => 'health:$k',
      ask: 'كل أكلة في سلتها', speak: 'حط الأكل اللي بيقوينا في سلة، والأكل اللي بناكل منه شوية في سلة',
      orderHint: 'اسحب الأكلة للسلة، أو اضغطها وبعدين اضغط السلة',
      boxes: const [SortBox('good', '💪 بيقوّينا كل يوم', color: 0xFF2FA36B), SortBox('treat', '🍬 شوية بس', color: 0xFFE0662E)],
      sortCards: [
        for (final f in r.shuffle([...good.map((e) => (e, 'good')), ...sweet.map((e) => (e, 'treat'))]))
          SortCard(f.$1, foodNames[f.$1]!, f.$2),
      ],
      hint: 'الفاكهة والخضار واللبن بيقوّوا جسمنا 💪', speakHint: 'الفاكهة والخضار واللبن بيقووا جسمنا',
    );
  }
  final g = r.sample(healthyFood), t = r.sample(treatFood);
  return Question(
    type: 'disc_health', mode: QMode.choice, skill: 'health:pick', numeric: false, bigChoices: true,
    ask: 'أنهي أكلة بتقوّي جسمك أكتر؟', speak: 'أنهي أكلة بتقوي جسمك أكتر؟',
    choices: r.shuffle([g, t]), answer: g,
    choiceSay: {g: foodNames[g]!, t: foodNames[t]!},
    hint: 'الحلويات حلوة بس شوية بس 🍬', speakHint: 'الحلويات حلوة بس شوية بس',
  );
}
