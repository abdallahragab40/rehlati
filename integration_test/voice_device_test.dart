import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rehlati/content/language_data.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/audio/speech_service.dart';
import 'package:rehlati/core/audio/teaching.dart';
import 'package:rehlati/core/audio/voice_lines.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/main.dart' as app;

/// على جهاز حقيقي: المقاطع المسجّلة (جُمل + مقاطع تعليم) بتتحمّل من الـ assets وبتخلص تشغيل
/// من غير ما نرجع لصوت الجهاز.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recorded Arabic clips play on the device', (tester) async {
    await app.main();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final speech = c.read(speechProvider) as SpeechService;
    final wasOn = c.read(progressProvider).settings.speech;
    c.read(progressProvider.notifier).update((p) => p.settings.speech = true);
    addTearDown(() => c.read(progressProvider.notifier).update((p) => p.settings.speech = wasOn));

    Future<void> playsRecorded(Object text, List<String?> clips) async {
      speech.speak(text, clips: clips);
      var started = false;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        started |= speech.speaking.value;
        if (started && !speech.speaking.value) break;
      }
      debugPrint('VOICE $clips → ${speech.lastEvent}');
      expect(speech.lastEvent, 'مقاطع مسجّلة ✅', reason: '$clips');
      expect(started && !speech.speaking.value, isTrue, reason: 'playback of $clips never finished');
    }

    // لوحة الحروف، سؤال بيخلط جملة ومقطع تعليم، وجملة لوحدها
    final tha = arLetters.firstWhere((l) => l.letter == 'ث');
    await playsRecorded(sayLetter(tha), letterLesson(tha));
    await playsRecorded('أنهي صورة بتبدأ بحرف ق؟', [say('أنهي صورة بتبدأ بحرف'), say('ق')]);
    await playsRecorded(sayWelcome, ['welcome']);
  });
}
