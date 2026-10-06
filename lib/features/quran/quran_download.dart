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

class DownloadState {
  const DownloadState({required this.juz, this.done = 0, this.total = 0, this.failed = 0, this.running = false});
  final String juz;
  final int done, total, failed;
  final bool running;

  double get pct => total == 0 ? 0 : done / total;
}

/// تنزيل واحد في نفس الوقت. state = null يعني مفيش تنزيل حصل.
class QuranDownloader extends Notifier<DownloadState?> {
  int _run = 0;

  @override
  DownloadState? build() => null;

  void cancel() {
    _run++;
    final s = state;
    if (s != null) state = DownloadState(juz: s.juz, done: s.done, total: s.total, failed: s.failed);
  }

  Future<void> start(Juz juz) async {
    final my = ++_run;
    final (name, from, to) = juz;
    final repo = ref.read(quranRepositoryProvider);
    final folder = QuranConfig.reciter(ref.read(reciterProvider).reciter).folder;
    state = DownloadState(juz: name, running: true);
    try {
      final chapters = [for (final c in await repo.chapters()) if (c.number >= from && c.number <= to) c];
      final jobs = [
        for (final c in chapters)
          for (var a = 1; a <= c.ayahs; a++) (c.number, a),
      ];
      var done = 0, failed = 0;
      void tick() {
        if (my == _run) state = DownloadState(juz: name, done: done, total: jobs.length, failed: failed, running: true);
      }

      tick();
      for (final c in chapters) {
        if (my != _run) return;
        await repo.surah(c.number); // النص بيتحفظ في الكاش
      }
      // ٤ في نفس الوقت: أسرع من واحد ورا التاني ومن غير ما نضغط على السيرفر
      var next = 0;
      Future<void> worker() async {
        while (my == _run && next < jobs.length) {
          final (s, a) = jobs[next++];
          final ok = await RecitationPlayer.download(
            QuranConfig.ayahAudioUrl(folder, s, a),
            await RecitationPlayer.cacheFile(folder, s, a),
          );
          ok ? done++ : failed++;
          tick();
        }
      }

      await Future.wait([for (var i = 0; i < 4; i++) worker()]);
      if (my == _run) state = DownloadState(juz: name, done: done, total: jobs.length, failed: failed);
    } catch (_) {
      if (my == _run) state = DownloadState(juz: name, failed: 1);
    }
  }
}

final quranDownloadProvider = NotifierProvider<QuranDownloader, DownloadState?>(QuranDownloader.new);

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
      if (s != null && (s.running || s.total > 0 || s.failed > 0)) ...[
        Text(
          s.running
              ? '⏳ بننزّل ${s.juz}… ${ar(s.done)} من ${ar(s.total)} آية'
              : s.failed == 0
                  ? '✅ ${s.juz} على الجهاز — يشتغل من غير نت'
                  : s.total == 0
                      ? '⚠️ مفيش نت دلوقتي — جرّب تاني'
                      : '⚠️ اتنزّل ${ar(s.done)} من ${ar(s.total)} — جرّب تاني تكمّل الباقي',
          style: kidText(15),
        ),
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
