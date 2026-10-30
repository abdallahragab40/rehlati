import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/language_data.dart';
import 'package:rehlati/core/audio/clip_manifest.g.dart';
import 'package:rehlati/core/audio/speech_service.dart';
import 'package:rehlati/core/audio/teaching.dart';
import 'package:rehlati/core/audio/voice_lines.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/school_lessons.dart';
import 'package:rehlati/domain/stages.dart';

/// كل جملة عربية لازم يكون ليها مقطع مسجّل، وإلا الطفل هيسمع صوت الجهاز الآلي.
/// لو الاختبار ده فشل بعد تعديل نص: flutter test tool/voice_phrases_test.dart && python3 tool/render_voice.py
/// بيشتغل بس لما نطق الأسئلة مفتوح (lib/core/features.dart).
void main() {
  test('English plays its recordings sentence by sentence, with a pause between', () {
    final keys = SpeechService.enClipsFor(['Try again', 'B is for Ball'])!;
    expect(keys, [SpeechService.enKey('Try again'), 'pause', SpeechService.enKey('B is for Ball')]);
    expect(clipKeys, contains('pause'));
    expect(SpeechService.enClipsFor('Very good! A sentence nobody recorded.'), isNull, reason: 'one missing → device voice');
  });

  test('every fixed English line is recorded', () {
    for (final t in ['Very good!', 'Try again', 'Not this one', 'Hello! Which letter is this?',
        'This stage is locked. Finish the one before it first.']) {
      expect(SpeechService.enClipsFor(t), isNotNull, reason: t);
    }
    for (final it in enLetters) {
      expect(SpeechService.enClipsFor('${it.letter} . ${it.word}'), isNotNull, reason: it.letter);
    }
  });

  test('English is spoken one sentence at a time', () {
    expect(SpeechService.enSentences('cat. Which letter does it start with?'), ['cat.', 'Which letter does it start with?']);
    expect(SpeechService.enSentences('A . Apple'), ['A .', 'Apple']);
    expect(SpeechService.enSentences('Complete the word cat'), ['Complete the word cat']);
  });

  if (!voiceEnabled) {
    test('every Arabic line is recorded', () {}, skip: 'question voice is off (lib/core/features.dart)');
    return;
  }
  void recorded(Object text, [List<String?>? clips]) =>
      expect(SpeechService.clipsFor(text, clips), isNotNull, reason: 'no recording for: $text');

  test('phrase keys are stable', () {
    expect(SpeechService.phraseKey(SpeechService.clean(sayRetry)), SpeechService.phraseKey('حاول مرة تانية'));
    expect(SpeechService.phraseKey('أ'), isNot(SpeechService.phraseKey('ا')));
  });

  test('fixed lines are recorded', () {
    for (final t in [sayRetry, sayNotThis, sayGoalDone, sayTimeUp]) {
      recorded(t);
    }
    recorded(sayVoiceTest);
    recorded(sayWelcome, ['welcome']);
    recorded(sayLocked, ['locked']);
    for (final l in arLetters) {
      recorded(sayLetter(l), letterLesson(l));
    }
  });

  test('every taught letter, syllable and word has a فصحى clip', () {
    final parts = [
      for (final l in arLetters) ...[l.letter, l.word, for (final h in ['َ', 'ُ', 'ِ']) '${l.letter}$h'],
      for (final w in arWords) ...[w.word, ...w.word.split('')],
    ];
    for (final p in parts) {
      final k = teachKey(p);
      expect(k, isNotNull, reason: 'no teaching key for: $p');
      expect(clipKeys, contains(k), reason: 'teaching clip not rendered: $k ($p)');
    }
  });

  // نفس اللي GameEngine بيقوله بالإنجليزي: السؤال، والاختيار + Try again + التلميح، والاختيار + Very good!
  for (final s in packs.values.where((s) => !s.isLearn && s.isEnglish)) {
    test('${s.id} English lines are recorded', () {
      final r = Rng.seeded(s.id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 60; i++) {
          final q = makeQuestion(s.id, lv, r, progress: ProgressData());
          expect(SpeechService.enClipsFor(q.speak), isNotNull, reason: q.speak);
          for (final c in q.choices) {
            final said = q.choiceSay[c] ?? '$c';
            expect(SpeechService.enClipsFor([said, 'Try again', q.speakHint ?? '']), isNotNull, reason: '$said / ${q.speakHint}');
            expect(SpeechService.enClipsFor([q.sayRight ?? said, 'Very good!']), isNotNull, reason: said);
          }
        }
      }
    });
  }

  test('school lessons and exams start with a recorded intro, and their questions are recorded', () {
    for (final id in allSchoolRoundIds()) {
      final s = schoolStage(id)!;
      final qs = schoolQuestions(schoolRound(id)!, ProgressData(age: 6), Rng.seeded(id.hashCode));
      if (s.isEnglish) {
        for (final q in qs.where((q) => q.isEnglish)) {
          expect(SpeechService.enClipsFor(q.speak), isNotNull, reason: '$id: ${q.speak}');
        }
        continue;
      }
      recorded([sayStageIntro(s.name), qs.first.speak], qs.first.clips == null ? null : [say(sayStageIntro(s.name)), ...qs.first.clips!]);
      for (final q in qs) {
        recorded(q.speak, q.clips);
      }
    }
  });

  for (final s in packs.values.where((s) => !s.isLearn && !s.isEnglish)) {
    test('${s.id} questions are recorded', () {
      final r = Rng.seeded(s.id.hashCode);
      final p = ProgressData();
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 60; i++) {
          final q = makeQuestion(s.id, lv, r, progress: p);
          recorded([sayStageIntro(s.name), q.speak], q.clips);
          recorded(q.speak, q.clips);
          // غلطة في وضع الاختيار: القيمة + حاول تاني + التلميح (نفس شكل GameEngine.answer)
          for (final c in q.choices) {
            final said = q.choiceSay[c] ?? (c is int ? arNum(c) : (signWord[c] ?? '$c'));
            final clip = q.choiceSay.containsKey(c) ? say(said) : (c is int ? nk(c) : signClip[c] ?? say(said));
            recorded(
              [said, sayRetry, q.speakHint ?? q.hint],
              q.clipsHint == null ? null : [clip, 'retry', ...q.clipsHint!],
            );
          }
        }
      }
    });
  }
}
