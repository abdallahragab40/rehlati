import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/learning_time.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';

import 'engine_test.dart' show correctIndex, makeContainer;

const min = 60000;

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 5, 10);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  void wait(int minutes, {LearningTimer? flushEvery}) {
    for (var i = 0; i < minutes; i++) {
      now = now.add(const Duration(minutes: 1));
      flushEvery?.flush();
    }
  }

  ProgressData progress(ProviderContainer c) => c.read(progressProvider);

  test('only open, foreground activity time counts', () async {
    final c = await makeContainer();
    final t = c.read(learningTimeProvider);
    wait(5); // على الخريطة — مفيش نشاط مفتوح
    t.enter();
    wait(1, flushEvery: t);
    wait(1, flushEvery: t);
    t.setForeground(false);
    wait(10); // التطبيق في الخلفية عشر دقايق
    t.setForeground(true);
    wait(1, flushEvery: t);
    t.leave();
    wait(3);
    t.flush();
    expect(progress(c).todayMs, 3 * min);
    expect(progress(c).timeMs, 3 * min);
  });

  test('repeated flushes, checkpoints and leaves never double count', () async {
    final c = await makeContainer();
    final t = c.read(learningTimeProvider)..enter();
    wait(1);
    t
      ..flush()
      ..flush()
      ..checkpoint();
    wait(1);
    t
      ..leave()
      ..leave()
      ..setForeground(false)
      ..setForeground(true);
    wait(4);
    t.flush();
    expect(progress(c).todayMs, 2 * min);
  });

  test('time across midnight is split between the two days', () async {
    final c = await makeContainer();
    now = DateTime(2026, 10, 5, 23, 58);
    final t = c.read(learningTimeProvider)..enter();
    wait(5, flushEvery: t);
    t.leave();
    final p = progress(c);
    expect(p.days['2026-10-05']!.ms, 2 * min);
    expect(p.days['2026-10-06']!.ms, 3 * min);
    expect(p.todayMs, 3 * min, reason: 'the new day starts its own allowance');
  });

  test('a long silent gap counts at most one segment and a clock moved back counts nothing', () async {
    final c = await makeContainer();
    final t = c.read(learningTimeProvider)..enter();
    wait(10);
    t.flush();
    expect(progress(c).todayMs, 2 * min);

    now = now.subtract(const Duration(minutes: 5));
    t.flush();
    expect(progress(c).todayMs, 2 * min);
    wait(1);
    t.leave();
    expect(progress(c).todayMs, 3 * min);
  });

  test('switching child records the open time for the child who was playing', () async {
    final c = await makeContainer();
    final n = c.read(progressProvider.notifier);
    final t = c.read(learningTimeProvider)..enter();
    wait(1, flushEvery: t);
    wait(1);
    await n.addChild();
    final second = c.read(activeChildProvider);
    wait(1);
    t.leave();
    expect(progress(c).todayMs, 1 * min);
    await n.switchTo(ProgressRepository.mainId);
    expect(progress(c).todayMs, 2 * min);
    expect(second, isNot(ProgressRepository.mainId));
  });

  test('the limit uses exact time, not rounded minutes', () {
    final p = ProgressData()..settings.limitMin = 10;
    p.addTime(9 * min + 30000);
    expect(p.todayMin, 10, reason: 'display still rounds');
    expect(p.limitReached, isFalse);
    expect(p.limitLeft, 1);
    p.addTime(29999);
    expect(p.limitReached, isFalse);
    p.addTime(1);
    expect([p.limitReached, p.limitLeft], [true, 0]);
  });

  test('a game stops between questions when the limit is reached, and replay stays stopped', () async {
    final c = await makeContainer();
    c.read(progressProvider.notifier).update((p) => p.settings.limitMin = 1);
    final t = c.read(learningTimeProvider)..enter();
    final engine = c.read(gameProvider.notifier)..start('counting');
    var s = c.read(gameProvider)!;
    expect(s.timeUp, isFalse);

    wait(1, flushEvery: t);
    engine.answer(correctIndex(s.q));
    expect(c.read(progressProvider).stars, 1, reason: 'the current question finishes normally');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    s = c.read(gameProvider)!;
    expect([s.timeUp, s.result], [true, null]);

    engine.replay();
    expect(c.read(gameProvider)!.timeUp, isTrue);
  });
}
