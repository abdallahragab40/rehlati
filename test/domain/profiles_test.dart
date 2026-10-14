import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('age sets the lowest question level', () {
    expect(ProgressData().level('math'), 1);
    expect(ProgressData(age: 5).level('math'), 2);
    expect(ProgressData(age: 6).level('math'), 3);
  });

  test('ages outside 4–6 start at the nearest level', () {
    expect(ProgressData(age: 3).level('math'), 1);
    expect(ProgressData(age: 7).level('math'), 3);
    expect(ProgressData(age: 8).level('math'), 3);
  });

  test('old progress skips the setup screen, new progress shows it', () {
    expect(ProgressData.fromJson({'games': 3}).setupDone, isTrue);
    expect(ProgressData.fromJson({}).setupDone, isFalse);
    expect(ProgressData.fromJson(ProgressData(setupDone: true).toJson()).setupDone, isTrue);
  });

  test('settings round-trip and old settings get defaults', () {
    final s = Settings.fromJson((Settings(speechRate: .8, westernDigits: true).toJson()));
    expect([s.speechRate, s.westernDigits], [.8, true]);
    final old = Settings.fromJson({'speech': true});
    expect([old.speechRate, old.westernDigits], [1.0, false]);
  });

  test('siblings keep separate progress and the first child keeps the old key', () async {
    SharedPreferences.setMockInitialValues({ProgressRepository.key: jsonEncode({'name': 'يوسف', 'stars': 9})});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final n = c.read(progressProvider.notifier);
    expect(c.read(progressProvider).name, 'يوسف');

    await n.addChild();
    expect(c.read(progressProvider).stars, 0);
    n.update((p) => p..name = 'مريم'..stars = 2);
    final second = c.read(activeChildProvider);
    expect(second, isNot(ProgressRepository.mainId));

    await n.switchTo(ProgressRepository.mainId);
    expect(c.read(progressProvider).name, 'يوسف');
    expect(c.read(progressProvider).stars, 9);

    await n.removeChild(second);
    expect(c.read(progressRepositoryProvider).ids, [ProgressRepository.mainId]);
    expect(prefs.getString(ProgressRepository.keyFor(second)), isNull);
  });
}
