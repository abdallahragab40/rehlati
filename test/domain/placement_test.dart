import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/placement.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show correctIndex, makeContainer, wrongIndex;

/// اختبار تحديد المستوى: الدرجات، الحساب، وتطبيق النتيجة.
void main() {
  test('every ladder has 5 rungs of 2 questions, from real stages of its own world', () {
    for (final MapEntry(key: world, value: ladder) in placementLadders.entries) {
      expect(ladder.length, 5, reason: world);
      for (final rung in ladder) {
        expect(rung.questions.length, 2);
        for (final (id, lv) in rung.questions) {
          final s = packs[id]!;
          expect([s.world, s.isMadd, s.isLearn], [world, false, false], reason: id);
          expect(lv, inInclusiveRange(1, 4));
        }
        expect(rung.opens.every((id) => packs[id]?.world == world), isTrue, reason: rung.label);
        expect(rung.level, inInclusiveRange(1, 3));
      }
    }
  });

  test('placement stages are playable but never on a map or in the journey', () {
    final onMaps = {for (final list in worldStages.values) ...list.map((s) => s.id)};
    for (final s in placementStages) {
      expect(packs[s.id], same(s));
      expect(onMaps, isNot(contains(s.id)));
      expect(isPlacement(s.id), isTrue);
    }
    final r = Rng.seeded(81);
    expect(placementRound('math', r).length, 10);
  });

  test('a rung counts only when both answers are right first time, and the climb stops at the first miss', () {
    expect(placementReached([false, false, true, true, true, true, true, true, true, true]), -1);
    expect(placementReached([true, false, true, true, true, true, true, true, true, true]), -1, reason: 'one guess is not enough');
    expect(placementReached([true, true, true, true, false, true, true, true, true, true]), 1);
    expect(placementReached(List.filled(10, true)), 4);
  });

  test('applying a result opens the passed rungs and sets the subject level, without locking anything', () {
    final p = ProgressData(unlocked: ['counting', 'ar_learn', 'en_learn', 'sequence']);
    final top = applyPlacement(p, 'math', 2);
    expect(top?.id, 'tensOnes');
    expect(p.unlocked, containsAll(['chooseNumber', 'addition', 'subtraction', 'tensOnes', 'add100', 'sequence']));
    expect(p.unlocked.contains('times2510'), isFalse);
    expect(p.settings.worldLevel, {'math': 3});
    expect(placementLabel('math', 2), 'تانية ابتدائي');

    final none = ProgressData();
    expect(applyPlacement(none, 'english', -1), isNull);
    expect(none.settings.worldLevel, {'english': 1});
    expect(placementLabel('english', -1), 'لسه بيبدأ');
  });

  test('a real round: two perfect rungs then a miss places the child at first primary', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('place_math');
    expect(c.read(gameProvider)!.total, 10);
    for (var i = 0; i < 10; i++) {
      final q = c.read(gameProvider)!.q;
      if (i == 4) engine.answer(wrongIndex(q));
      engine.answer(correctIndex(c.read(gameProvider)!.q));
      await Future<void>.delayed(const Duration(milliseconds: 1450));
    }
    final result = c.read(gameProvider)!.result!;
    expect(result.placed, 'أولى ابتدائي');
    expect(result.unlocked?.id, 'addition');
    final p = c.read(progressProvider);
    expect(p.settings.worldLevel['math'], 2);
    expect(p.isUnlocked('subtraction'), isTrue);
    expect(p.best.containsKey('place_math'), isFalse, reason: 'no medals for the check itself');
  }, timeout: const Timeout(Duration(seconds: 40)));
}
