/// شهادات الإنجاز اللي ولي الأمر يقدر يطبعها أو يشاركها: حفظ سورة، أو مسار تعلّم خلص.
/// محسوبة من التقدّم الموجود — مفيش بيانات جديدة بتتخزّن.
library;

import '../core/utils/arabic.dart';
import 'passport.dart';
import 'paths.dart';
import 'progress/progress_data.dart';

class Certificate {
  const Certificate(this.id, this.icon, this.title);

  /// `world:math` أو `path:reading` أو `surah:112`.
  final String id;
  final String icon;

  /// "حفظ سورة الإخلاص" — بيتكتب تحت اسم الطفل.
  final String title;
}

/// الشهادات المستحقة: العوالم اللي اتختم فيها ختم «أتقنتها» في جواز رحلتي، والمسارات اللي خلصت،
/// وبعدها السور المحفوظة بترتيب المصحف.
/// [surahNames] من قايمة السور المتخزّنة — لو مش موجودة بنكتب رقم السورة.
List<Certificate> certificates(ProgressData p, Map<int, String> surahNames) => [
      for (final page in passport(p))
        if (page.stamps == stampAt.length) Certificate('world:${page.world.id}', page.world.icon, 'إتقان عالم ${page.world.name}'),
      for (final path in learningPaths)
        if (path.started(p) && path.complete(p)) Certificate('path:${path.id}', path.icon, 'إتمام ${path.name}'),
      for (final s in memorizedSurahs(p))
        Certificate('surah:$s', '📖', 'حفظ ${surahTitle(s, surahNames[s])}'),
    ];

/// "سورة الإخلاص": المصدر الأساسي بيرجّع الاسم ومعاه "سُورَةُ"، والاحتياطي من غيرها.
String surahTitle(int number, String? name) {
  if (name == null) return 'السورة رقم ${ar(number)}';
  return name.replaceAll(RegExp('[\u064B-\u0652]'), '').startsWith('سورة') ? name : 'سورة $name';
}

/// السور اللي نشاط الحفظ فيها خلص.
List<int> memorizedSurahs(ProgressData p) => {
      for (final k in p.quran.keys) int.parse(k.split(':').first),
    }.where((s) => p.quranDone(s, 'memorize')).toList()
      ..sort();
