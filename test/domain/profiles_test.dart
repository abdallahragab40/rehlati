import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/school.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the grade sets the lowest question level', () {
    expect(ProgressData().level('math'), 1);
    expect(ProgressData(grade: 'kg1').level('math'), 1);
    expect(ProgressData(grade: 'kg2').level('math'), 2);
    expect(ProgressData(grade: 'p1').level('math'), 3);
    expect(ProgressData(grade: 'p6').level('math'), 3);
  });

  test('grades run from KG1 to sixth primary, each with a name and a usual age', () {
    expect(schoolGrades, ['kg1', 'kg2', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6']);
    expect([for (final g in schoolGrades) gradeAge(g)], [4, 5, 6, 7, 8, 9, 10, 11]);
    expect(gradeAge(null), isNull);
    expect([for (final g in schoolGrades) gradeShort(g)], ['KG1', 'KG2', 'أولى', 'تانية', 'تالتة', 'رابعة', 'خامسة', 'سادسة']);
    expect(gradeRange('p4', 'p6'), 'رابعة – سادسة');
    for (final g in schoolGrades) {
      expect(gradeName(g), isNot(g), reason: 'every grade has an Arabic name');
    }
  });

  group('primary groups open by school grade', () {
    const firsts = ['madd_alif', 'ar_haraka', 'tensOnes', 'moneyCount', 'mulGroups'];
    List<String> open(ProgressData p) => [for (final id in firsts) if (p.isUnlocked(id)) id];

    test('the grade opens the first stage of each group up to that grade', () {
      expect(open(ProgressData(grade: 'kg1')), isEmpty);
      expect(open(ProgressData(grade: 'kg2')), isEmpty, reason: 'KG2 keeps the old order');
      expect(open(ProgressData(grade: 'p1')), ['madd_alif', 'ar_haraka']);
      expect(open(ProgressData(grade: 'p2')), ['madd_alif', 'ar_haraka', 'tensOnes', 'moneyCount']);
      expect(open(ProgressData(grade: 'p3')), firsts);
      expect(open(ProgressData(grade: 'p6')), firsts);
      expect(open(ProgressData()), isEmpty, reason: 'no grade yet, nothing opens early');
    });

    test('each school-book group opens from its own grade', () {
      const books = {'thousands': 'p3', 'en_possessive': 'p3', 'roundLarge': 'p4', 'ar_nounSigns': 'p4', 'en_present': 'p4',
          'decimals5': 'p5', 'ar_mafool': 'p5', 'en_frequency': 'p5', 'divisibility': 'p6', 'ar_nakira': 'p6', 'en_ableTo': 'p6'};
      for (final MapEntry(key: id, value: g) in books.entries) {
        final i = schoolGrades.indexOf(g);
        expect(ProgressData(grade: g).isUnlocked(id), isTrue, reason: '$id at $g');
        expect(ProgressData(grade: schoolGrades[i - 1]).isUnlocked(id), isFalse, reason: '$id below $g');
      }
    });

    test('only the first stage of a group opens early; the rest still open one by one', () {
      final p = ProgressData(grade: 'p3');
      expect([p.isUnlocked('times2510'), p.isUnlocked('skipCount'), p.isUnlocked('ar_haraka_pick')], [false, false, false]);
      expect(p.unlockNext('mulGroups')?.id, 'times2510');
      expect(p.isUnlocked('times2510'), isTrue);
    });
  });

  test('the grade survives JSON; old progress gets its grade from the saved age', () {
    final back = ProgressData.fromJson(jsonDecode(jsonEncode(ProgressData(grade: 'p3').toJson())) as Map<String, dynamic>);
    expect([back.grade, back.age], ['p3', 8]);
    expect(ProgressData(grade: 'p3').toJson().containsKey('age'), isFalse, reason: 'the age is not asked or saved any more');
    expect(ProgressData.fromJson({'grade': 'p9'}).grade, isNull);
    expect(ProgressData.fromJson({'grade': 3}).grade, isNull);
    expect(ProgressData().toJson().containsKey('grade'), isFalse);
    // قبل كده: السن من شاشة البداية، والصف اختياري من لوحة ولي الأمر (وكان فيه "قبل المدرسة")
    expect([for (final a in [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) ProgressData.fromJson({'age': a}).grade],
        ['kg1', 'kg1', 'kg2', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p6']);
    expect(ProgressData.fromJson({'age': 8, 'grade': 'p1'}).grade, 'p1', reason: 'the parent\'s grade wins over the old age');
    expect(ProgressData.fromJson({'age': 3, 'grade': 'pre'}).grade, 'kg1');
  });

  test('the profile needs a name and a grade before the home screen opens', () {
    expect(ProgressData(name: 'سارة', grade: 'p1', setupDone: true).profileReady, isTrue);
    expect(ProgressData(name: 'سارة', setupDone: true).profileReady, isFalse);
    expect(ProgressData(name: '  ', grade: 'p1', setupDone: true).profileReady, isFalse);
    expect(ProgressData(name: 'سارة', grade: 'p1').profileReady, isFalse);
  });

  test('old progress skips the intro, new progress shows it', () {
    expect(ProgressData.fromJson({'games': 3}).setupDone, isTrue);
    expect(ProgressData.fromJson({}).setupDone, isFalse);
    expect(ProgressData.fromJson(ProgressData(setupDone: true).toJson()).setupDone, isTrue);
  });

  test('settings round-trip and old settings get defaults', () {
    final s = Settings.fromJson((Settings(speechRate: .8, enSpeechRate: .7, westernDigits: true).toJson()));
    expect([s.speechRate, s.enSpeechRate, s.westernDigits], [.8, .7, true]);
    final old = Settings.fromJson({'speech': true});
    expect([old.speechRate, old.enSpeechRate, old.westernDigits], [1.0, .85, false]);
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
