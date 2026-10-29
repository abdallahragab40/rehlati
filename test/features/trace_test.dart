import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/features/game/play_modes.dart';

import '../domain/engine_test.dart' show makeContainer;

/// ارسم بصباعك: المسح فوق الشكل كله بينجح، والشخبطة برّه الشكل بتتمسح وتتحسب محاولة.
void main() {
  Future<GameSession> pumpTrace(WidgetTester tester, ProviderContainer c) async {
    final keys = <String, GlobalKey>{};
    c.read(gameProvider.notifier).start('traceNum');
    final s = c.read(gameProvider)!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Consumer(
                builder: (_, ref, _) => TraceGame(
                  s: ref.watch(gameProvider)!,
                  engine: ref.read(gameProvider.notifier),
                  keyFor: (a) => keys.putIfAbsent(a, GlobalKey.new),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    // القناع بيتحسب من صورة (toByteData) — محتاج وقت حقيقي
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    return s;
  }

  testWidgets('scribbling over the whole shape finishes the drawing', (tester) async {
    final c = await makeContainer();
    final s = await pumpTrace(tester, c);
    final board = tester.getRect(find.byType(GestureDetector).first);
    // صفوف متقاربة من فوق لتحت على اللوحة كلها: بتغطّي الشكل، وأغلبها فوقه أو جنبه
    final g = await tester.startGesture(board.topLeft + Offset(board.width * .25, board.height * .12));
    for (var y = .12; y <= .88; y += .03) {
      for (var x = .25; x <= .75; x += .05) {
        await g.moveTo(board.topLeft + Offset(board.width * x, board.height * y));
      }
    }
    await g.up();
    await tester.pump();
    expect(s.locked, isTrue);
    expect(s.tries, 0);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a long line far from the shape is a gentle retry and clears the board', (tester) async {
    final c = await makeContainer();
    final s = await pumpTrace(tester, c);
    final board = tester.getRect(find.byType(GestureDetector).first);
    final g = await tester.startGesture(board.topLeft + const Offset(4, 4));
    for (var i = 0; i < 40; i++) {
      await g.moveTo(board.topLeft + Offset(4 + i * 6.0, 6));
    }
    await g.up();
    await tester.pump();
    expect(s.locked, isFalse);
    expect(s.tries, 1);
    expect(s.traceTick, 1);
    await tester.pump(const Duration(seconds: 1));
  });
}
