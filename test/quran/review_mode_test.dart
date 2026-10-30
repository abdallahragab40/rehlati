import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/quran/quran_modes.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// المراجعة كلها لحد الآخر: «الآية اللي بعدها» و«كمّل الآية» بالتبادل، حتى لو «كمّل الآية»
/// اختارت آخر آية في السورة (مالهاش آية بعدها).
void main() {
  // عينات قصيرة للاختبار بس (مش نص قرآني) — كل آية فيها كلمتين أو أكتر
  const ayahs = [Ayah(1, 'كلمة أولى طويلة'), Ayah(2, 'كلمة تانية هنا'), Ayah(3, 'كلمة تالتة هناك'), Ayah(4, 'رابعة وخلاص')];

  for (var seed = 0; seed < 8; seed++) {
    testWidgets('a full review round works (seed $seed)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sp),
          speechProvider.overrideWithValue(FakeSpeech()),
          sfxProvider.overrideWithValue(FakeSfx()),
          rngProvider.overrideWithValue(Rng.seeded(seed)),
          quranChaptersProvider.overrideWith((ref) async => const [QuranChapter(112, 'الإخلاص', 4)]),
          surahProvider.overrideWith((ref, n) async => ayahs),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: QuranModeScreen(surah: 112, mode: 'review'),
        ),
      ));
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      await settle();
      var sawFill = false;
      // كل سؤال: جرّب الاختيارات لحد الصح (الآيات والكلمات كلها نصوص في الاختيارات)
      final candidates = {for (final a in ayahs) ...[a.text, ...a.text.split(' ')]};
      for (var q = 0; q < 3 && find.textContaining('من ٣ —').evaluate().isEmpty; q++) {
        sawFill |= find.text('كمّل الآية').evaluate().isNotEmpty;
        final before = find.textContaining('سؤال ${['١', '٢', '٣'][q]} من').evaluate().isNotEmpty;
        expect(before, isTrue, reason: 'question ${q + 1}');
        for (final c in candidates) {
          final f = find.text(c);
          if (f.evaluate().isEmpty) continue;
          await tester.tap(f.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
          final right = find.textContaining('صح!').evaluate().isNotEmpty || find.textContaining('أحسنت').evaluate().isNotEmpty;
          await settle();
          if (right) break;
        }
      }
      expect(tester.takeException(), isNull);
      expect(sawFill, isTrue, reason: 'the second question completes the ayah');
      expect(find.textContaining('من ٣ —'), findsOneWidget, reason: 'the round finished');
      // احتفال الختام ليه مؤقتات
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
