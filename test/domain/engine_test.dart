import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/sfx_service.dart';
import 'package:rehlati/core/audio/speech_service.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSpeech implements Speech {
  final said = <Object>[];
  @override
  final ValueNotifier<bool> speaking = ValueNotifier(false);
  @override
  void speak(Object text, {List<String?>? clips}) => said.add(text);
  @override
  void speakEn(Object text) => said.add(text);
  @override
  void stop() {}
}

class FakeSfx extends Sfx {
  final played = <SfxKind>[];
  @override
  void play(SfxKind kind) => played.add(kind);
}

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    speechProvider.overrideWithValue(FakeSpeech()),
    sfxProvider.overrideWithValue(FakeSfx()),
    rngProvider.overrideWithValue(Rng.seeded(3)),
  ]);
  addTearDown(c.dispose);
  // autoDispose — لازم حد يسمع عشان المحرك يفضل عايش
  c.listen(gameProvider, (_, _) {});
  return c;
}

int correctIndex(Question q) => q.choices.indexOf(q.answer!);
int wrongIndex(Question q) => q.choices.indexWhere((c) => c != q.answer);

void main() {
  test('a first-try answer gives a star and moves on after the delay', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    final s = c.read(gameProvider)!;
    expect(s.total, 10);

    engine.answer(correctIndex(s.q));
    expect(c.read(progressProvider).stars, 1);
    expect(c.read(progressProvider).starsIn('math'), 1);
    expect(s.dots[0], DotState.done);
    expect(s.locked, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(c.read(gameProvider)!.idx, 1);
  });

  test('the next question waits for the praise to finish speaking', () async {
    final c = await makeContainer();
    final speech = c.read(speechProvider) as FakeSpeech;
    final engine = c.read(gameProvider.notifier)..start('counting');
    speech.speaking.value = true;
    engine.answer(correctIndex(c.read(gameProvider)!.q));

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(c.read(gameProvider)!.idx, 0, reason: 'still speaking');
    speech.speaking.value = false;
    await Future<void>.delayed(const Duration(milliseconds: GameEngine.speechGapMs + 50));
    expect(c.read(gameProvider)!.idx, 1);
  });

  test('two wrong tries highlight the answer and give no star', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    final s = c.read(gameProvider)!;
    final q = s.q;

    engine.answer(wrongIndex(q));
    expect(s.hintTarget, isNull);
    engine.answer(wrongIndex(q));
    expect(s.hintTarget, q.answer);
    expect(c.read(progressProvider).wrong, 1, reason: 'a question is counted wrong only once');

    engine.answer(correctIndex(q));
    expect(c.read(progressProvider).stars, 0);
    expect(s.dots[0], DotState.miss);
    expect(s.mistakes, ['counting']);
  });

  test('a perfect round unlocks the next stage and records medals', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    for (var i = 0; i < 10; i++) {
      final s = c.read(gameProvider)!;
      engine.answer(correctIndex(s.q));
      await Future<void>.delayed(const Duration(milliseconds: 1450));
    }
    final s = c.read(gameProvider)!;
    expect(s.result, isNotNull);
    expect(s.result!.correct, 10);
    expect(s.result!.unlocked?.id, 'chooseNumber');
    final p = c.read(progressProvider);
    expect(p.best['counting'], 3);
    expect(p.achievements, contains('first_game'));
    expect(p.achievements, contains('stars10'));
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('order mode accepts items one by one in order', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('ascending');
    final s = c.read(gameProvider)!;
    final q = s.q;
    for (final v in q.answerList) {
      engine.pick(q.items.indexOf(v));
    }
    expect(s.picked, q.answerList);
    expect(s.locked, isTrue);
    expect(c.read(progressProvider).stars, 1);
  });

  test('leaving the screen cancels pending timers', () async {
    final c = await makeContainer();
    final sub = c.listen(gameProvider, (_, _) {});
    final engine = c.read(gameProvider.notifier)..start('counting');
    engine.answer(correctIndex(c.read(gameProvider)!.q));
    // كل المستمعين بيمشوا → المحرك بيتقفل
    sub.close();
    c.invalidate(gameProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    // مفيش استثناء من مؤقت شغال على محرك مقفول
    expect(c.read(progressProvider).stars, 1);
  });
}
