import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/sfx_service.dart';
import 'package:rehlati/core/widgets/kid_widgets.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/school_lessons.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/game/play_modes.dart' show TraceBoard;
import 'package:rehlati/features/school/lesson_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;
import '../domain/lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles()) l.id: l};

  /// الشرح على موبايل صغير (٣٦٠ نقطة) وخط النظام ١.٣، وبعده «تدرّب لوحدك» بيروح للجولة.
  Future<(ProviderContainer, FakeSpeech, FakeSfx)> open(WidgetTester tester, String id, {Map<String, Object>? prefs}) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (prefs != null) SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final speech = FakeSpeech(), sfx = FakeSfx();
    final router = GoRouter(initialLocation: '/lesson/$id', routes: [
      GoRoute(path: '/lesson/:id', builder: (_, s) => LessonScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/play/:stage', builder: (_, s) => Text('play ${s.pathParameters['stage']}')),
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(path: '/school', builder: (_, _) => const Text('school')),
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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  KidButton? goButton(WidgetTester tester) => tester
      .widgetList<KidButton>(find.byType(KidButton))
      .where((b) => b.kind == BtnKind.go)
      .firstOrNull;

  /// البطاقة والنشاط اللي ظاهرين — من مفتاح الكارت (`صفحة:نشاط`).
  (int, int) where(WidgetTester tester) {
    final key = tester.widget<QCard>(find.byType(QCard)).key! as ValueKey<String>;
    final [page, q] = key.value.split(':').map(int.parse).toList();
    return (page, q);
  }

  /// زرار شغّال بالنص ده — [last] للعمود التاني في «وصّل».
  Finder chip(String label, {bool last = false}) {
    final f = find.byWidgetPredicate((w) => w is Pressable3D && w.semanticLabel == label && w.onTap != null);
    return last ? f.last : f.first;
  }

  Future<void> solve(WidgetTester tester, LessonTask t) async {
    switch (t.kind) {
      case TaskKind.choice:
        await tap(tester, chip(t.answer));
      case TaskKind.pick:
        for (final a in t.answers) {
          await tap(tester, chip(a));
        }
      case TaskKind.order:
        for (final it in t.items) {
          await tap(tester, chip(it));
        }
      case TaskKind.match:
        for (final (a, b) in t.pairs) {
          await tap(tester, chip(a));
          await tap(tester, chip(b, last: true));
        }
      case TaskKind.sort:
        final all = [for (final g in t.groups) ...g.$2];
        for (var i = 0; i < all.length; i++) {
          final shown = tester
              .widgetList<Pressable3D>(find.byType(Pressable3D))
              .map((w) => w.semanticLabel)
              .firstWhere((l) => all.contains(l))!;
          await tap(tester, chip(t.groups.firstWhere((g) => g.$2.contains(shown)).$1));
        }
      case TaskKind.trace:
        // القناع بيتحسب من صورة — محتاج وقت حقيقي، وبعدين شخبطة فوق اللوحة كلها
        await tester.ensureVisible(find.byType(TraceBoard));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump();
        final board = tester.getRect(find.byType(TraceBoard));
        final g = await tester.startGesture(board.topLeft + Offset(board.width * .2, board.height * .1));
        for (var y = .1; y <= .9; y += .03) {
          for (var x = .2; x <= .8; x += .05) {
            await g.moveTo(board.topLeft + Offset(board.width * x, board.height * y));
          }
        }
        await g.up();
        await settle(tester);
      case TaskKind.line:
        final mark = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == t.answer).first;
        await tap(tester, mark);
    }
  }

  /// يمشي الدرس لحد البطاقة [until] (أو لآخره)، ويحل كل نشاط صح من أول مرة.
  Future<void> walk(WidgetTester tester, LessonContent l, {int? until}) async {
    bool more() => until != null
        ? where(tester).$1 < until
        : find.text('▶️ تدرّب لوحدك').evaluate().isEmpty && find.text('✅ خلّصت — ارجع للدروس').evaluate().isEmpty;
    for (var guard = 0; more(); guard++) {
      expect(guard, lessThan(80), reason: 'stuck on a card');
      if (goButton(tester)?.onTap == null) {
        final (page, q) = where(tester);
        if (l.blocks[page] is ReadBlock) {
          // اقرا وبعدين اسمع: الجاي بيفتح بعد السمع
          await tap(tester, find.text('🔊 اسمعها واتأكد'));
        } else {
          await solve(tester, (l.blocks[page] as TryBlock).tasks[q]);
        }
        expect(goButton(tester)?.onTap, isNotNull, reason: '${l.id} card $page task $q was not solved');
      }
      await tap(tester, find.byWidget(goButton(tester)!));
    }
  }

  for (final l in lessons.values) {
    testWidgets('${l.id} ${l.title}: every card and task works, and the end leads to practice', (tester) async {
      final (container, speech, sfx) = await open(tester, l.id);
      await walk(tester, l);

      final log = container.read(progressProvider).lessonLogs[l.uid]!;
      expect((log.done, log.mistakes), (true, 0));
      expect(lessonStatus(container.read(progressProvider), l), LessonStatus.mastered);
      expect(speech.said, isNotEmpty);
      expect(sfx.played, isNot(contains(SfxKind.bad)));
      await tap(tester, find.text(schoolRound(l.id) != null ? '▶️ تدرّب لوحدك' : '✅ خلّصت — ارجع للدروس'));
      // درس شرح بس (استماع، نشيد، قراءة) بيرجع لدروس المدرسة
      if (schoolRound(l.id) != null) expect(find.text('play ${l.id}'), findsOneWidget);
    });
  }

  testWidgets('«رتّب» starts mixed up, and a wrong letter does not count', (tester) async {
    final l = lessons['school:p1-t1-arabic:u1:l2']!;
    final page = l.blocks.indexWhere((b) => b is TryBlock && b.tasks.any((t) => t.kind == TaskKind.order));
    final (_, _, sfx) = await open(tester, l.id);
    await walk(tester, l, until: page);
    final tasks = (l.blocks[page] as TryBlock).tasks;
    await solve(tester, tasks.first);
    await tap(tester, find.byWidget(goButton(tester)!));
    final t = tasks[1];
    expect(t.kind, TaskKind.order);
    final shown = [
      for (final w in tester.widgetList<Pressable3D>(find.byType(Pressable3D)))
        if (t.items.contains(w.semanticLabel) && w.onTap != null) w.semanticLabel!,
    ];
    expect(shown, unorderedEquals(t.items));
    expect(shown, isNot(t.items), reason: 'the letters must not start in the right order');
    // أول حرف غلط: «ا» مكانها مش الأول
    await tap(tester, chip(t.items.firstWhere((i) => i != t.items.first)));
    expect(sfx.played.last, SfxKind.bad);
    expect(goButton(tester)!.onTap, isNull);
  });

  testWidgets('«رتّب» and «صنّف» also work by dragging', (tester) async {
    Future<void> dragTo(Finder from, Finder to) async {
      await tester.ensureVisible(from);
      await tester.pump();
      final g = await tester.startGesture(tester.getCenter(from));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(tester.getCenter(from), tester.getCenter(to), i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle(tester);
    }

    // رتّب «باب»: نسحب كل حرف لخانة الإجابة
    var l = lessons['school:p1-t1-arabic:u1:l2']!;
    var page = l.blocks.indexWhere((b) => b is TryBlock && b.tasks.any((t) => t.kind == TaskKind.order));
    await open(tester, l.id);
    await walk(tester, l, until: page);
    await solve(tester, (l.blocks[page] as TryBlock).tasks.first);
    await tap(tester, find.byWidget(goButton(tester)!));
    final word = (l.blocks[page] as TryBlock).tasks[1];
    for (final it in word.items) {
      await dragTo(chip(it), find.text('؟').first);
    }
    expect(goButton(tester)!.onTap, isNotNull, reason: 'the word was built by dragging');

    // صنّف «أكبر من ٥ / أصغر من ٥»: نسحب الرقم للمجموعة
    await tester.pumpWidget(const SizedBox());
    l = lessons['school:p1-t1-math:u1:l10']!;
    page = l.blocks.indexWhere((b) => b is TryBlock && b.tasks.any((t) => t.kind == TaskKind.sort));
    await open(tester, l.id);
    await walk(tester, l, until: page);
    final t = (l.blocks[page] as TryBlock).tasks.single;
    final all = [for (final g in t.groups) ...g.$2];
    for (var i = 0; i < all.length; i++) {
      final shown = tester.widgetList<Pressable3D>(find.byType(Pressable3D)).map((w) => w.semanticLabel).firstWhere(all.contains)!;
      final group = t.groups.firstWhere((g) => g.$2.contains(shown)).$1;
      await dragTo(find.byWidgetPredicate((w) => w is Pressable3D && w.semanticLabel == shown).first, chip(group));
    }
    expect(goButton(tester)!.onTap, isNotNull, reason: 'sorted by dragging');
  });

  testWidgets('a mistake gets its own hint, a second one a simpler example, and the parent sees it needs review',
      (tester) async {
    final l = lessons['school:p1-t1-math:u1:l1']!;
    final (container, speech, sfx) = await open(tester, l.id);
    final checkPage = l.blocks.indexWhere((b) => b is TryBlock && b.check);
    await walk(tester, l, until: checkPage);
    final t = (l.blocks[checkPage] as TryBlock).tasks.first;
    final [w1, w2] = t.choices.where((c) => c != t.answer).toList();

    await tap(tester, chip(w1));
    expect(sfx.played.last, SfxKind.bad);
    expect(find.text('🤔 ${t.hintFor(w1)}'), findsOneWidget);
    expect(speech.said.last, t.hintFor(w1));
    expect(find.text('💡 خلّينا نشوف مثال أسهل'), findsNothing);
    expect(goButton(tester)!.onTap, isNull);

    await tap(tester, chip(w2));
    expect(find.text('🤔 ${t.hintFor(w2)}'), findsOneWidget);
    expect(find.text('💡 خلّينا نشوف مثال أسهل'), findsOneWidget);

    await tap(tester, chip(t.answer));
    expect(speech.said.last, t.why);
    expect(goButton(tester)!.onTap, isNotNull);

    await walk(tester, l);
    final p = container.read(progressProvider);
    expect(p.lessonLogs[l.uid]!.mistakes, 2);
    expect(lessonStatus(p, l), LessonStatus.helped);
    expect(find.textContaining('هنرجع للدرس ده تاني'), findsOneWidget);
  });

  testWidgets('reopening a lesson that needs review keeps it there until the child finishes it again', (tester) async {
    final l = lessons['school:p1-t1-math:u1:l10']!;
    var (container, _, _) = await open(tester, l.id);
    final checkPage = l.blocks.indexWhere((b) => b is TryBlock && b.check);
    await walk(tester, l, until: checkPage);
    final t = (l.blocks[checkPage] as TryBlock).tasks.first;
    await tap(tester, chip(t.choices.firstWhere((c) => c != t.answer)));
    await walk(tester, l);
    expect(lessonStatus(container.read(progressProvider), l), LessonStatus.helped);

    final saved = container.read(sharedPrefsProvider);
    final prefs = {for (final k in saved.getKeys()) k: saved.get(k)!};
    await tester.pumpWidget(const SizedBox());
    (container, _, _) = await open(tester, l.id, prefs: prefs);
    expect(where(tester).$1, 0);
    expect(lessonStatus(container.read(progressProvider), l), LessonStatus.helped);

    await walk(tester, l);
    expect(container.read(progressProvider).lessonLogs[l.uid]!.mistakes, 0);
    expect(lessonStatus(container.read(progressProvider), l), LessonStatus.mastered);
  });

  testWidgets('the lesson goes on from the card where the child stopped', (tester) async {
    final l = lessons['school:p1-t1-arabic:u1:l2']!;
    final (container, _, _) = await open(tester, l.id);
    await walk(tester, l, until: 2);
    expect(container.read(progressProvider).lessonLogs[l.uid]!.page, 2);
    expect(lessonStatus(container.read(progressProvider), l), LessonStatus.started);

    final saved = container.read(sharedPrefsProvider);
    final prefs = {for (final k in saved.getKeys()) k: saved.get(k)!};
    await tester.pumpWidget(const SizedBox());
    await open(tester, l.id, prefs: prefs);
    expect(where(tester).$1, 2);
    expect(find.text('👋 كمّلنا من آخر مكان وقفت فيه'), findsOneWidget);
  });

  testWidgets('the parent marks the home activity as done', (tester) async {
    final l = lessons['school:p1-t1-english:u1:l1']!;
    final (container, _, _) = await open(tester, l.id);
    await walk(tester, l, until: l.blocks.indexWhere((b) => b is ActivityBlock));
    await tap(tester, find.text('✅ عملنا النشاط'));
    expect(container.read(progressProvider).lessonLogs[l.uid]!.activity, isTrue);
    expect(find.text('✅ عملتوا النشاط — برافو!'), findsOneWidget);
  });

  testWidgets('a lesson with no explanation offers practice', (tester) async {
    await open(tester, 'school:p1-t2-math:u1:l1');
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
