/// تنزيل جزء كامل (النص + تلاوة القارئ المختار) عشان القرآن يشتغل من غير نت.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/quran_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
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
  });
  final String juz;

  /// القارئ اللي اتنزّلت تلاوته — تغيير القارئ بعدها مايخليش التاني "متنزّل".
  final String reciter;
  final DownloadPhase phase;
  final int done, total, failed;

  bool get running => phase == DownloadPhase.downloading;
  double get pct => total == 0 ? 0 : done / total;

  DownloadState copyWith({DownloadPhase? phase, int? done, int? total, int? failed}) => DownloadState(
        juz: juz,
        reciter: reciter,
        phase: phase ?? this.phase,
        done: done ?? this.done,
        total: total ?? this.total,
        failed: failed ?? this.failed,
      );
}

/// ملفات تلاوة الآيات على الجهاز — بتتبدّل في الاختبارات عشان مانلمسش النت.
class AyahAudioStore {
  const AyahAudioStore();

  Future<bool> has(String folder, int surah, int ayah) async =>
      (await RecitationPlayer.cacheFile(folder, surah, ayah)).existsSync();

  /// true لو الآية بقت على الجهاز.
  Future<bool> fetch(String folder, int surah, int ayah) async => RecitationPlayer.download(
        QuranConfig.ayahAudioUrl(folder, surah, ayah),
        await RecitationPlayer.cacheFile(folder, surah, ayah),
      );
}

final ayahAudioStoreProvider = Provider<AyahAudioStore>((ref) => const AyahAudioStore());

/// تنزيل واحد في نفس الوقت. state = null يعني مفيش تنزيل حصل.
class QuranDownloader extends Notifier<DownloadState?> {
  int _run = 0;

  @override
  DownloadState? build() => null;

  /// الملفات اللي خلصت بتفضل على الجهاز، والمرة الجاية بتكمّل الناقص بس.
  void cancel() {
    final s = state;
    if (s == null || !s.running) return;
    _run++;
    state = s.copyWith(phase: DownloadPhase.cancelled);
  }

  Future<void> start(Juz juz) async {
    final my = ++_run;
    final (name, from, to) = juz;
    final repo = ref.read(quranRepositoryProvider);
    final store = ref.read(ayahAudioStoreProvider);
    final reciter = QuranConfig.reciter(ref.read(reciterProvider).reciter);
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
      Future<void> worker() async {
        while (my == _run && next < jobs.length) {
          final (n, a) = jobs[next++];
          final ok = await store.has(reciter.folder, n, a) || await store.fetch(reciter.folder, n, a);
          if (my != _run) return;
          ok ? done++ : failed++;
          emit(s.copyWith(done: done, failed: failed));
        }
      }

      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
      if (my != _run) return;
      emit(s.copyWith(
        phase: jobs.isNotEmpty && done == jobs.length
            ? DownloadPhase.complete
            : done == 0
                ? DownloadPhase.failed
                : DownloadPhase.partial,
      ));
    } catch (_) {
      emit(s.copyWith(phase: DownloadPhase.failed));
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
      DownloadPhase.failed => s.done == 0
          ? '⚠️ مقدرناش ننزّل ${s.juz} — اتأكد من النت وجرّب تاني'
          : '⚠️ اتنزّل ${ar(s.done)} من ${ar(s.total)} — جرّب تاني تكمّل الباقي',
    };

/// كارت لوحة ولي الأمر.
class QuranDownloadCard extends ConsumerWidget {
  const QuranDownloadCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quranDownloadProvider);
    final dl = ref.read(quranDownloadProvider.notifier);
    final reciter = QuranConfig.reciter(ref.watch(reciterProvider).reciter);
    final body = kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('نزّل الجزء مرة واحدة على واي فاي، وبعدها القرآن يشتغل في أي مكان من غير نت. '
          'التلاوة بصوت ${reciter.label} (حوالي ٥٠ ميجا لجزء عمّ).', style: body),
      const SizedBox(height: 10),
      if (s != null) ...[
        Text(downloadLabel(s), style: kidText(15)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: s.pct, minHeight: 10, color: AppColors.mint, backgroundColor: AppColors.line),
        ),
        const SizedBox(height: 10),
      ],
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 4, children: [
        if (s?.running ?? false)
          KidButton('⏹️ وقّف', kind: BtnKind.ghost, onTap: dl.cancel)
        else
          for (final j in juzList) KidButton('⬇️ ${j.$1}', onTap: () => unawaited(dl.start(j))),
      ]),
    ]);
  }
}
