/// عالم القرآن: قائمة السور (رحلة) وشاشة السورة — منقول من QuranWorld في js/quran.js.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/quran_config.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import 'quran_repository.dart';
import 'quran_widgets.dart';
import 'recitation.dart';

class QuranMode {
  const QuranMode(this.id, this.icon, this.name, this.desc);
  final String id, icon, name, desc;
}

const quranModes = [
  QuranMode('listen', '🎧', 'الاستماع', 'اسمع السورة آية آية'),
  QuranMode('repeat', '🗣️', 'الترديد', 'ردّد ورا الشيخ'),
  QuranMode('memorize', '📖', 'الحفظ', 'رتّب كلمات الآية'),
  QuranMode('review', '🔄', 'المراجعة', 'إيه الآية اللي بعدها؟'),
];

/// بيحمّل السورة (من الكاش أو النت) ويعرض التحميل أو الخطأ، وبعدين [builder].
class SurahLoader extends ConsumerWidget {
  const SurahLoader({super.key, required this.surah, required this.title, required this.builder});
  final int surah;
  final String? title;
  final Widget Function(BuildContext context, QuranChapter chapter, List<Ayah> ayahs) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(quranChaptersProvider);
    final ayahs = ref.watch(surahProvider(surah));
    final chapter = chapters.value?.where((c) => c.number == surah).firstOrNull;
    final error = chapters.error ?? ayahs.error;
    Widget body;
    if (error != null) {
      body = QuranFailed(
        error: error,
        sourceLabel: ref.read(quranRepositoryProvider).sourceLabel(),
        onRetry: () => ref
          ..invalidate(quranChaptersProvider)
          ..invalidate(surahProvider(surah)),
        onHome: () => context.go('/'),
      );
    } else if (chapter == null || !ayahs.hasValue) {
      body = QuranLoading(chapter == null ? 'لحظة واحدة…' : 'بنفتح سورة ${chapter.name}');
    } else {
      body = builder(context, chapter, ayahs.value!);
    }
    return ScreenFrame(
      onBack: () => context.back(),
      title: title ?? chapter?.name,
      background: const QuranSky(),
      child: body,
    );
  }
}

// ---------------------------------------------------------------- قائمة السور

class QuranHomeScreen extends ConsumerWidget {
  const QuranHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(quranChaptersProvider);
    final p = ref.watch(progressProvider);
    Widget body;
    if (chapters.hasError) {
      body = QuranFailed(
        error: chapters.error!,
        sourceLabel: ref.read(quranRepositoryProvider).sourceLabel(),
        onRetry: () => ref.invalidate(quranChaptersProvider),
        onHome: () => context.back(),
      );
    } else if (!chapters.hasValue) {
      body = const QuranLoading('لحظة واحدة…');
    } else {
      body = _SurahPath(chapters: chapters.value!, progress: p);
    }
    return ScreenFrame(
      onBack: () => context.back(),
      title: '📖 القرآن',
      background: const QuranSky(),
      child: Column(children: [
        const SizedBox(height: 6),
        const Banner3D('📖 عالم القرآن', color: quranMint, tone: quranMintDark, ink: Color(0xFF04332C)),
        const SizedBox(height: 14),
        Text(QuranConfig.rangeTitle,
            style: kidText(context.clampVw(22, 6, 32), color: Colors.white)
                .copyWith(shadows: const [Shadow(color: Color(0x4D1B3557), offset: Offset(0, 3))])),
        const HeroText('اختار سورة وابدأ الرحلة'),
        const SizedBox(height: 22),
        body,
      ]),
    );
  }
}

