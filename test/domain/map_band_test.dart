import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

/// خريطة العربي والحساب و English على قد صف الطفل: صفه الأول، واللي فات مراجعة، والأعلى ورا زرار.
void main() {
  List<Stage> band(String world, String? grade, MapBand b) => [for (final s in worldStages[world]!) if (mapBand(s, grade) == b) s];

  test('from grade 2 up, every subject opens on stages for the child, never an empty map', () {
    for (final world in ['arabic', 'math', 'english']) {
      for (final grade in ['p2', 'p3', 'p4', 'p5', 'p6']) {
        expect(band(world, grade, MapBand.now), isNotEmpty, reason: '$world $grade');
        expect(band(world, grade, MapBand.review), isNotEmpty, reason: '$world $grade has earlier grades to review');
      }
    }
  });

  test('a new child can open the first stage of every group shown for their grade, without the review stages', () {
    for (final grade in ['p2', 'p3', 'p4', 'p5', 'p6']) {
      final p = ProgressData(grade: grade);
      for (final world in ['arabic', 'math', 'english']) {
        final now = band(world, grade, MapBand.now);
        final ids = {for (final s in now) s.id};
        for (final group in {for (final s in now) s.group}) {
          final first = now.firstWhere((s) => s.group == group);
          expect(p.isUnlocked(first.id) || ids.contains(first.after), isTrue, reason: '$grade $world ${first.name}');
        }
      }
    }
  });

  test('a grade 5 child opening Arabic starts with grade 5, and the letters are in review', () {
    final now = band('arabic', 'p5', MapBand.now);
    expect(now.first.name, 'المفعول به');
    expect(now.every((s) => stageShownFrom(s) == 'p5'), isTrue);
    expect(band('arabic', 'p5', MapBand.review).map((s) => s.name), contains('تعرّف على الحروف'));
    expect(band('arabic', 'p5', MapBand.higher).every((s) => stageShownFrom(s) == 'p6'), isTrue);
  });

  test('a subject with no stages of its own for the grade uses the nearest grade below', () {
    expect(mapGradeFor('arabic', 'p3'), 'p2');
    expect(mapGradeFor('english', 'p2'), 'p1');
    expect(band('arabic', 'p3', MapBand.now).every((s) => stageShownFrom(s) == 'p2'), isTrue);
  });

  test('KG and grade 1 still see everything up to their grade, with nothing set aside for review', () {
    for (final grade in [null, 'kg1', 'kg2', 'p1']) {
      for (final world in ['arabic', 'math', 'english']) {
        expect(mapGradeFor(world, grade), isNull, reason: '$world $grade');
        expect(band(world, grade, MapBand.review), isEmpty, reason: '$world $grade');
      }
    }
    expect(band('arabic', 'p1', MapBand.now).first.name, 'تعرّف على الحروف');
  });

  test('the home tile describes what the child will see first', () {
    expect(worldDescFor(worldMeta('arabic'), 'p5'), isNot(contains('الحروف')));
    expect(worldDescFor(worldMeta('arabic'), 'p1'), worldMeta('arabic').desc);
    expect(worldDescFor(worldMeta('math'), 'p6'), contains('الجبر'));
    expect(worldDescFor(worldMeta('games'), 'p6'), worldMeta('games').desc);
  });
}
