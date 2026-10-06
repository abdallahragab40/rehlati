import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/game/visuals.dart';

void main() {
  test('no "listen and choose" questions while the voice is off', () {
    if (voiceEnabled) return;
    final r = Rng.seeded(1);
    for (final type in ['madd_types', 'madd_types:listen', 'madd_complete', 'madd_complete:listen']) {
      for (var i = 0; i < 200; i++) {
        final q = makeQuestion(type, 2, r, progress: ProgressData());
        expect(q.visuals.whereType<ListenVisual>(), isEmpty, reason: type);
      }
    }
  });

  testWidgets('tapping pictures counts them in order, crossed-out ones are skipped', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: VisualView(PicsVisual('🍎', 4, goneFrom: 3)))),
    ));
    await tester.pumpAndSettle();
    final apples = find.text('🍎');
    await tester.tap(apples.at(1));
    await tester.pump();
    await tester.tap(apples.at(0));
    await tester.pump();
    await tester.tap(apples.at(1)); // مرة تانية مابتتعدش
    await tester.tap(apples.at(3), warnIfMissed: false); // مشطوبة
    await tester.pumpAndSettle();
    expect(find.text('١'), findsOneWidget);
    expect(find.text('٢'), findsOneWidget);
    expect(find.text('٣'), findsNothing);
  });
}