class _SurahPath extends StatelessWidget {
  const _SurahPath({required this.chapters, required this.progress});
  final List<QuranChapter> chapters;
  final ProgressData progress;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(children: [
          const _Pill('🕌 البداية', AppColors.gold, AppColors.goldDark, Color(0xFF4A2B00)),
          for (var i = 0; i < chapters.length; i++) ...[
            const _Link(),
            // عنوان الجزء بيظهر مرة واحدة قبل أول سورة فيه
            if (i == 0 || QuranConfig.juzOf(chapters[i - 1].number) != QuranConfig.juzOf(chapters[i].number)) ...[
              _Pill(QuranConfig.juzOf(chapters[i].number), quranMint, quranMintDark, Colors.white),
              const _Link(),
            ],
            LayoutBuilder(
              builder: (context, box) => Align(
                // محطات متعرّجة: الأولى ناحية الشمال والتانية ناحية اليمين
                alignment: i.isEven ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: i.isEven ? box.maxWidth * .06 : 0,
                    start: i.isOdd ? box.maxWidth * .06 : 0,
                  ),
                  child: SizedBox(
                    width: (box.maxWidth * .88).clamp(0, 320),
                    child: _SurahStop(chapter: chapters[i], progress: progress),
                  ),
                ),
              ),
            ),
          ],
          const _Link(),
          const _Pill('🌟 تمّت الرحلة', quranMint, quranMintDark, Color(0xFF04332C)),
        ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color, this.tone, this.ink);
  final String text;
  final Color color, tone, ink;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: tone, offset: const Offset(0, 5))],
        ),
        child: Text(text, style: kidText(17, color: ink)),
      );
}

class _Link extends StatelessWidget {
  const _Link();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(children: [
          for (var i = 0; i < 2; i++)
            Container(
              width: 10,
              height: 7,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: const Color(0xBFFFFFFF), borderRadius: BorderRadius.circular(99)),
            ),
        ]),
      );
}

class _SurahStop extends StatelessWidget {
  const _SurahStop({required this.chapter, required this.progress});
  final QuranChapter chapter;
  final ProgressData progress;

  @override
  Widget build(BuildContext context) {
    final stars = progress.surahStars(chapter.number);
    final (bg, fg) = stars == 4
        ? (AppColors.gold, const Color(0xFF4A2B00))
        : stars > 0
            ? (quranMint, Colors.white)
            : (const Color(0xFF9FB8CC), Colors.white);
    return Pressable3D(
      onTap: () => context.push('/quran/${chapter.number}'),
      radius: 24,
      shadowColor: AppColors.shadow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      semanticLabel: 'سورة ${chapter.name}، ${ar(stars)} من ٤ أنشطة',
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Text(ar(chapter.number), style: kidText(18, color: fg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chapter.name, style: kidText(20, height: 1.3)),
            Text('${ar(chapter.ayahs)} آيات', style: kidText(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ]),
        ),
        Column(children: [
          for (final m in quranModes)
            Opacity(
              opacity: progress.quranDone(chapter.number, m.id) ? 1 : .22,
              child: Text(m.icon, style: const TextStyle(fontSize: 12, height: 1.15)),
            ),
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------- شاشة السورة

class SurahScreen extends ConsumerWidget {
  const SurahScreen({super.key, required this.surah});
  final int surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final reciter = ref.watch(reciterProvider).reciter;
    return SurahLoader(
      surah: surah,
      title: null,
      builder: (context, chapter, ayahs) => Column(children: [
        const SizedBox(height: 6),
        Banner3D(chapter.name, color: quranMint, tone: quranMintDark, ink: const Color(0xFF04332C)),
        const SizedBox(height: 6),
        HeroText('${ar(ayahs.length)} آيات — اختار إيه اللي عايز تعمله'),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: TileWrap(
            minTileWidth: 150,
            spacing: 12,
            maxColumns: 2,
            children: [
              for (final m in quranModes)
                Pressable3D(
                  onTap: () => context.push('/quran/$surah/${m.id}'),
                  radius: 24,
                  shadowColor: AppColors.shadow,
                  semanticLabel: m.name,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Stack(children: [
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(m.icon, style: const TextStyle(fontSize: 40, height: 1.1)),
                        const SizedBox(height: 6),
                        Text(m.name, style: kidText(20)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(m.desc,
                              textAlign: TextAlign.center,
                              style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
                        ),
                      ]),
                    ),
                    if (p.quranDone(surah, m.id))
                      const PositionedDirectional(top: 10, start: 12, child: Text('⭐', style: TextStyle(fontSize: 16))),
                  ]),
                ),
            ],
          ),
        ),
        ReciterPicker(
          label: '🎙️ القارئ',
          value: reciter,
          options: QuranConfig.reciters,
          onChanged: ref.read(reciterProvider.notifier).setReciter,
        ),
      ]),
    );
  }
}
