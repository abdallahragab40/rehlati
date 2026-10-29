// بيجمع كل جملة عربية ممكن التطبيق ينطقها ويكتبها في tool/phrases.tsv
// (المفتاح، النص، واللي يتبعت للصوت فعلاً) عشان tool/render_voice.py يسجّلها.
//
//   flutter test tool/voice_phrases_test.dart && python3 tool/render_voice.py
//
// المولّدات عشوائية، فبنفضل نولّد لحد ما يعدّي عدد كبير من الأسئلة من غير جملة جديدة.
// أسئلة الحساب اللي مقاطع مفاتيحها كاملة (n3 + plus + n4…) مش محتاجة جملة كاملة.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/language_data.dart';
import 'package:rehlati/content/madd.dart';
import 'package:rehlati/content/math_data.dart';
import 'package:rehlati/content/parent_guide_data.g.dart';
import 'package:rehlati/core/audio/speech_service.dart';
import 'package:rehlati/core/audio/teaching.dart';
import 'package:rehlati/core/audio/voice_lines.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/madd_generators.dart';
import 'package:rehlati/domain/progress/badges.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/progress/ranks.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  test('collect Arabic phrases', () {
    final out = <String>{};
    void add(Object? t) {
      if (t is int) {
        add(arNum(t));
      } else if (t is String) {
        final c = SpeechService.clean(signWord[t] ?? t);
        // الحروف والمقاطع والكلمات اللي ليها مقطع تعليم مشكول مش محتاجة مقطع جملة
        if (c.isNotEmpty && teachKey(c) == null) out.add(c);
      }
    }

    // السؤال اللي كل مقاطع مفاتيحه في clips.tsv مش محتاج جملة كاملة
    final clipKeys = {
      for (final l in File('tool/clips.tsv').readAsLinesSync())
        if (l.isNotEmpty && !l.startsWith('#')) l.split('\t').first,
    };
    // say('…') جوه المقاطع = جملة لازم تتسجّل لوحدها
    bool keyed(List<String?>? k) {
      if (k == null || k.isEmpty || k.any((e) => e == null)) return false;
      final ok = k.every((e) => clipKeys.contains(e) || e!.startsWith(sayPrefix));
      if (ok) {
        for (final e in k.where((e) => e!.startsWith(sayPrefix))) {
          add(e!.substring(sayPrefix.length));
        }
      }
      return ok;
    }

    void addQuestion(Question q) {
      if (!keyed(q.clips)) add(q.speak);
      if (!keyed(q.clipsHint)) add(q.speakHint ?? q.hint);
      add(q.sayRight);
      for (final v in q.choices) {
        add(q.choiceSay[v] ?? v);
      }
      for (final v in [...q.items, ...q.right, ...q.pairMap.keys]) {
        add(v);
      }
      for (final c in q.cells) {
        add(c.ch);
      }
      for (final c in q.cards) {
        add(c.ch);
      }
      for (final c in q.sortCards) {
        add(c.say);
      }
      for (final v in [...q.visuals, ...?q.revealVisuals]) {
        if (v is ListenVisual) add(v.say);
        if (v is MaddTextVisual) add(v.say);
      }
    }

    final types = [
      for (final s in packs.values.where((s) => !s.isLearn && !s.isEnglish)) ...[
        s.id,
        if (s.madd != null) for (final k in s.madd!.kinds) '${s.id}:$k',
      ],
    ];
    for (final type in types) {
      final r = Rng.seeded(type.hashCode);
      // "أتقن" كل الأنواع عشان المولّد يفتح كل الأمثلة كمان
      for (final p in [ProgressData(), _mastered()]) {
        for (var lv = 1; lv <= 4; lv++) {
          var quiet = 0;
          while (quiet < 3000) {
            final before = out.length;
            addQuestion(makeQuestion(type, lv, r, progress: p));
            quiet = out.length == before ? quiet + 1 : 0;
          }
        }
      }
    }

    // المحرك والشاشات
    for (final s in packs.values.where((s) => !s.isEnglish)) {
      add(sayStageIntro(s.name));
    }
    for (final (t, _) in praiseSay) {
      add(t);
    }
    for (final t in [sayRetry, sayNotThis, sayWelcome, sayLocked, sayGoalDone, sayTimeUp, ...sayVoiceTest]) {
      add(t);
    }
    for (final b in badges) {
      add(sayToast(b.name, rank: false));
    }
    for (final r in ranks) {
      add(sayToast(r.name, rank: true));
    }
    for (final t in maddTypes) {
      add(sayRemedial(t.name));
      add(saySyl(t.result));
      for (final e in t.examples) {
        add(saySyl(e));
        add(saySyl(normalizeSyl(e, t.key)));
      }
    }
    for (final w in maddWords) {
      add(w.w);
      add(sayMamdoud(mamdoudOf(w.madd)));
      add(sayMaddChar(maddCharOf(w.madd)));
    }
    for (final b in pgBehaviors) {
      if (b.game != null) add(fillChildName(b.game!.q, ''));
    }

    // الحرف لوحده بيتنطق باسمه ("ج م ل" ← "جيم، ميم، لام") عشان الصوت مايقراهوش صوت مبهم.
    // المقاطع المشكولة ("بَ") بتفضل زي ما هي لأنها صوت مش اسم حرف.
    final names = {
      for (final l in arLetters) l.letter: l.name!,
      'ا': 'ألف', 'إ': 'ألف', 'آ': 'ألف', 'ى': 'ألف', 'ة': 'تاء مربوطة', 'ء': 'همزة', 'ئ': 'همزة', 'ؤ': 'همزة',
    };
    // المقطع لوحده الصوت بيقوله في عُشر ثانية فمايتسمعش: المد بنكرّر حرفه عشان يتمدّ
    // فعلاً (بَا ← بَاااا)، والحركة القصيرة بنقفلها بهاء ساكنة (بَ ← بَهْ).
    final syl = RegExp(r'^([ء-ي])([َُِ])([اوي])?$');
    String spoken(String t) {
      final out = <String>[];
      var spelling = false;
      final words = t.split(' ').where((w) => w != 'ـ').toList();
      // جملة مشكولة (نَنَامُ فِي اللَّيْلِ): "فِي" فيها كلمة مش مقطع، فمابتتمدّش.
      // الشدة لوحدها (كوّن) مش تشكيل كامل، فمابتتحسبش
      String bareOf(String w) => w.replaceAll(RegExp(r'[؟?.:،!]$'), '');
      final sentence = words.any((w) => RegExp('[\u064B-\u0650\u0652]').hasMatch(w) && !syl.hasMatch(bareOf(w)));
      for (var i = 0; i < words.length; i++) {
        final w = words[i];
        final bare = w.replaceAll(RegExp(r'[؟?.:،!]$'), '');
        // "و" لوحدها غالبًا حرف عطف — حرف بس لو بعد "حرف" أو وسط حروف متهجّية
        bool letterAt(int j) => j >= 0 && j < words.length && words[j].length == 1 && names.containsKey(words[j]);
        final isAnd = bare == 'و' && words.length > 1 && !(i > 0 && words[i - 1].endsWith('حرف')) && !letterAt(i - 1) && !letterAt(i + 1);
        final n = isAnd ? null : names[bare];
        final m = syl.firstMatch(bare);
        if (n != null) {
          out.add(spelling ? '، $n' : n);
          if (w.length > 1) out.add(w.substring(1));
        } else if (m != null && !sentence) {
          out.add('${m[1]}${m[2]}${m[3] == null ? 'هْ' : m[3]! * 4}${w.substring(bare.length)}');
        } else {
          out.add(w);
        }
        spelling = n != null;
      }
      return out.join(' ').replaceAll(' ، ', '، ');
    }

    // جملة كلها مقاطع (اسمع المقطع) بتتقال أبطأ
    String rate(String t) =>
        t.split(' ').where((w) => w.isNotEmpty && w != '.').every((w) => syl.hasMatch(w)) ? '-35%' : '';

    final keys = <String, String>{};
    final rows = StringBuffer('# GENERATED by tool/voice_phrases_test.dart — key, text, spoken, rate\n');
    for (final t in out.toList()..sort()) {
      final k = SpeechService.phraseKey(t);
      expect(keys.putIfAbsent(k, () => t), t, reason: 'hash collision');
      rows.writeln('$k\t$t\t${spoken(t)}\t${rate(t)}');
    }
    File('tool/phrases.tsv').writeAsStringSync(rows.toString());
    // ignore: avoid_print
    print('${out.length} phrases → tool/phrases.tsv');
  });
}

ProgressData _mastered() {
  final p = ProgressData();
  for (final t in maddTypes) {
    for (var i = 0; i < 30; i++) {
      p.madd.record(type: t.key, word: null, stageId: 'madd_types', ok: true);
    }
  }
  return p;
}
