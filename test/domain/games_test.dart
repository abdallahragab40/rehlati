import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/sfx_service.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show FakeSfx, FakeSpeech, makeContainer;

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

  test('where is the cat: cups lock while shuffling; an empty cup shows the cat and shuffles again', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('cups');
    final s = c.read(gameProvider)!;
    final q = s.q;
    expect(s.cupLifted, {q.catCup}, reason: 'the cat is shown first');

    final wrong = (q.catCup + 1) % q.cupCount;
    engine.cupPick(wrong);
    expect(s.tries, 0, reason: 'no picking while the cups move');

    Future<void> settle() => Future<void>.delayed(
        Duration(milliseconds: GameEngine.cupShowMs + GameEngine.cupDropMs + q.cupSwaps * q.cupStepMs + 200));
    await settle();
    expect(s.cupReady, isTrue);
    expect([...s.cupSlots]..sort(), [for (var i = 0; i < q.cupCount; i++) i], reason: 'every cup has its own slot');

    engine.cupPick(wrong);
    expect(s.tries, 1);
    expect(s.cupReady, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    expect(s.cupLifted, contains(q.catCup), reason: 'shows where the cat was');

    await Future<void>.delayed(
        Duration(milliseconds: 1400 + GameEngine.cupDropMs + q.cupSwaps * q.cupStepMs + 300));
    expect(s.cupReady, isTrue);
    engine.cupPick(q.catCup);
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.miss);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('maze: walls stop the rabbit without a penalty, and the carrot finishes it', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('maze');
    final s = c.read(gameProvider)!;
    final q = s.q, n = q.mazeSize;
    expect(s.mazeAt, q.mazeStart);

    // الأرنب فوق على اليمين: فوقه حيطة دايمًا
    engine.mazeMove(-1, 0);
    expect(s.mazeAt, q.mazeStart);
    expect(s.mazeBump, 1);
    expect(s.tries, 0);

    // أقصر طريق بالـ BFS
    final prev = <int, int>{q.mazeStart: -1}, todo = [q.mazeStart];
    const moves = [(mazeN, -1, 0), (mazeS, 1, 0), (mazeE, 0, 1), (mazeW, 0, -1)];
    while (todo.isNotEmpty) {
      final cell = todo.removeAt(0);
      for (final (bit, dr, dc) in moves) {
        if (q.mazeWalls[cell] & bit != 0) continue;
        final to = cell + dr * n + dc;
        if (!prev.containsKey(to)) {
          prev[to] = cell;
          todo.add(to);
        }
      }
    }
    final path = [q.mazeGoal];
    while (prev[path.last]! != -1) {
      path.add(prev[path.last]!);
    }
    for (final to in path.reversed.skip(1)) {
      final d = to - s.mazeAt;
      d.abs() == 1 ? engine.mazeMove(0, d) : engine.mazeMove(d.sign, 0);
    }
    expect(s.mazeAt, q.mazeGoal);
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.done);
    expect(s.mazeTrail.length, path.length);
  });

  test('colour lights repeat like the rhythm but make no drum sounds', () async {
    final c = await makeContainer();
    final sfx = c.read(sfxProvider) as FakeSfx;
    final engine = c.read(gameProvider.notifier)..start('lights');
    final s = c.read(gameProvider)!;
    final q = s.q;
    expect(q.lights, isTrue);
    await Future<void>.delayed(Duration(milliseconds: 1200 + 400 + q.beats.length * 700 + 300));
    expect(s.rhythmLock, isFalse);
    expect(s.padLit, isNull, reason: 'the light goes off after each flash');
    expect(sfx.played.where((k) => k.index >= SfxKind.pad0.index), isEmpty);
    for (final k in q.beats) {
      engine.rhythmTap(k);
    }
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.done);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('tracing: done solves it, drawing off the shape is a gentle retry that clears the board', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('traceAr');
    final s = c.read(gameProvider)!;
    expect(s.q.trace, isNotEmpty);
    engine.traceOff();
    expect(s.tries, 1);
    expect(s.traceTick, 1);
    expect(s.locked, isFalse);
    engine.traceDone();
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.miss);
  });

  test('drag to the basket records the skill on the item type, not the madd type', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('dragSort');
    final s = c.read(gameProvider)!;
    final q = s.q;
    final card = q.sortCards.first;
    final wrongBox = q.boxes.firstWhere((b) => b.key != card.type).key;
    engine.sortPlace(wrongBox, card: 0);
    expect(c.read(progressProvider).skills.keys, contains('dragSort|cat:${card.type}'));
    for (var i = 0; i < q.sortCards.length; i++) {
      engine.sortPlace(q.sortCards[i].type, card: i);
    }
    expect(s.locked, isTrue);
  });

  test('ordered pictures are spoken by their names', () async {
    final c = await makeContainer();
    final speech = c.read(speechProvider) as FakeSpeech;
    final engine = c.read(gameProvider.notifier)..start('cleanSteps');
    final s = c.read(gameProvider)!;
    final first = s.q.answerList.first;
    engine.pick(s.q.items.indexOf(first));
    expect(speech.said.last, [s.q.choiceSay[first]]);
  });

  test('every new picture game is open from the start', () async {
    final c = await makeContainer();
    final p = c.read(progressProvider);
    for (final id in ['oddOne', 'shadow', 'opposite', 'storyOrder', 'category', 'missingPic', 'cups', 'cleanSteps',
        'manner', 'dragSort', 'maze', 'lights', 'traceNum', 'traceAr', 'traceEn']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
      expect(packs[id]!.group, isNotNull, reason: id);
    }
  });

  test('manners are gentle: a wrong answer gets the soft encouragement', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('manner');
    final s = c.read(gameProvider)!;
    final fx = <GameFx>[];
    engine.fx.listen(fx.add);
    expect(s.q.gentle, isTrue);
    engine.answer(s.q.choices.indexWhere((v) => v != s.q.answer));
    await Future<void>.delayed(Duration.zero);
    expect(fx.whereType<FxWrong>().single.gentle, isTrue);
    expect(s.q.mode, QMode.choice);
  });
}
