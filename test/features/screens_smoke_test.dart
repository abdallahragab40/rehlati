import 'dart:convert';

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
import 'package:rehlati/features/achievements/achievements_screen.dart';
import 'package:rehlati/features/game/game_screen.dart';
import 'package:rehlati/features/home/home_screen.dart';
import 'package:rehlati/features/intro/intro_screen.dart';
import 'package:rehlati/content/parent_guide.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/features/daily/time_up_screen.dart';
import 'package:rehlati/features/letter_board/letter_board_screen.dart';
import 'package:rehlati/features/madd/madd_lesson_screen.dart';
import 'package:rehlati/features/parent_guide/pg_screens.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/parent/guide_screen.dart';
import 'package:rehlati/features/quran/quran_modes.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/paths/paths_screen.dart';
import 'package:rehlati/features/quran/quran_screens.dart';
import 'package:rehlati/features/world_map/world_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// كل شاشة على موبايل صغير (٣٦٠ نقطة) وخط النظام ١.٣ — من غير overflow ولا استثناءات.
void main() {
  // عينات قصيرة للاختبار بس
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
    expect(tester.takeException()?.toString(), isNull);
    // نشيل الشاشة عشان المؤقتات والـ tickers تتقفل
    await tester.pumpWidget(const SizedBox());
  }

  final screens = <String, Widget>{
    'first-launch intro': const HomeScreen(), // جهاز جديد ← الترحيب
    for (final w in ['math', 'arabic', 'english', 'games']) 'world $w': WorldMapScreen(world: w),
    for (final s in packs.values.where((s) => !s.isLearn)) 'play ${s.id}': GameScreen(stageId: s.id),
    for (final s in packs.values.where((s) => s.isMadd)) 'madd lesson ${s.id}': MaddLessonScreen(stageId: s.id),
    for (final s in packs.values.where((s) => s.isLearn)) 'learn ${s.id}': LetterBoardScreen(stageId: s.id),
    'achievements': const AchievementsScreen(),
    'dashboard': const DashboardScreen(),
    'dashboard guide': const DashboardScreen(tab: DashTab.guide),
    'dashboard settings': const DashboardScreen(tab: DashTab.settings),
    'guide': const GuideScreen(),
    'quran home': const QuranHomeScreen(),
    'surah': const SurahScreen(surah: 112),
    for (final m in quranModes) 'quran ${m.id}': QuranModeScreen(surah: 112, mode: m.id),
    'parent guide home': const PgHomeScreen(),
    for (final b in pgBehaviors) 'parent guide ${b.id}': PgDetailScreen(id: b.id),
    'parent guide goals': const PgGoalsScreen(),
    'kid hub': const KidHubScreen(),
    'time up': const TimeUpScreen(),
    'journey': const JourneyScreen(),
    'paths': const PathsScreen(),
    for (final path in learningPaths) 'path ${path.id}': PathScreen(id: path.id),
    'kid play': KidPlayScreen(ids: [for (final b in pgBehaviors.take(3)) b.id]),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} renders on a small phone with large text', (tester) => pump(tester, e.value));
  }

  testWidgets('first-launch setup renders on a small phone with large text',
      (tester) => pump(tester, const HomeScreen(), prefs: {IntroController.key: true})); // بعد الترحيب ← الاسم والعمر

  // تدريب صغير: الطفل غلط ٣ مرات في المد بالواو، ومعاه هدف في دليل ولي الأمر
  testWidgets('madd small practice and dashboard with data render', (tester) async {
    final blob = jsonEncode({
      'skills': {'madd_alif|madd:waw': 3},
      'best': {'ar_table': 2, 'madd_alif': 2},
      'madd': {'types': {'alif': {'ok': 9, 'tries': 10}}, 'words': {'باب': {'ok': 2, 'tries': 2}}},
      'parentGuide': {'focus': {'hit': {'start': 1, 'days': [true, true, false, false, false, false, false], 'paused': false}}},
      'stars': 420,
      'settings': {'speech': true, 'sfx': true, 'goal': 25, 'limitMin': 30},
      'days': {
        for (var i = 0; i < 10; i++)
          ProgressData.dayKey(DateTime.now().subtract(Duration(days: i))): {'stars': 3 * i, 'correct': 5, 'wrong': 1, 'games': 2, 'ms': 600000},
      },
    });
    await pump(tester, const MaddLessonScreen(stageId: 'madd_waw'), prefs: {ProgressRepository.key: blob});
    await pump(tester, const DashboardScreen(), prefs: {ProgressRepository.key: blob});
    await pump(tester, const HomeScreen(), prefs: {ProgressRepository.key: blob});
    await pump(tester, const AchievementsScreen(), prefs: {ProgressRepository.key: blob});
  });

  testWidgets('a journey with skipped steps renders for the child and the parent', (tester) async {
    String blob(List<Map<String, Object>> steps) => jsonEncode({
          'name': 'يوسف',
          'setupDone': true,
          'journey': {'day': ProgressData.dayKey(DateTime.now()), 'steps': steps},
        });
    final midway = blob([
      {'kind': 'warm', 'target': 'stage:counting', 'skipped': true},
      {'kind': 'practice', 'target': 'stage:completeTable'},
      {'kind': 'fresh', 'target': 'stage:ar_connect'},
    ]);
    final allPassed = blob([
      {'kind': 'warm', 'target': 'stage:counting', 'skipped': true},
      {'kind': 'practice', 'target': 'stage:completeTable', 'done': true},
    ]);
    for (final b in [midway, allPassed]) {
      await pump(tester, const JourneyScreen(), prefs: {ProgressRepository.key: b});
      await pump(tester, const HomeScreen(), prefs: {ProgressRepository.key: b});
      await pump(tester, const DashboardScreen(), prefs: {ProgressRepository.key: b});
    }
  });

  testWidgets('world maps and dashboard with parent-skipped stages render', (tester) async {
    final blob = jsonEncode({
      'name': 'يوسف',
      'setupDone': true,
      'unlocked': ['counting', 'chooseNumber', 'nextNumber', 'ar_learn', 'ar_pick', 'en_learn', 'en_pick'],
      'skipped': ['counting', 'chooseNumber', 'ar_learn', 'en_learn'],
    });
    for (final w in ['math', 'arabic', 'english']) {
      await pump(tester, WorldMapScreen(world: w), prefs: {ProgressRepository.key: blob});
    }
    await pump(tester, const DashboardScreen(), prefs: {ProgressRepository.key: blob});
  });

  testWidgets('home and dashboard with two children render', (tester) async {
    final prefs = <String, Object>{
      ProgressRepository.profilesKey: jsonEncode({'active': 'main', 'ids': ['main', 'c1']}),
      ProgressRepository.key: jsonEncode({'name': 'يوسف', 'age': 5, 'setupDone': true, 'stars': 12}),
      ProgressRepository.keyFor('c1'): jsonEncode({'name': 'مريم', 'age': 4, 'setupDone': true, 'stars': 3}),
    };
    await pump(tester, const HomeScreen(), prefs: prefs);
    await pump(tester, const DashboardScreen(), prefs: prefs);
  });
}
