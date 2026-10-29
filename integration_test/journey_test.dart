import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// رحلة كاملة على جهاز: أول تشغيل → الترحيب → البداية → جولة → إعادة فتح → طفل تاني → تبديل → ولي الأمر.
/// الإجابات بتتبعت للمحرك مباشرة (نفس اختبارات المحرك)، والتنقل كله بلمس حقيقي.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fresh install to sibling management', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    // كل اللي على الجهاز يرجع زي ما كان بعد الاختبار
    final saved = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    addTearDown(() async {
      await prefs.clear();
      for (final MapEntry(:key, :value) in saved.entries) {
        switch (value) {
          case String v: await prefs.setString(key, v);
          case bool v: await prefs.setBool(key, v);
          case int v: await prefs.setInt(key, v);
          case double v: await prefs.setDouble(key, v);
          case List<Object?> v: await prefs.setStringList(key, v.cast<String>());
        }
      }
    });
    await prefs.clear();

    Future<void> settle([int frames = 12]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> tapWhenReady(Finder f) async {
      for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.ensureVisible(f.first);
      await settle(4);
      await tester.tap(f.first);
      await settle();
    }

    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    Future<void> setup(String name, String age) async {
      await tapWhenReady(find.byType(TextField));
      await tester.enterText(find.byType(TextField), name);
      await settle(3);
      await tapWhenReady(find.text(age));
      await tapWhenReady(find.text('🚀 يلا نبدأ'));
      expect(container().read(progressProvider).name, name);
    }

    Future<void> openParent() async {
      await tapWhenReady(find.text('⚙️'));
      final row = find.ancestor(of: find.text('👨‍👩‍👦 لوحة ولي الأمر'), matching: find.byType(Row));
      await tapWhenReady(find.descendant(of: row, matching: find.text('افتح')));
      final q = tester.widget<Text>(find.textContaining('كام')).data!;
      final latin = q.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
      final n = RegExp(r'\d+').allMatches(latin).map((m) => int.parse(m[0]!)).toList();
      await tester.enterText(find.byType(TextField), '${n[0] * n[1]}');
      await tapWhenReady(find.text('دخول'));
      expect(find.text('👨‍👩‍👦 لوحة ولي الأمر'), findsOneWidget);
    }

    // ١) أول تشغيل: الترحيب (مرة واحدة) ثم شاشة البداية
    await app.main();
    await settle(20);
    await tapWhenReady(find.text('التالي'));
    await tapWhenReady(find.text('التالي'));
    await tapWhenReady(find.text('🎒 يلا نبدأ الرحلة'));
    await setup('سارة', '٤');

    // ٢) جولة كاملة في العد
    await tapWhenReady(find.text('الحساب'));
    await tapWhenReady(find.text('العد'));
    final c = container();
    for (var i = 0; i < 10; i++) {
      for (var t = 0; t < 30 && (c.read(gameProvider)?.idx != i || c.read(gameProvider)!.locked); t++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      final s = c.read(gameProvider)!;
      c.read(gameProvider.notifier).answer(s.q.choices.indexOf(s.q.answer!));
      await settle(8);
    }
    await settle();
    expect(c.read(gameProvider)!.result, isNotNull);
    final stars = c.read(progressProvider).stars;
    expect(stars, greaterThanOrEqualTo(10));
    expect(c.read(progressProvider).isUnlocked('chooseNumber'), isTrue);
    await tapWhenReady(find.text('🗺️ الخريطة'));
    await tapWhenReady(find.text('↩'));

    // ٣) إعادة الفتح: نقرا من تخزين الجهاز نفسه، مش من الذاكرة
    await c.read(progressProvider.notifier).flush();
    await prefs.reload();
    await app.main();
    await settle(20);
    expect(container().read(progressProvider).name, 'سارة');
    expect(container().read(progressProvider).stars, stars);
    expect(container().read(progressProvider).isUnlocked('chooseNumber'), isTrue);

    // ٤) رحلة النهاردة: بتتخطط من التقدّم، وأول خطوة بتفتح نشاط حقيقي
    await tapWhenReady(find.textContaining('🧭 رحلة النهاردة'));
    final journey = container().read(progressProvider).todayJourney!;
    expect(journey.steps, isNotEmpty);
    expect(find.text('▶️ يلا'), findsOneWidget);
    await tapWhenReady(find.text('▶️ يلا'));
    expect(find.textContaining('🧭 رحلة النهاردة'), findsNothing, reason: 'the first step opened');
    await tapWhenReady(find.text('↩'));
    await tapWhenReady(find.text('🏠 الرئيسية'));
    debugPrint('JOURNEY steps=${[for (final s in journey.steps) s.target]}');

    // ٥) طفل تاني من لوحة ولي الأمر
    await openParent();
    // مكتبة القرآن بتتمسح من فولدر الجهاز الحقيقي وبتعرض الأجزاء للقارئ المختار
    final juzRow = find.textContaining('التلاوة:');
    for (var i = 0; i < 50 && juzRow.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(juzRow, findsNWidgets(3));
    expect(find.text('📤 صدّر نسخة'), findsOneWidget);
    await tapWhenReady(find.text('➕ إضافة طفل'));
    await setup('عمر', '٦');
    expect(container().read(progressProvider).stars, 0);

    // ٦) التبديل من صورة الطفل في الرئيسية
    await tapWhenReady(find.text('🔄'));
    await tapWhenReady(find.text('سارة'));
    expect(container().read(progressProvider).name, 'سارة');
    expect(container().read(progressProvider).stars, stars);

    // ٧) ولي الأمر يمسح الطفل التاني — سارة ماتتأثرش
    await openParent();
    final omar = find.ancestor(of: find.textContaining('عمر •'), matching: find.byType(Row));
    await tapWhenReady(find.descendant(of: omar, matching: find.byType(IconButton)));
    await tapWhenReady(find.widgetWithText(TextButton, 'امسح'));
    final repo = container().read(progressRepositoryProvider);
    expect(repo.ids, [ProgressRepository.mainId]);
    expect(container().read(progressProvider).stars, stars);
    await prefs.reload();
    expect(prefs.getKeys().where((k) => k.startsWith('${ProgressRepository.key}.')), isEmpty);
    debugPrint('JOURNEY ok stars=$stars');
  });
}
