import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/app.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;
import 'music_test.dart' show FakeMusic;
import 'parent_flow_test.dart' show answerOf;

/// إضافة طفل ومسحه من لوحة ولي الأمر والرجوع للرئيسية — على مقاس التابلت.
/// الرئيسية مستخبية ورا اللوحة (Riverpod بيوقف متابعتها)، ولما ترجع تظهر ماينفعش
/// تبلّغ كارت الأطفال اللي في اللوحة وهي بتتبني (setState during build).
void main() {
  testWidgets('add and remove a sibling from the parent dashboard on a tablet', (tester) async {
    tester.view
      ..physicalSize = const Size(2048, 2732)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'سارة', 'age': 5}),
      'rehlati.intro.v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        musicProvider.overrideWithValue(FakeMusic()),
        quranChaptersProvider.overrideWith((ref) async => const <QuranChapter>[]),
      ],
      child: const RehlatiApp(),
    ));
    // الرئيسية فيها حركة مستمرة — pumpAndSettle مابيخلصش
    Future<void> settle([int frames = 8]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();

    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f.first);
      await settle(2);
      await tester.tap(f.first);
      await settle();
    }

    Future<void> openParent() async {
      await tap(find.text('⚙️'));
      final row = find.ancestor(of: find.text('👨‍👩‍👦 لوحة ولي الأمر'), matching: find.byType(Row));
      await tap(find.descendant(of: row, matching: find.text('افتح')));
      await tester.enterText(find.byType(TextField), '${answerOf(tester.widget<Text>(find.textContaining('كام')).data!)}');
      await tap(find.text('دخول'));
    }

    await openParent();
    await tap(find.text('➕ إضافة طفل'));
    await tester.enterText(find.byType(TextField), 'عمر');
    await settle();
    await tap(find.text('أولى'));
    await tap(find.text('🚀 يلا نبدأ'));

    // التبديل من صورة الطفل في الرئيسية
    await tap(find.text('🔄'));
    await tap(find.text('سارة'));

    await openParent();
    final omar = find.ancestor(of: find.textContaining('عمر •'), matching: find.byType(Row));
    await tap(find.descendant(of: omar, matching: find.byType(IconButton)));
    await tap(find.widgetWithText(TextButton, 'امسح'));
    await tap(find.text('رجوع'));

    final repo = ProviderScope.containerOf(tester.element(find.byType(RehlatiApp))).read(progressRepositoryProvider);
    expect(repo.ids, [ProgressRepository.mainId]);
  });
}
