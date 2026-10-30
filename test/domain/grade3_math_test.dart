import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade3_math_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

int _num(String s) => int.parse(s.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join());

void main() {
  final gens = {'thousands': thousands, 'areaPerimeter': areaPerimeter, 'mulStrategies': mulStrategies, 'dotPlot': dotPlot};

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 300; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.choices, contains(q.answer), reason: '${q.ask} ${q.choices}');
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.ask} ${q.choices}');
          expect(q.choices.length, greaterThanOrEqualTo(2));
        }
      }
    });
  }

  test('thousands: the place digit is the right one, and the size follows the level', () {
    final r = Rng.seeded(1);
    for (var lv = 1; lv <= 3; lv++) {
      for (var i = 0; i < 200; i++) {
        final q = thousands(lv, r);
        if (!q.ask.startsWith('الرقم اللي في خانة')) continue;
        final n = _num((q.visuals.single as BigLetterVisual).text);
        expect('$n'.length, lv + 3);
        const places = ['الآحاد', 'العشرات', 'المئات', 'آحاد الألوف', 'عشرات الألوف', 'مئات الألوف'];
        final i0 = places.indexWhere((p) => q.ask == 'الرقم اللي في خانة $p كام؟');
        expect(q.answer, '$n'.split('').reversed.map(int.parse).toList()[i0], reason: '$n ${q.ask}');
      }
    }
  });

  test('area counts the squares and perimeter adds the sides', () {
    final r = Rng.seeded(2);
    for (var i = 0; i < 300; i++) {
      final q = areaPerimeter(3, r);
      final v = q.visuals.single as GridAreaVisual;
      if (q.ask.contains('عرضه')) continue;
      if (q.skill == 'ap:area') expect(q.answer, v.cells.length);
      if (q.skill == 'ap:perimeter') expect(q.answer, 2 * (v.cols + v.rows));
      expect(v.cells.every((c) => c.$1 < v.cols && c.$2 < v.rows), isTrue);
    }
    expect(areaPerimeter(1, Rng.seeded(3), focus: 'perimeter').skill, 'ap:perimeter');
  });

  test('multiplication strategies follow their focus', () {
    final r = Rng.seeded(4);
    for (final f in ['tens', 'estimate']) {
      expect(mulStrategies(2, r, focus: f).skill, 'mul:$f');
    }
    expect(mulStrategies(2, r, focus: 'props').skill, anyOf('mul:distributive', 'mul:associative'));
  });

  test('dot plot: one column has the most dots', () {
    final r = Rng.seeded(5);
    for (var i = 0; i < 300; i++) {
      final v = dotPlot(2, r).visuals.whereType<DotPlotVisual>().single;
      final top = v.rows.map((x) => x.$2).reduce((a, b) => a > b ? a : b);
      expect(v.rows.where((x) => x.$2 == top), hasLength(1));
    }
  });

  test('grade 3 maths opens from existing progress', () {
    expect(ProgressData(best: {'times2510': 2}).isUnlocked('thousands'), isTrue);
  });
}
