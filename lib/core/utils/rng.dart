import 'dart:math';

/// عشوائية قابلة للحقن — في الاختبارات بنمرّر seed ثابت عشان النتايج تتكرر.
class Rng {
  Rng([Random? random]) : _r = random ?? Random();
  Rng.seeded(int seed) : _r = Random(seed);

  final Random _r;

  /// رقم صحيح بين a و b شاملين الطرفين.
  int rnd(int a, int b) => _r.nextInt(b - a + 1) + a;

  double next() => _r.nextDouble();

  bool chance(double p) => _r.nextDouble() < p;

  T sample<T>(List<T> list) => list[rnd(0, list.length - 1)];

  /// خلط في نفس المكان (Fisher–Yates) وبيرجّع نفس القائمة.
  List<T> shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = rnd(0, i);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
    return list;
  }

  /// اختيارات رقمية فريدة حول الإجابة وداخل حدود المستوى.
  List<int> numberChoices(int answer, int count, int min, int max) {
    final set = <int>{answer};
    var guard = 0;
    while (set.length < count && guard++ < 80) {
      final c = answer + sample<int>(const [-3, -2, -1, 1, 2, 3]);
      if (c >= min && c <= max) set.add(c);
    }
    var v = min;
    while (set.length < count && v <= max) {
      set.add(v++);
    }
    return shuffle(set.toList());
  }

  /// اختيارات نصية فريدة حول الإجابة.
  List<String> textChoices(String answer, List<String> pool, int count) {
    final set = <String>{answer};
    var guard = 0;
    while (set.length < count && guard++ < 60) {
      set.add(sample(pool));
    }
    return shuffle(set.toList());
  }
}
