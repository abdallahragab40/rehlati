import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/content/math_data.dart';
import 'package:rehlati/core/audio/voice_lines.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/fresh_round.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/question_key.dart';
import 'package:rehlati/domain/school_lessons.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show FakeSpeech, makeContainer;

Question _q(String answer, {String ask = 'اختار'}) =>
    Question(type: 't', mode: QMode.choice, ask: ask, speak: ask, hint: '', choices: [answer, 'x'], answer: answer);

/// جولات ورا بعض لطفل واحد زي ما المحرك بيعملها، لحد ما الجديد يخلص أو [rounds] جولة.
({int rounds, bool exhausted}) _play(Stage s, ProgressData p, Rng r, {int rounds = 25}) {
  final shown = <int>{};
  for (var i = 0; i < rounds; i++) {
    final list = drawRound(
      count: s.count ?? questionsPerRound, level: roundLevel(p, s), seen: p.hasSeen,
      make: (lv) => makeQuestion(s.id, lv, r, progress: p),
    );
    if (list.isEmpty) return (rounds: i, exhausted: true);
    final here = <int>{};
    for (final q in list) {
      if (isActivity(q)) continue;
      final k = questionKey(q);
      expect(here.add(k), isTrue, reason: '${s.id}: the same question twice in one round\n${questionSig(q)}');
      expect(shown.contains(k), isFalse, reason: '${s.id}: a solved question came back as new\n${questionSig(q)}');
      shown.add(k);
      p.markSeen(q);
    }
  }
  return (rounds: rounds, exhausted: false);
}

void main() {
  test('every learning stage: no repeat inside a round, and nothing solved comes back as new', () {
    final tracked = packs.values.where(tracksRepeats).toList();
    expect(tracked.length, greaterThan(200));
    var exhausted = 0;
    for (final s in tracked) {
      final r = _play(s, ProgressData(grade: 'p3'), Rng.seeded(s.id.hashCode));
      if (r.exhausted) exhausted++;
    }
    // ignore: avoid_print
    print('${tracked.length} stages; $exhausted run out of new questions within 25 rounds');
  });

  test('games and tracing are not limited: replaying them is the activity', () {
    for (final id in ['maze', 'sudoku', 'rhythm', 'traceNum']) {
      expect(tracksRepeats(packs[id]!), isFalse, reason: id);
    }
    expect(tracksRepeats(packs['counting']!), isTrue);
  });

  test('the fingerprint keeps marks: words that differ only by a vowel are different questions', () {
    expect(questionKey(_q('الطيورَ')), isNot(questionKey(_q('الطيورِ'))));
    expect(questionKey(_q('نهرٌ')), isNot(questionKey(_q('نهرٍ'))));
    // ترتيب الاختيارات والمسافات الزيادة مش سؤال جديد
    const a = Question(type: 't', mode: QMode.choice, ask: 'كام؟', speak: 'كام؟', hint: '', choices: [1, 2, 3], answer: 2);
    const b = Question(type: 't', mode: QMode.choice, ask: 'كام؟ ', speak: 'كام؟', hint: '', choices: [3, 1, 2], answer: 2);
    expect(questionKey(a), questionKey(b));
  });

  test('when the new questions run out the round gets shorter, then empty; review still has questions', () {
    var n = 0;
    final pool = ['أ', 'ب', 'ت'];
    Question make(int _) => _q(pool[n++ % pool.length]);
    final p = ProgressData();
    final first = drawRound(count: 10, level: 1, make: make, seen: p.hasSeen);
    expect(first.map((q) => q.answer), unorderedEquals(pool), reason: 'only 3 different questions exist');
    first.forEach(p.markSeen);
    expect(drawRound(count: 10, level: 1, make: make, seen: p.hasSeen), isEmpty);
    final review = drawRound(count: 10, level: 1, make: make, seen: p.hasSeen, review: true);
    expect(review.length, 3, reason: 'review repeats on purpose, but never twice in a round');
  });

  test('the seen log survives saving, and the oldest entries go first past the cap', () {
    final p = ProgressData()..markSeen(_q('أ'));
    final back = ProgressData.fromJson(p.toJson());
    expect(back.hasSeen(_q('أ')), isTrue);
    expect(back.hasSeen(_q('ب')), isFalse);
    final big = ProgressData();
    for (var i = 0; i <= ProgressData.seenCap; i++) {
      big.markSeen(_q('$i'));
    }
    expect(big.seen['t']!.length, ProgressData.seenCap);
    expect(big.hasSeen(_q('0')), isFalse);
    expect(big.hasSeen(_q('${ProgressData.seenCap}')), isTrue);
  });

  test('school rounds skip solved questions and never repeat inside a round', () {
    final id = allSchoolRoundIds().firstWhere((id) => id.contains('p1-t1-math'));
    final round = schoolRound(id)!;
    final p = ProgressData(grade: 'p1');
    final r = Rng.seeded(5);
    final first = schoolQuestions(round, p, r, fresh: true);
    expect(first, isNotEmpty);
    final keys = [for (final q in first) if (!isActivity(q)) questionKey(q)];
    expect(keys.toSet().length, keys.length);
    first.forEach(p.markSeen);
    for (final q in schoolQuestions(round, p, r, fresh: true)) {
      expect(p.hasSeen(q), isFalse);
    }
  });

  test('the engine says plainly when nothing new is left, and its review round is labelled', () async {
    final c = await makeContainer();
    final progress = c.read(progressProvider.notifier);
    final stage = packs['en_body']!;
    // الطفل حل كل أسئلة المرحلة في كل المستويات
    final r = Rng.seeded(1);
    progress.update((p) {
      for (var i = 0; i < 4000; i++) {
        p.markSeen(makeQuestion(stage.id, 1 + i % 4, r, progress: p));
      }
    });
    final engine = c.read(gameProvider.notifier)..start(stage.id);
    final s = c.read(gameProvider)!;
    expect(s.allSeen, isTrue);
    expect((c.read(speechProvider) as FakeSpeech).said.last, sayAllSeen);

    engine.reviewStage();
    final review = c.read(gameProvider)!;
    expect(review.allSeen, isFalse);
    expect(review.revisiting, isTrue);
    expect(review.bubble, startsWith('🔁 مراجعة'));
  });

  test('a finished question is logged as seen for the child', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    final q = c.read(gameProvider)!.q;
    engine.answer(q.choices.indexOf(q.answer!));
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(c.read(progressProvider.notifier).data.hasSeen(q), isTrue);
  });
}
