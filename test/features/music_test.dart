import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/app.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/music_service.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

class FakeMusic implements Music {
  bool quietNow = false;
  @override
  void quiet(bool yes) => quietNow = yes;
  @override
  void background(bool yes) {}
  @override
  void refresh() {}
  String themeNow = 'home';
  @override
  void theme(String id) => themeNow = id;
}

/// الموسيقى بتسكت لما ندخل عالم القرآن (حتى لو اتفتح بـ push) وبترجع لما نخرج.
void main() {
  testWidgets('music goes quiet in the Quran world and comes back outside', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'سارة', 'grade': 'p1'})});
    final prefs = await SharedPreferences.getInstance();
    final music = FakeMusic();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        musicProvider.overrideWithValue(music),
        quranChaptersProvider.overrideWith((ref) async => const [QuranChapter(112, 'الإخلاص', 4)]),
        surahProvider.overrideWith((ref, n) async => const [Ayah(1, 'قُلْ'), Ayah(2, 'هُوَ')]),
      ],
      child: const RehlatiApp(),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await settle();
    expect(music.quietNow, isFalse);

    await tester.tap(find.text('القرآن الكريم'));
    await settle();
    expect(music.quietNow, isTrue, reason: 'Quran world');

    await tester.tap(find.textContaining('الإخلاص').first);
    await settle();
    expect(music.quietNow, isTrue, reason: 'inside a surah');

    await tester.tap(find.text('↩').first);
    await settle();
    expect(music.quietNow, isTrue, reason: 'back to the surah list');

    await tester.tap(find.text('↩').first);
    await settle();
    expect(music.quietNow, isFalse, reason: 'home again');
    expect(music.themeNow, 'home');

    await tester.ensureVisible(find.text('ألعاب'));
    await settle();
    await tester.tap(find.text('ألعاب'));
    await settle();
    expect(music.themeNow, 'games', reason: 'each world has its mood');
    await tester.ensureVisible(find.text('فرقع البالونة'));
    await settle();
    await tester.tap(find.text('فرقع البالونة'));
    await settle();
    expect(music.themeNow, 'balloons', reason: 'and some games have their own');
    expect(music.quietNow, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
