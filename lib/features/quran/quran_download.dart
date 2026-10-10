/// تنزيل جزء كامل (النص + تلاوة القارئ المختار) عشان القرآن يشتغل من غير نت.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/quran_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/progress_controller.dart';
import 'quran_library.dart';
import 'quran_repository.dart';
import 'recitation.dart';

/// الجزء: اسمه وسوره.
typedef Juz = (String name, int from, int to);
const juzList = <Juz>[('جزء عمّ', 78, 114), ('جزء تبارك', 67, 77)];

/// "complete" بس لما كل آيات الجزء تبقى على الجهاز بصوت القارئ ده — صفر أخطاء لوحده مش كفاية.
enum DownloadPhase { downloading, cancelled, partial, failed, complete }

class DownloadState {
  const DownloadState({
    required this.juz,
    required this.reciter,
    this.phase = DownloadPhase.downloading,
    this.done = 0,
    this.total = 0,
    this.failed = 0,
    this.storageFull = false,
  });
  final String juz;

  /// القارئ اللي اتنزّلت تلاوته — تغيير القارئ بعدها مايخليش التاني "متنزّل".
  final String reciter;
  final DownloadPhase phase;
  final int done, total, failed;

  /// التنزيل وقف لأن مساحة الجهاز خلصت.
  final bool storageFull;

  bool get running => phase == DownloadPhase.downloading;
  double get pct => total == 0 ? 0 : done / total;

  DownloadState copyWith({DownloadPhase? phase, int? done, int? total, int? failed, bool? storageFull}) => DownloadState(
        juz: juz,
        reciter: reciter,
        phase: phase ?? this.phase,
        done: done ?? this.done,
        total: total ?? this.total,
        failed: failed ?? this.failed,
        storageFull: storageFull ?? this.storageFull,
      );
}

/// ملفات تلاوة الآيات على الجهاز — بتتبدّل في الاختبارات عشان مانلمسش النت.
class AyahAudioStore {
  const AyahAudioStore();

  /// الملف موجود وسليم — الملف التالف مابيتحسبش وبيتنزّل تاني.
  Future<bool> has(String folder, int surah, int ayah) async =>
      RecitationPlayer.isValid(await RecitationPlayer.cacheFile(folder, surah, ayah));

  Future<AyahFetch> fetch(String folder, int surah, int ayah) async => RecitationPlayer.fetch(
        QuranConfig.ayahAudioUrl(folder, surah, ayah),
        await RecitationPlayer.cacheFile(folder, surah, ayah),
      );
}

final ayahAudioStoreProvider = Provider<AyahAudioStore>((ref) => const AyahAudioStore());

/// تنزيل ماكملش (اتقفل التطبيق أو اتلغى أو فشل) — بيتحفظ عشان يكمل بعد إعادة الفتح.
typedef PendingJob = ({Juz juz, String reciter});

/// تنزيل واحد في نفس الوقت. state = null يعني مفيش تنزيل حصل من ساعة ما التطبيق اتفتح.
class QuranDownloader extends Notifier<DownloadState?> {
  static const jobKey = 'rehlati.quranJob.v1';
  int _run = 0;

  @override
  DownloadState? build() => null;

  /// آخر تنزيل ماكملش، من التخزين — بيفضل لحد ما يكمل.
  PendingJob? get pendingJob {
    try {
      final raw = ref.read(sharedPrefsProvider).getString(jobKey);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map;
      final juz = juzList.firstWhere((x) => x.$1 == j['juz']);
      final reciter = QuranConfig.reciters.firstWhere((r) => r.id == j['reciter']).id;
      return (juz: juz, reciter: reciter);
    } catch (_) {
      return null;
    }
  }

  /// الملفات اللي خلصت بتفضل على الجهاز، والمرة الجاية بتكمّل الناقص بس.
  void cancel() {
    final s = state;
    if (s == null || !s.running) return;
    _run++;
    state = s.copyWith(phase: DownloadPhase.cancelled);
  }

