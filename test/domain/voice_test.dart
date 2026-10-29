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
import 'package:rehlati/domain/stages.dart';

/// كل جملة عربية لازم يكون ليها مقطع مسجّل، وإلا الطفل هيسمع صوت الجهاز الآلي.
/// لو الاختبار ده فشل بعد تعديل نص: flutter test tool/voice_phrases_test.dart && python3 tool/render_voice.py
/// بيشتغل بس لما نطق الأسئلة مفتوح (lib/core/features.dart).
void main() {
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
