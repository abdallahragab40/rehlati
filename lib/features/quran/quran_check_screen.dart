/// التحقق من النص — نسخة من quran-check.html داخل التطبيق.
///
/// بيجيب السورة من المصدرين ويقارن آية بآية:
///   ✅ مطابق حرف بحرف
///   🟡 نفس الحروف والكلمات، والاختلاف في طريقة كتابة العلامات بس (متوقع بين المصادر)
///   ❌ اختلاف في الحروف أو عدد الكلمات — محتاج مراجعة
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/quran_config.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import 'quran_repository.dart';
import 'quran_widgets.dart';

enum AyahMatch { exact, marksOnly, different }

AyahMatch compareAyah(String a, String b) {
  if (a == b) return AyahMatch.exact;
  List<String> sk(String t) => t.split(RegExp(r'\s+')).map(skeleton).where((w) => w.isNotEmpty).toList();
  // الهمزة على الألف بتتكتب بطريقتين بين المصادر (ءا / آ) — نوحّدها قبل المقارنة
  String norm(String w) => w.replaceAll('ءا', 'ا').replaceAll('ء', '');
  final x = sk(a).map(norm).toList(), y = sk(b).map(norm).toList();
  if (x.length != y.length) return AyahMatch.different;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return AyahMatch.different;
  }
  return AyahMatch.marksOnly;
}

class QuranCheckScreen extends ConsumerStatefulWidget {
  const QuranCheckScreen({super.key});

  @override
  ConsumerState<QuranCheckScreen> createState() => _QuranCheckScreenState();
}

class _QuranCheckScreenState extends ConsumerState<QuranCheckScreen> {
  int surah = QuranConfig.to;
  Future<Map<String, List<Ayah>>>? _future;

  void _run() => setState(() => _future = ref.read(quranRepositoryProvider).fetchAll(surah));

  @override
  Widget build(BuildContext context) {
    final chapters = ref.watch(quranChaptersProvider).value ?? const <QuranChapter>[];
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🔍 التحقق من النص',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🔍 التحقق من النص القرآني', style: kidText(22), textAlign: TextAlign.center),
          const NoteBox(Text(
            'الصفحة دي بتجيب السورة من المصدرين وتقارنهم آية بآية. '
            'الأصفر معناه نفس الحروف والكلمات بس طريقة كتابة العلامات مختلفة (ده طبيعي بين المصادر). '
            'الأحمر معناه اختلاف حقيقي — بلّغ المطوّر قبل ما تدّي القسم ده للطفل.',
          )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButton<int>(
                value: surah,
                isExpanded: true,
                style: kidText(16, weight: FontWeight.w700),
                items: [
                  for (final c in chapters) DropdownMenuItem(value: c.number, child: Text('${ar(c.number)} — ${c.name}')),
                  if (chapters.isEmpty) DropdownMenuItem(value: surah, child: Text(ar(surah))),
                ],
                onChanged: (v) => setState(() => surah = v ?? surah),
              ),
            ),
            const SizedBox(width: 10),
            KidButton('قارن', onTap: _run),
          ]),
          if (_future != null)
            FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return NoteBox(Text('خطأ: ${snap.error}'));
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: quranMint)),
                  );
                }
                return _Report(snap.data!);
              },
            ),
        ]),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report(this.bySource);
  final Map<String, List<Ayah>> bySource;

  @override
  Widget build(BuildContext context) {
    final labels = bySource.keys.toList();
    final a = bySource[labels[0]]!, b = bySource[labels[1]]!;
    if (a.length != b.length) {
      return NoteBox(Text('❌ عدد الآيات مختلف: ${ar(a.length)} / ${ar(b.length)}'));
    }
    final results = [for (var i = 0; i < a.length; i++) compareAyah(a[i].text, b[i].text)];
    final bad = results.where((r) => r == AyahMatch.different).length;
    final marks = results.where((r) => r == AyahMatch.marksOnly).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 12),
      SpeechBubble(
        bad == 0
            ? '✅ مفيش اختلاف في الحروف — ${ar(a.length)} آية (${ar(marks)} فيها اختلاف علامات بس)'
            : '❌ ${ar(bad)} آية فيها اختلاف حقيقي',
        kind: bad == 0 ? BubbleKind.ok : BubbleKind.no,
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < a.length; i++)
        if (results[i] != AyahMatch.exact)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: results[i] == AyahMatch.different ? AppColors.noBg : AppColors.noteBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${results[i] == AyahMatch.different ? '❌' : '🟡'} آية ${ar(a[i].number)}',
                  style: kidText(15, weight: FontWeight.w700)),
              for (final (k, list) in [(labels[0], a), (labels[1], b)]) ...[
                Text(k, style: kidText(11, weight: FontWeight.w600, color: AppColors.inkSoft)),
                Text(list[i].text, textAlign: TextAlign.center, style: ayahStyle(context)),
              ],
            ]),
          ),
    ]);
  }
}
