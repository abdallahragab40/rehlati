/// كل الجمل العربية اللي الشاشات بتنطقها برّه مولّدات الأسئلة — في مكان واحد عشان
/// tool/voice_phrases_test.dart يلاقيها ويسجّلها مسبقًا بالصوت البشري/العصبي.
library;

import '../../content/language_data.dart';

/// جزء جملة طبيعي جوه قائمة مقاطع (`clips`) — بيتسجّل كجملة كاملة بدل ما يتركّب
/// من كلمات، زي "تلاتة ... و ... خمسة". الباقي مفاتيح ثابتة من tool/clips.tsv.
String say(String text) => '$sayPrefix$text';
const sayPrefix = 'say:';

const sayRetry = 'حاول مرة تانية';
const sayNotThis = 'مش ده';
const sayWelcome = 'أهلاً يا بطل! اختار عالم وابدأ المغامرة';
const sayLocked = 'المرحلة دي مقفولة، خلص اللي قبلها الأول';
const sayGoalDone = 'برافو! خلصت هدف النهاردة';
const sayTimeUp = 'خلاص يا بطل، بكرة نكمل';
const sayVoiceTest = ['أهلاً يا بطل، أنا الأسد صاحبك', 'واحد، اتنين، تلاتة'];

String sayStageIntro(String stageName) => '$stageName. يلا بينا!';
String sayUnlocked(String stageName) => 'وفتحت مرحلة جديدة: $stageName';
String sayToast(String name, {required bool rank}) => rank ? 'مبروك! وصلت $name' : 'إنجاز جديد! $name';

/// لوحة الحروف: "ب . ب مثل بطة" — النص للعرض ولو المقاطع ناقصة؛ الصوت من letterLesson (teaching.dart).
String sayLetter(Letter it) => '${it.letter} . ${it.letter} مثل ${it.word}';

/// درس المد والممدود.
String sayMamdoud(String mam) => '$mam الممدود';
String sayMaddChar(String mad) => '${mad == 'ا' ? 'ألف' : mad} حرف المد';
String sayRemedial(String typeName) => 'تحتاج إلى تدريب صغير على $typeName';

/// لعبة دليل الأهل: {name} بتتبدّل باسم الطفل. "الطفل" هو اللي بيتسجّل مسبقًا.
String fillChildName(String s, String name) => s.replaceAll('{name}', name.isEmpty ? 'الطفل' : name);
