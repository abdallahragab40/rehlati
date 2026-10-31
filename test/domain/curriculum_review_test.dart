import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/basics_generators.dart';
import 'package:rehlati/domain/generators/en_primary_generators.dart';
import 'package:rehlati/domain/generators/grade4_math_generators.dart';
import 'package:rehlati/domain/generators/grade5_math_generators.dart';
import 'package:rehlati/domain/generators/grade6_math_generators.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/school_lessons.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  test(
    'all 36 books have ready lessons and valid focused choices at every level',
    () {
      expect(schoolBooks.map((b) => b.id).toSet(), hasLength(36));
      final r = Rng.seeded(20261031);
      for (final book in schoolBooks) {
        for (final unit in book.units) {
          for (final lesson in unit.lessons) {
            expect(lesson.ready, isTrue, reason: '${book.id}: ${lesson.title}');
            for (final item in lesson.items) {
              final gen = packs[item.stage]!.gen;
              if (gen == null) continue; // Madd has its own question factory.
              for (var lv = item.minLevel; lv <= 4; lv++) {
                for (var i = 0; i < 20; i++) {
                  final q = gen(lv, r, focus: item.focus);
                  if (q.mode != QMode.choice) continue;
                  final reason =
                      '${book.id}: ${lesson.title}, ${item.stage}/${item.focus}, level $lv';
                  expect(q.choices, contains(q.answer), reason: reason);
                  expect(
                    q.choices.length,
                    greaterThanOrEqualTo(2),
                    reason: reason,
                  );
                  expect(
                    q.choices.toSet().length,
                    q.choices.length,
                    reason: reason,
                  );
                }
              }
            }
          }
        }
      }
    },
  );

  test('addition and subtraction stories stay on the requested operation', () {
    final r = Rng.seeded(14);
    for (final focus in ['add', 'sub']) {
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 60; i++) {
          final q = wordProblem(lv, r, focus: focus);
          expect(q.skill, 'wp:$focus');
          final tiles = (q.visuals.single as ExprVisual).parts;
          final a = (tiles[0] as ExprSide).number!;
          final b = (tiles[2] as ExprSide).number!;
          expect(q.answer, focus == 'add' ? a + b : a - b);
        }
      }
    }
  });

  test(
    'short vowel lessons use only their target vowels and preserve word focus',
    () {
      final r = Rng.seeded(25);
      for (final vowels in ['ae', 'io', 'u', 'aei']) {
        for (var i = 0; i < 100; i++) {
          final q = enCvc(4, r, focus: 'vowels:$vowels');
          expect(vowels.contains((q.answer as String)[1]), isTrue);
        }
      }
      expect(enCvc(1, r, focus: 'cat').answer, 'cat');
    },
  );

  test(
    'school rounds exercise the intended skills even at the first level',
    () {
      final expected = <String, Set<String>>{
        'القيمة المطلقة': {'int:abs'},
        'خط الأعداد ومقارنة الأعداد': {'int:read', 'int:compare'},
        'التعبيرات والمقادير الجبرية': {'alg:equiv'},
        'العلاقة بين متغيرين': {
          'alg:independent',
          'alg:dependent',
          'alg:value',
        },
        'العامل المشترك الأكبر والمضاعف المشترك الأصغر': {
          'factors:gcf',
          'factors:common',
        },
        'النسبة والنسب المتكافئة': {'ratio:simplest', 'ratio:equiv'},
        'الوسط الحسابي والوسيط والمنوال': {
          'stat:mean',
          'stat:median',
          'stat:mode',
        },
        'المدى': {'stat:range'},
      };
      for (final entry in expected.entries) {
        final book = schoolBooks.singleWhere(
          (b) =>
              b.grade == 'p6' &&
              b.subject == 'math' &&
              b.units.any((u) => u.lessons.any((l) => l.title == entry.key)),
        );
        final u = book.units.indexWhere(
          (u) => u.lessons.any((l) => l.title == entry.key),
        );
        final l = book.units[u].lessons.indexWhere((l) => l.title == entry.key);
        final round = schoolRound(lessonId(book, u, l))!;
        final skills = <String>{};
        for (var seed = 0; seed < 20; seed++) {
          final qs = schoolQuestions(
            round,
            ProgressData(age: 6),
            Rng.seeded(seed),
          );
          expect(qs, hasLength(round.count));
          skills.addAll(qs.map((q) => q.skill!));
        }
        expect(skills, entry.value, reason: entry.key);
      }
    },
  );

  test('present continuous focus excludes simple present questions', () {
    final r = Rng.seeded(16);
    for (var i = 0; i < 100; i++) {
      expect(enContinuous(1, r, focus: 'continuous').skill, 'en_cont:cont');
      expect(enContinuous(1, r, focus: 'simple').skill, 'en_cont:simple');
    }
  });

  test(
    'absolute value includes zero and both signs with correct nonnegative answers',
    () {
      final r = Rng.seeded(6);
      final seen = <int>{};
      for (var i = 0; i < 600; i++) {
        final q = integers(1, r, focus: 'abs');
        final n = List.generate(41, (i) => i - 20).singleWhere(
          (n) => q.ask == 'القيمة المطلقة للعدد ${intWord(n)} كام؟',
        );
        seen.add(n);
        expect(q.answer, ar(n.abs()));
      }
      expect(seen, containsAll([-20, 0, 20]));
    },
  );

  int arNum(String s) => int.parse(s.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join());

  test('mixed number sums and differences are right, in units of the common denominator', () {
    final r = Rng.seeded(31);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 200; i++) {
        final q = fractions5(lv, r, focus: 'mixed');
        expect(q.skill, anyOf('frac5:mixedAdd', 'frac5:mixedSub'));
        // «٢ و ٣/٤» أو «٣/٤» أو «٢»
        (int, int, int) parse(String t) {
          final m = RegExp(r'^(?:(\S+) و )?(\S+)/(\S+)$').firstMatch(t.trim());
          if (m == null) return (arNum(t.trim()), 0, 1);
          return (m[1] == null ? 0 : arNum(m[1]!), arNum(m[2]!), arNum(m[3]!));
        }
        final shown = (q.visuals.single as BigLetterVisual).text;
        final add = shown.contains('+');
        final sides = shown.split(add ? ' + ' : ' − ').map(parse).toList();
        final (w, n, d) = parse('${q.answer}');
        final value = (w * d + n) / d;
        double v((int, int, int) x) => (x.$1 * x.$3 + x.$2) / x.$3;
        expect(value, closeTo(add ? v(sides[0]) + v(sides[1]) : v(sides[0]) - v(sides[1]), 1e-9), reason: '$shown = ${q.answer}');
        expect(n, lessThan(d), reason: 'proper fraction part');
      }
    }
  });

  test('elapsed time adds minutes across the hour on a 12-hour clock', () {
    final r = Rng.seeded(32);
    int minutes(String t) {
      final p = t.split(':');
      return arNum(p[0]) * 60 + arNum(p[1]);
    }
    for (var i = 0; i < 300; i++) {
      final q = unitConvert(2, r, focus: 'elapsed');
      expect(q.skill, 'unit:elapsed');
      final times = RegExp(r'[٠-٩]+:[٠-٩]+').allMatches(q.ask).map((m) => minutes(m[0]!)).toList();
      expect(times.every((t) => t < 13 * 60), isTrue, reason: q.ask);
      if (times.length == 2) {
        expect(arNum('${q.answer}'), times[1] - times[0], reason: q.ask);
      } else {
        final dur = arNum(RegExp(r'بعد (\S+) دقيقة').firstMatch(q.ask)![1]!);
        expect(minutes('${q.answer}'), times[0] + dur, reason: q.ask);
      }
    }
  });

  test('sound lessons ask only about their own sounds', () {
    final r = Rng.seeded(33);
    for (final (focus, sounds) in [('digraph:sh,th', {'sh', 'th'}), ('digraph:ch', {'ch'}), ('long:a,i', {'a', 'i'}), ('long:o,u', {'o', 'u'})]) {
      for (var i = 0; i < 100; i++) {
        expect(sounds, contains(enSounds(3, r, focus: focus).answer), reason: focus);
      }
    }
  });
}
