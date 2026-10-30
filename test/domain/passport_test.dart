import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/certificates.dart';
import 'package:rehlati/domain/passport.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  test('a new child has an empty passport with a page for every world', () {
    final p = ProgressData();
    expect(passport(p).map((x) => x.world.id), [for (final w in worlds) w.id]);
    expect(stampCount(p), 0);
    expect(stampTotal, worlds.length * 3);
  });

  test('stamps follow the world progress, and mastering a world earns a certificate', () {
    final p = ProgressData();
    final math = worldStages['math']!;
    p.best[math.first.id] = 1;
    expect(passport(p).firstWhere((x) => x.world.id == 'math').stamps, 1);

    for (final s in math) {
      p.best[s.id] = 3;
    }
    expect(passport(p).firstWhere((x) => x.world.id == 'math').stamps, 3);
    expect(certificates(p, const {}).map((c) => c.id), contains('world:math'));
    expect(certificates(p, const {}).firstWhere((c) => c.id == 'world:math').title, 'إتقان عالم الحساب');
  });
}
