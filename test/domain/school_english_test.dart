import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {
    'en_prep': enPrep, 'en_days': enDaysGame, 'en_months': enMonthsGame, 'en_feelings': enFeelingsGame,
    'en_weather': enWeatherGame, 'en_seasons': enSeasonsGame, 'en_rooms': enRoomsGame, 'en_places': enPlacesGame,
    'en_transport': enTransportGame, 'en_clothes': enClothesGame, 'en_sports': enSportsGame,
  };

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.isEnglish, isTrue);
          expect(q.choices, contains(q.answer), reason: q.ask);
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.choices}');
          expect(q.choices.length, greaterThanOrEqualTo(2));
        }
      }
    });
  }

  test('days and months wrap around, and the week starts on Saturday', () {
    expect(enDays.first, 'Saturday');
    expect(enDaysGame(1, Rng.seeded(1), focus: 'Friday').answer, 'Saturday');
    final before = [for (var i = 0; i < 40; i++) enMonthsGame(2, Rng.seeded(i), focus: 'January')]
        .where((q) => q.ask.contains('before'));
    expect(before.first.answer, 'December');
  });

  test('in, on and under only go with places where they make sense', () {
    final r = Rng.seeded(3);
    for (var i = 0; i < 300; i++) {
      final q = enPrep(3, r);
      final v = q.visuals.single as PrepVisual;
      final place = prepPlaces.firstWhere((p) => p.$1 == v.place);
      expect(place.$3, contains(v.prep));
      expect('${q.answer}', anyOf(v.prep, contains(' ${v.prep} the ${place.$2}.')));
    }
  });

  test('English stages are unlocked for children who already passed My family', () {
    expect(ProgressData(best: {'en_family': 2}).isUnlocked('en_prep'), isTrue);
  });
}
