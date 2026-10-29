import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/language_data.dart';
import 'package:rehlati/core/audio/teaching.dart';
import 'package:rehlati/core/audio/clip_manifest.g.dart';
import 'package:rehlati/domain/generators/sukun_generators.dart';

void main() {
  test('every tanween syllable and sukun word has an exact vowelled teaching input', () {
    final rows = {
      for (final line in File('tool/teaching.tsv').readAsLinesSync())
        if (line.isNotEmpty && !line.startsWith('#')) line.split('\t')[0]: line.split('\t'),
    };
    final texts = [
      for (final l in arLetters.where((l) => l.letter != 'أ'))
        for (final (mark, _) in tanweens) tanweenSyl(l.letter, mark),
      for (final w in sukunWords) ...[w.word, ...w.parts.where((p) => !p.endsWith('ْ'))],
    ];
    for (final text in texts) {
      final key = teachKey(text);
      expect(key, isNotNull, reason: text);
      expect(rows.containsKey(key), isTrue, reason: '$text → $key');
      expect(clipKeys, contains(key), reason: 'missing recording: $text');
      expect(File('assets/audio/clips/$key.m4a').lengthSync(), greaterThan(0));
      if (text != 'ةٌ') expect(rows[key]![2], text, reason: 'preserve vowels: $text');
    }
    for (final w in sukunWords) {
      final letter = arLetters.singleWhere((l) => l.letter == w.sakin[0]);
      expect(rows.containsKey(teachKey('${letter.name} ساكنة')), isTrue);
      expect(w.parts.where((p) => p.endsWith('ْ')).length, 1);
      expect(w.parts.toSet().length, w.parts.length);
    }
    expect(teachKey('شمس'), isNot(teachKey('شَمْسٌ')), reason: 'pausal and tanween endings differ');
    expect(teachKey('بًا'), isNot(teachKey('بَ')));
  });
}
