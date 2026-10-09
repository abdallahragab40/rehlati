import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// التطبيق الحقيقي على جهاز: لوحة الحروف بتتعد في وقت التعلّم، ولما الحد يخلص
/// الشاشة بتروح لـ "وقت الراحة" حتى لو الطفل لسه جوه النشاط.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the letter board counts toward the limit and stops when it runs out', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    // تقدّم اللي على الجهاز يرجع زي ما كان بعد الاختبار
    const keys = [ProgressRepository.key, ProgressRepository.profilesKey];
    final saved = {for (final k in keys) k: prefs.getString(k)};
    addTearDown(() async {
      for (final MapEntry(:key, :value) in saved.entries) {
        value == null ? await prefs.remove(key) : await prefs.setString(key, value);
      }
    });
    await prefs.remove(ProgressRepository.profilesKey);
    final seeded = ProgressData(name: 'تجربة', age: 5, setupDone: true, settings: Settings(limitMin: 1, speech: false, music: false, sfx: false))
      ..addTime(30000);
    await prefs.setString(ProgressRepository.key, jsonEncode(seeded.toJson()));

    Future<void> settle([int frames = 15]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    /// بيستنى لحد ما الزرار يظهر (أول تشغيل بعد البناء بياخد وقت) وبعدين يدوس عليه.
    Future<void> tapWhenReady(String text) async {
      final f = find.text(text).first;
      for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.ensureVisible(f);
      await settle(5);
      await tester.tap(f);
      await settle();
    }

    await app.main();
    await settle(20);
    await tapWhenReady('العربي');
    await tapWhenReady('تعرّف على الحروف');
    expect(find.text('خلاص يا بطل، بكرة نكمّل!'), findsNothing, reason: '30 seconds were still left');

    // ٣٠ ثانية فاضلة + tick كل ٣٠ ثانية
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settle();
    expect(find.text('خلاص يا بطل، بكرة نكمّل!'), findsOneWidget);

    final stored = ProgressData.fromJson((jsonDecode(prefs.getString(ProgressRepository.key)!) as Map).cast());
    debugPrint('TIME today=${stored.todayMs}ms');
    expect(stored.todayMs, greaterThanOrEqualTo(60000));
  });
}
