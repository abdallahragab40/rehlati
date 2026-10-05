@Tags(['network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rehlati/features/quran/quran_check_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';

/// بيكلم المصادر الحقيقية — مش بيشتغل في الاختبارات العادية:
///   flutter test --tags network
void main() {
  test('both sources agree on every letter of Juz Amma', () async {
    final repo = QuranRepository(client: http.Client(), cacheFile: () async => File('${Directory.systemTemp.path}/q_live.json'));
    var marksOnly = 0;
    for (var s = 78; s <= 114; s++) {
      final all = (await repo.fetchAll(s)).values.toList();
      expect(all[0].length, all[1].length, reason: 'surah $s ayah count');
      for (var i = 0; i < all[0].length; i++) {
        final r = compareAyah(all[0][i].text, all[1][i].text);
        expect(r, isNot(AyahMatch.different), reason: '$s:${i + 1}\n${all[0][i].text}\n${all[1][i].text}');
        if (r == AyahMatch.marksOnly) marksOnly++;
      }
    }
    // ignore: avoid_print
    print('marks-only differences: $marksOnly');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
