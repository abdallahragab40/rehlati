import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/sfx_service.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show FakeSfx, makeContainer;

/// عالم الألعاب: مفتوح كله، والتلوين والإيقاع شغالين في المحرك.
void main() {
  test('every game is open from the start and never "unlocks" anything', () async {
    final c = await makeContainer();
    final p = c.read(progressProvider);
    for (final s in worldStages['games']!) {
      expect(p.isUnlocked(s.id), isTrue, reason: s.id);
    }
    expect(p.unlockNext('balloons'), isNull);
  });

  test('colour by numbers: pick a colour, paint matching cells, a wrong cell is a gentle mistake', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('colorNum');
    final s = c.read(gameProvider)!;
    final q = s.q;
    expect(s.total, 1);

    engine.colorPaint(0); // من غير لون — مفيش حاجة تحصل
    expect(s.painted, isEmpty);

    final first = q.paintCells.first;
    engine.colorSelect(first);
    final wrong = q.paintCells.indexWhere((n) => n != first);
    engine.colorPaint(wrong);
    expect(s.painted, isEmpty);
    expect(s.tries, 1);

    for (final pot in q.pots) {
      engine.colorSelect(pot.n);
      for (var i = 0; i < q.paintCells.length; i++) {
        if (q.paintCells[i] == pot.n) engine.colorPaint(i);
      }
    }
    expect(s.painted.length, q.paintCells.length);
    expect(s.locked, isTrue);
  });

  test('rhythm: plays the beats, then the child repeats them; a wrong pad replays', () async {
    final c = await makeContainer();
    final sfx = c.read(sfxProvider) as FakeSfx;
    final engine = c.read(gameProvider.notifier)..start('rhythm');
    final s = c.read(gameProvider)!;
    final q = s.q;

    // قبل ما الإيقاع يخلص ممنوع الضغط
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(s.rhythmLock, isTrue);
    engine.rhythmTap(q.beats.first);
    expect(s.picked, isEmpty);

    await Future<void>.delayed(Duration(milliseconds: 400 + q.beats.length * 700 + 300));
    expect(s.rhythmLock, isFalse);
    final pads = sfx.played.where((k) => k.index >= SfxKind.pad0.index).length;
    expect(pads, q.beats.length, reason: 'each beat makes its drum sound');

    final wrong = q.pads.map((p) => p.k).firstWhere((k) => k != q.beats.first);
    engine.rhythmTap(wrong);
    expect(s.tries, 1);
    expect(s.rhythmLock, isTrue, reason: 'replays the rhythm');

    await Future<void>.delayed(Duration(milliseconds: 900 + 400 + q.beats.length * 700 + 300));
    for (final k in q.beats) {
      engine.rhythmTap(k);
    }
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.miss);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('balloons answer by index like a normal choice', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('balloons');
    final s = c.read(gameProvider)!;
    engine.answer(s.q.choices.indexOf(s.q.answer!));
    expect(c.read(progressProvider).starsIn('games'), 1);
  });

  test('the puzzle reveals a piece for every solved question', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('puzzle');
    final s = c.read(gameProvider)!;
    expect(s.total, 4);
    final q = s.q;
    engine.answer(q.choices.indexWhere((v) => v != q.answer));
    engine.answer(q.choices.indexOf(q.answer!));
    expect(s.solved, 1, reason: 'solved after a mistake still opens a piece');
  });
}
