import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/sfx_service.dart';
import 'package:rehlati/core/widgets/kid_widgets.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/school/lesson_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;
import '../domain/lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles()) l.id: l};

  /// الشرح على موبايل صغير (٣٦٠ نقطة) وخط النظام ١.٣، وبعده «تدرّب لوحدك» بيروح للجولة.
  Future<(ProviderContainer, FakeSpeech, FakeSfx)> open(WidgetTester tester, String id) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final speech = FakeSpeech(), sfx = FakeSfx();
    final router = GoRouter(initialLocation: '/lesson/$id', routes: [
      GoRoute(path: '/lesson/:id', builder: (_, s) => LessonScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/play/:stage', builder: (_, s) => Text('play ${s.pathParameters['stage']}')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(sp),
        speechProvider.overrideWithValue(speech),
        sfxProvider.overrideWithValue(sfx),
        lessonsProvider.overrideWith((ref) async => lessons),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
      ),
    ));
    await settle(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(LessonScreen)));
    return (container, speech, sfx);
  }

  KidButton? goButton(WidgetTester tester) => tester
      .widgetList<KidButton>(find.byType(KidButton))
      .where((b) => b.kind == BtnKind.go)
      .firstOrNull;

  for (final l in lessons.values) {
    testWidgets('${l.id} ${l.title}: every card shows, and the end leads to practice', (tester) async {
      final (container, speech, sfx) = await open(tester, l.id);
      final answers = {for (final b in l.blocks.whereType<TryBlock>()) for (final q in b.questions) q.answer};

      for (var guard = 0; find.text('▶️ تدرّب لوحدك').evaluate().isEmpty; guard++) {
        expect(guard, lessThan(60), reason: 'stuck on a card');
        if (goButton(tester)?.onTap == null) {
          // «جرّب معايا»: الزرار مقفول لحد الإجابة الصح
          final shown = [
            for (final w in tester.widgetList<Pressable3D>(find.byType(Pressable3D)))
              if (answers.contains(w.semanticLabel)) w.semanticLabel!,
          ];
          for (final label in shown) {
            await tap(tester, find.byWidgetPredicate((w) => w is Pressable3D && w.semanticLabel == label).first);
            if (goButton(tester)?.onTap != null) break;
          }
          expect(goButton(tester)?.onTap, isNotNull, reason: 'no choice solved the question');
        }
        await tap(tester, find.byWidget(goButton(tester)!));
      }

      expect(container.read(progressProvider).explained, contains(l.id));
      expect(speech.said, isNotEmpty);
      expect(sfx.played, contains(SfxKind.good));
      await tap(tester, find.text('▶️ تدرّب لوحدك'));
      expect(find.text('play ${l.id}'), findsOneWidget);
    });
  }

  testWidgets('a wrong choice says try again and keeps the question', (tester) async {
    final l = lessons['school:p1-t1-math:u1:l1']!;
    final (_, speech, sfx) = await open(tester, l.id);
    for (var guard = 0; find.textContaining('جرّب معايا').evaluate().isEmpty; guard++) {
      expect(guard, lessThan(20));
      await tap(tester, find.byWidget(goButton(tester)!));
    }
    final q = l.blocks.whereType<TryBlock>().first.questions.first;
    final wrong = q.choices.firstWhere((c) => c != q.answer);
    await tap(tester, find.byWidgetPredicate((w) => w is Pressable3D && w.semanticLabel == wrong));
    expect(sfx.played, [SfxKind.bad]);
    expect(find.text('مش ده — فكّر تاني 🤔'), findsOneWidget);
    expect(goButton(tester)!.onTap, isNull);
    await tap(tester, find.byWidgetPredicate((w) => w is Pressable3D && w.semanticLabel == q.answer));
    expect(speech.said.last, q.why);
    expect(goButton(tester)!.onTap, isNotNull);
  });

  testWidgets('a lesson with no explanation offers practice', (tester) async {
    await open(tester, 'school:p1-t1-math:u2:l1');
    expect(find.text('الدرس ده لسه مالوش شرح'), findsOneWidget);
    expect(find.text('▶️ ذاكر الدرس'), findsOneWidget);
  });
}

/// الشاشة بتتسكرول — الزرار ممكن يكون تحت.
Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(tester.takeException()?.toString(), isNull);
}
