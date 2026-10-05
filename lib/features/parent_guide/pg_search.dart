/// البحث في دليل ولي الأمر — كلمات محلية (tags) بس، مفيش أي حاجة بتتبعت بره الجهاز.
/// منقول من search() في js/parentGuide.js.
library;

import '../../content/parent_guide.dart';

/// توحيد الكتابة: من غير تشكيل، والألف والياء والتاء المربوطة بشكل واحد.
String pgNorm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[ً-ٰٟـ]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll(RegExp(r'[^ء-يa-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const _stop = {
  'ابني', 'ابنتي', 'بنتي', 'طفلي', 'طفلتي', 'انا', 'هو', 'هي', 'ده', 'دي', 'دا', 'في', 'من', 'علي', 'عن', 'مع',
  'لما', 'لو', 'كل', 'بقي', 'عمال', 'قوي', 'جدا', 'اوي', 'كتير', 'حاجه', 'ايه', 'ليه', 'ازاي', 'مش', 'لا', 'ما',
  'بس', 'يا', 'بعد', 'قبل', 'عند', 'اللي', 'الي',
};

String _stripAl(String t) => t.startsWith('ال') ? t.substring(2) : t;

class _Indexed {
  _Indexed(this.b)
      : phrases = [for (final t in b.tags) if (pgNorm(t).contains(' ')) pgNorm(t)],
        singles = [
          for (final t in b.tags)
            if (pgNorm(t).isNotEmpty && !pgNorm(t).contains(' ')) _stripAl(pgNorm(t)),
        ];
  final PgBehavior b;
  final List<String> phrases;
  final List<String> singles;
}

final _index = [for (final b in pgBehaviors) _Indexed(b)];

/// السلوكيات الأقرب لكلام ولي الأمر، الأعلى نتيجة الأول.
List<PgBehavior> pgSearch(String q) {
  final nq = pgNorm(q);
  if (nq.isEmpty) return const [];
  final toks = nq.split(' ').map(_stripAl).where((t) => t.length >= 3 && !_stop.contains(t)).toList();
  final scored = <(int, int, PgBehavior)>[];
  for (final (i, x) in _index.indexed) {
    var s = 0;
    for (final p in x.phrases) {
      if (nq.contains(p)) s += 6;
    }
    for (final tag in x.singles) {
      for (final t in toks) {
        if (t == tag) {
          s += 3;
        } else if (tag.length >= 3 && t.contains(tag)) {
          s += 2;
        } else if (t.length >= 3 && tag.contains(t)) {
          s += 1;
        }
      }
    }
    if (s > 0) scored.add((s, i, x.b));
  }
  // ترتيب ثابت: النتيجة الأعلى، وبعدين ترتيب البيانات الأصلي (زي sort في الجافاسكريبت)
  scored.sort((a, b) => a.$1 != b.$1 ? b.$1 - a.$1 : a.$2 - b.$2);
  return [for (final x in scored) x.$3];
}
