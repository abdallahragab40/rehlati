import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/school.dart';
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
    expect(ProgressData(age: 12).level('math'), 3);
  });

  test('ages run from 3 to 12 and the usual grade follows the Egyptian school ages', () {
    expect(kidAges, [for (var a = 3; a <= 12; a++) a]);
    expect([for (final a in kidAges) usualGrade(a)], ['pre', 'kg1', 'kg2', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p6']);
    expect(usualGrade(null), isNull);
    expect([yearsWord(10), yearsWord(11)], ['سنين', 'سنة']);
    for (final g in schoolGrades) {
      expect(gradeName(g), isNot(g), reason: 'every grade has an Arabic name');
    }
  });

  group('primary groups open by school grade', () {
    const firsts = ['madd_alif', 'ar_haraka', 'tensOnes', 'moneyCount', 'mulGroups'];
    List<String> open(ProgressData p) => [for (final id in firsts) if (p.isUnlocked(id)) id];

    test('the usual grade for the age opens the first stage of each group up to that grade', () {
      expect(open(ProgressData(age: 5)), isEmpty, reason: 'KG2 keeps the old order');
      expect(open(ProgressData(age: 6)), ['madd_alif', 'ar_haraka']);
      expect(open(ProgressData(age: 7)), ['madd_alif', 'ar_haraka', 'tensOnes', 'moneyCount']);
      expect(open(ProgressData(age: 8)), firsts);
      expect(open(ProgressData(age: 12)), firsts);
      expect(open(ProgressData()), isEmpty, reason: 'no age yet, nothing opens early');
    });

    test('a grade the parent picks wins over the age', () {
      expect(open(ProgressData(age: 8, grade: 'kg2')), isEmpty);
      expect(open(ProgressData(age: 5, grade: 'p3')), firsts);
      expect(ProgressData(age: 8, grade: 'p1').schoolGrade, 'p1');
    });

    test('only the first stage of a group opens early; the rest still open one by one', () {
      final p = ProgressData(age: 8);
      expect([p.isUnlocked('times2510'), p.isUnlocked('skipCount'), p.isUnlocked('ar_haraka_pick')], [false, false, false]);
      expect(p.unlockNext('mulGroups')?.id, 'times2510');
      expect(p.isUnlocked('times2510'), isTrue);
    });

    test('older children start primary stages at a level that fits them', () {
      expect(ProgressData(age: 8).level('math'), 3);
    });
  });

  test('the school grade is kept apart from age, survives JSON and ignores unknown values', () {
    final p = ProgressData(age: 7, grade: 'p3');
    final back = ProgressData.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect([back.age, back.grade], [7, 'p3']);
    expect(ProgressData.fromJson({'grade': 'p9'}).grade, isNull);
    expect(ProgressData.fromJson({'grade': 3}).grade, isNull);
    expect(ProgressData().toJson().containsKey('grade'), isFalse, reason: 'old payloads stay unchanged');
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
