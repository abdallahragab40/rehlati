import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/paths.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show correctIndex, makeContainer;

void main() {
  group('content', () {
    test('every path is 4 weeks of 4 lessons, built from scored stages of its own world', () {
      for (final path in learningPaths) {
        expect(path.weeks.length, 4, reason: path.id);
        for (final w in path.weeks) {
          expect(w.lessons.length, 4, reason: '${path.id} ${w.title}');
          expect(w.goal, isNotEmpty);
        }
        for (final l in path.lessons) {
          expect(l.stages, isNotEmpty, reason: l.id);
          expect(lessonPlayable(l), isTrue, reason: '${l.id} has a missing or letter-board stage');
          expect({for (final s in l.stages) packs[s]!.world}, {path.world}, reason: l.id);
          expect(l.stages.toSet().length, l.stages.length, reason: '${l.id} repeats a stage');
        }
      }
    });

    test('path and lesson ids are unique, since progress is saved under them', () {
      final paths = [for (final p in learningPaths) p.id];
      expect(paths.toSet().length, paths.length);
      final lessons = [for (final p in learningPaths) ...p.lessons.map((l) => l.id)];
      expect(lessons.toSet().length, lessons.length);
      expect(pathById('reading1'), same(readingPath));
      expect(pathById('nope'), isNull);
    });
  });

  group('progress', () {
    test('a passed stage counts for the current lesson only, and lessons open in order', () {
      final p = ProgressData();
      final first = mathPath.lessons.first;
      expect(mathPath.current(p), same(first));
      expect(mathPath.started(p), isFalse);

      // من درس جاي (الجيران في m3) مابيتحسبش لسه
      markPathStage(p, 'neighbors');
      expect(p.pathDone, isEmpty);

      markPathStage(p, 'counting');
      expect(mathPath.stepDone(p, first, 'counting'), isTrue);
      expect(mathPath.lessonDone(p, first), isFalse);
      expect(mathPath.started(p), isTrue);

      markPathStage(p, 'chooseNumber');
      expect(mathPath.lessonDone(p, first), isTrue);
      expect(mathPath.current(p)!.id, 'm2');
      expect(mathPath.lessonsDone(p), 1);
      expect(readingPath.started(p), isFalse, reason: 'a maths stage never moves the reading path');

      // نفس المرحلة في درس بعدين لازم تتلعب تاني وهو الدرس الحالي
      final m4 = mathPath.lessons.firstWhere((l) => l.id == 'm4');
      expect(mathPath.stepDone(p, m4, 'chooseNumber'), isFalse);
    });

    test('finishing every lesson completes the path', () {
      final p = ProgressData();
      for (final l in readingPath.lessons) {
        for (final s in l.stages) {
          markPathStage(p, s);
        }
      }
      expect(readingPath.complete(p), isTrue);
      expect(readingPath.current(p), isNull);
      expect(readingPath.lessonsDone(p), 16);
    });

    test('path progress survives JSON, and old progress has none', () {
      final p = ProgressData();
      markPathStage(p, 'counting');
      final back = ProgressData.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(back.pathDone, {'math1': {'m1:counting'}});
      expect(ProgressData.fromJson({}).pathDone, isEmpty);
      expect(ProgressData().toJson().containsKey('paths'), isFalse, reason: 'old payloads stay unchanged');
    });
  });

  test('a passed round marks the current path lesson', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    for (var i = 0; i < 10; i++) {
      engine.answer(correctIndex(c.read(gameProvider)!.q));
      await Future<void>.delayed(const Duration(milliseconds: 1450));
    }
    expect(c.read(gameProvider)!.result, isNotNull);
    expect(c.read(progressProvider).pathDone, {'math1': {'m1:counting'}});
  }, timeout: const Timeout(Duration(seconds: 30)));
}