  /// [reciterId]: لإكمال تنزيل قديم بنفس قارئه — غير كده القارئ المختار.
  Future<void> start(Juz juz, {String? reciterId}) async {
    final my = ++_run;
    final (name, from, to) = juz;
    final repo = ref.read(quranRepositoryProvider);
    final store = ref.read(ayahAudioStoreProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final reciter = QuranConfig.reciter(reciterId ?? ref.read(reciterProvider).reciter);
    unawaited(prefs.setString(jobKey, jsonEncode({'juz': name, 'reciter': reciter.id})));
    var s = DownloadState(juz: name, reciter: reciter.label);
    // تنزيل قديم اتلغى أو اتبدّل مايغيّرش حالة التنزيل الجديد
    void emit(DownloadState next) {
      s = next;
      if (my == _run) state = next;
    }

    emit(s);
    try {
      final chapters = [for (final c in await repo.chapters()) if (c.number >= from && c.number <= to) c];
      if (chapters.length != to - from + 1) throw QuranException('قائمة السور ناقصة');
      final jobs = [
        for (final c in chapters)
          for (var a = 1; a <= c.ayahs; a++) (c.number, a),
      ];
      emit(s.copyWith(total: jobs.length));
      for (final c in chapters) {
        if (my != _run) return;
        await repo.surah(c.number); // النص بيتحفظ في الكاش
      }
      // ٤ في نفس الوقت: أسرع من واحد ورا التاني ومن غير ما نضغط على السيرفر
      var next = 0, done = 0, failed = 0;
      var full = false;
      Future<void> worker() async {
        while (my == _run && !full && next < jobs.length) {
          final (n, a) = jobs[next++];
          final r = await store.has(reciter.folder, n, a) ? AyahFetch.saved : await store.fetch(reciter.folder, n, a);
          if (my != _run) return;
          // المساحة خلصت: مفيش فايدة نكمّل — الباقي هيفشل كله
          if (r == AyahFetch.storageFull) full = true;
          r == AyahFetch.saved ? done++ : failed++;
          emit(s.copyWith(done: done, failed: failed));
        }
      }

      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
      if (my != _run) return;
      final complete = jobs.isNotEmpty && done == jobs.length;
      if (complete) unawaited(prefs.remove(jobKey));
      emit(s.copyWith(
        storageFull: full,
        phase: complete
            ? DownloadPhase.complete
            : full || done == 0
                ? DownloadPhase.failed
                : DownloadPhase.partial,
      ));
    } catch (_) {
      emit(s.copyWith(phase: DownloadPhase.failed));
    } finally {
      // المكتبة (اللي على الجهاز) اتغيّرت
      if (my == _run && ref.mounted) ref.invalidate(quranLibraryProvider);
    }
  }
}

final quranDownloadProvider = NotifierProvider<QuranDownloader, DownloadState?>(QuranDownloader.new);

/// الجملة اللي بتظهر لولي الأمر — "على الجهاز" بس لما الجزء يكمل فعلًا.
String downloadLabel(DownloadState s) => switch (s.phase) {
      DownloadPhase.downloading =>
        s.total == 0 ? '⏳ بنجهّز ${s.juz}…' : '⏳ بننزّل ${s.juz}… ${ar(s.done)} من ${ar(s.total)} آية',
      DownloadPhase.complete => '✅ ${s.juz} على الجهاز بصوت ${s.reciter} — يشتغل من غير نت',
      DownloadPhase.cancelled => s.done == 0
          ? '⏹️ وقّفنا تنزيل ${s.juz}'
          : '⏹️ وقّفنا ${s.juz} — اتنزّل ${ar(s.done)} من ${ar(s.total)}، دوس تاني تكمّل الباقي',
      DownloadPhase.partial => '⚠️ اتنزّل ${ar(s.done)} من ${ar(s.total)} — جرّب تاني تكمّل الباقي',
      DownloadPhase.failed when s.storageFull =>
        '⚠️ مساحة الجهاز خلصت — اتنزّل ${ar(s.done)} من ${ar(s.total)}. فضّي مساحة ودوس كمّل',
      DownloadPhase.failed => s.done == 0
          ? '⚠️ مقدرناش ننزّل ${s.juz} — اتأكد من النت وجرّب تاني'
          : '⚠️ اتنزّل ${ar(s.done)} من ${ar(s.total)} — جرّب تاني تكمّل الباقي',
    };

/// كارت لوحة ولي الأمر: التنزيل، اللي على الجهاز لكل قارئ وجزء، والمسح.
class QuranDownloadCard extends ConsumerWidget {
  const QuranDownloadCard({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Reciter r, {Juz? juz}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('تمسح التلاوة؟', style: kidText(20)),
        content: Text('${juz?.$1 ?? 'كل التلاوات'} بصوت ${r.label}. الحفظ والنجوم مش هيتمسحوا، '
            'والتلاوة هتتنزّل تاني لما تتسمع أو تنزّلها.', style: kidText(15, weight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
          TextButton(onPressed: () => c.pop(true), child: const Text('امسح', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (ok != true) return;
    await deleteAudio(await RecitationPlayer.root(), r, juz: juz);
    ref.invalidate(quranLibraryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranDownloadProvider);
    final dl = ref.read(quranDownloadProvider.notifier);
    final reciter = QuranConfig.reciter(ref.watch(reciterProvider).reciter);
    final lib = ref.watch(quranLibraryProvider).value;
    final mine = lib?.where((x) => x.reciter.id == reciter.id).firstOrNull;
    final others = [for (final x in lib ?? const <ReciterStatus>[]) if (x.reciter.id != reciter.id && x.present > 0) x];
    final pending = s == null ? dl.pendingJob : null;
    final running = s?.running ?? false;
    final body = kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft);
    String mb(int b) => fmtBytes(b, ar);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('نزّل الجزء مرة واحدة على واي فاي، وبعدها القرآن يشتغل في أي مكان من غير نت. '
          'القارئ المختار: ${reciter.label}.', style: body),
      const SizedBox(height: 10),
      if (s != null) ...[
        Text(downloadLabel(s), style: kidText(15)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: s.pct, minHeight: 10, color: AppColors.mint, backgroundColor: AppColors.line),
        ),
        const SizedBox(height: 10),
      ] else if (pending != null) ...[
        Text('⏸️ تنزيل ${pending.juz.$1} بصوت ${QuranConfig.reciter(pending.reciter).label} ماكملش', style: kidText(15)),
        Center(
          child: KidButton('⬇️ كمّل التنزيل',
              onTap: () => unawaited(dl.start(pending.juz, reciterId: pending.reciter))),
        ),
        const SizedBox(height: 6),
      ],
      if (running) Center(child: KidButton('⏹️ وقّف', kind: BtnKind.ghost, onTap: dl.cancel)),
      // القارئ المختار: كل جزء وحالته
      for (final j in mine?.juz ?? const <JuzStatus>[])
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${j.complete ? '✅' : j.present > 0 ? '🟡' : '⬜'} ${j.juz.$1}', style: kidText(16)),
                Text(
                  'التلاوة: ${j.complete ? 'كاملة' : j.expected == null ? '${ar(j.present)} آية' : '${ar(j.present)} من ${ar(j.expected!)} آية'}'
                  '${j.bytes > 0 ? ' • ${mb(j.bytes)}' : ''}'
                  ' • النص: ${j.textCached == j.surahs ? 'كامل' : '${ar(j.textCached)} من ${ar(j.surahs)} سورة'}'
                  '${!j.complete && j.expected != null ? ' • الباقي حوالي ${mb((j.expected! - j.present) * mine!.bytesPerAyah)}' : ''}',
                  style: body,
                ),
              ]),
            ),
            if (!running && !j.complete)
              TextButton(
                onPressed: () => unawaited(dl.start(j.juz)),
                child: Text(j.present > 0 ? '⬇️ كمّل' : '⬇️ نزّل', style: kidText(14, color: AppColors.grape)),
              ),
            if (!running && j.present > 0)
              IconButton(
                tooltip: 'امسح',
                onPressed: () => _delete(context, ref, reciter, juz: j.juz),
                icon: const Text('🗑️', style: TextStyle(fontSize: 18)),
              ),
          ]),
        ),
      if (mine != null && mine.damaged > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${ar(mine.damaged)} ملف تالف — هيتنزّل تاني مع "كمّل".', style: body),
        ),
      // قراء تانيين متنزّل لهم حاجة: قرّاء المرتّل لوحدهم والمعلّم لوحدهم
      for (final (title, list) in [
        ('قرّاء تانيين على الجهاز', [for (final x in others) if (!x.reciter.teacher) x]),
        ('تلاوة المعلّم (الترديد) على الجهاز', [for (final x in others) if (x.reciter.teacher) x]),
      ])
        if (list.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(title, style: kidText(15)),
          for (final x in list)
            Row(children: [
              Expanded(
                child: Text(
                  '${x.reciter.label}: ${[for (final j in x.juz) if (j.present > 0) '${j.juz.$1} ${j.complete ? '✅' : '${ar(j.present)} آية'}'].join(' • ')} (${mb(x.bytes)})',
                  style: body,
                ),
              ),
              if (!running)
                IconButton(
                  tooltip: 'امسح',
                  onPressed: () => _delete(context, ref, x.reciter),
                  icon: const Text('🗑️', style: TextStyle(fontSize: 18)),
                ),
            ]),
        ],
    ]);
  }
}
