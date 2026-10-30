import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/features/quran/quran_modes.dart';

void main() {
  // عينات قصيرة للاختبار بس (مش نص قرآني)
  const ayahs = [Ayah(1, 'كلمة أولى طويلة'), Ayah(2, 'تانية هنا'), Ayah(3, 'تالتة ۚ هناك'), Ayah(4, 'رابعة')];

  test('complete the ayah hides only the last word and offers real words', () {
    for (var seed = 0; seed < 30; seed++) {
      final f = completeAyahQuestion(ayahs, Rng.seeded(seed))!;
      final words = ayahs[f.index].text.split(' ');
      expect(words.length, greaterThanOrEqualTo(2), reason: 'one-word ayahs are skipped');
      expect('${f.shown} ${f.answer}', ayahs[f.index].text);
      expect(f.options, hasLength(3));
      expect(f.options.toSet(), hasLength(3));
      expect(f.options, contains(f.answer));
      final all = {for (final a in ayahs) ...a.text.split(' ')};
      expect(f.options.every(all.contains), isTrue);
    }
  });

  test('a surah of one-word ayahs has no complete-the-ayah question', () {
    expect(completeAyahQuestion(const [Ayah(1, 'أ'), Ayah(2, 'ب'), Ayah(3, 'ج')], Rng.seeded(1)), isNull);
  });
}
