
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/paths.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/journey/journey.dart';
import 'package:rehlati/features/game/game_screen.dart';
import 'package:rehlati/features/home/home_screen.dart';
import 'package:rehlati/features/daily/time_up_screen.dart';
import 'package:rehlati/features/letter_board/letter_board_screen.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_modes.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/paths/paths_screen.dart';
import 'package:rehlati/features/quran/quran_screens.dart';
import 'package:rehlati/features/world_map/world_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// مراجعة الوصول: كل زرار ليه اسم لقارئ الشاشة، وأهداف اللمس ٤٨ نقطة (أندرويد) و٤٤ (iOS)
/// على موبايل صغير وخط ١.٣. أول سؤال من كل مرحلة — المولّدات seeded فالنتيجة ثابتة.
///
/// التباين (textContrastGuideline) مش هنا: ألوان الكروت محتاجة قرار تصميم — docs/PLAN.md C2.
void main() {
  const ayahs = [Ayah(1, 'كلمة أولى طويلة شوية'), Ayah(2, 'كلمة تانية'), Ayah(3, 'كلمة تالتة ۚ هنا'), Ayah(4, 'رابعة')];

  Future<void> pump(WidgetTester tester, Widget screen, {Map<String, Object> prefs = const {}}) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        rngProvider.overrideWithValue(Rng.seeded(5)),
        quranChaptersProvider.overrideWith((ref) async => const [QuranChapter(112, 'الإخلاص', 4)]),
        surahProvider.overrideWith((ref, n) async => ayahs),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: screen,
      ),
    ));
    // أنيميشن متكررة (المشاهد) — مش بنستنى settle
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  final screens = <String, Widget>{
    'home': const HomeScreen(),
    for (final w in ['math', 'arabic', 'english', 'games']) 'world $w': WorldMapScreen(world: w),
    for (final s in packs.values.where((s) => !s.isLearn)) 'play ${s.id}': GameScreen(stageId: s.id),
    'learn ar_learn': const LetterBoardScreen(stageId: 'ar_learn'),
    'quran home': const QuranHomeScreen(),
    'surah': const SurahScreen(surah: 112),
    for (final m in quranModes) 'quran ${m.id}': QuranModeScreen(surah: 112, mode: m.id),
    'journey': const JourneyScreen(),
    'paths': const PathsScreen(),
    for (final path in learningPaths) 'path ${path.id}': PathScreen(id: path.id),
    'time up': const TimeUpScreen(),
    'dashboard': const DashboardScreen(),
    'dashboard guide': const DashboardScreen(tab: DashTab.guide),
    'dashboard settings': const DashboardScreen(tab: DashTab.settings),
    'first-launch intro': const HomeScreen(),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key}: labelled tap targets of a comfortable size', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, e.value, prefs: e.key == 'home' ? {ProgressRepository.key: '{"setupDone": true}'} : const {});
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
