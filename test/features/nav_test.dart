import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/nav.dart';

void main() {
  test('back without history goes to the parent screen', () {
    expect(parentRoute('/play/counting'), '/world/math');
    expect(parentRoute('/play/ar_pick'), '/world/arabic');
    expect(parentRoute('/learn/en_learn'), '/world/english');
    expect(parentRoute('/madd/madd_alif'), '/world/arabic');
    expect(parentRoute('/world/math'), '/');
    expect(parentRoute('/quran/112/listen'), '/quran/112');
    expect(parentRoute('/quran/112'), '/quran');
    expect(parentRoute('/quran'), '/');
    expect(parentRoute('/pg/b/hit'), '/pg');
    expect(parentRoute('/pg/play'), '/pg/kids');
    expect(parentRoute('/guide'), '/parent');
    expect(parentRoute('/parent'), '/');
    expect(parentRoute('/play/unknown'), '/');
  });

  testWidgets('back works on a screen opened without history', (tester) async {
    final router = GoRouter(initialLocation: '/play/counting', routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(path: '/world/:id', builder: (c, s) => TextButton(onPressed: c.back, child: Text('map ${s.pathParameters['id']}'))),
      GoRoute(path: '/play/:stage', builder: (c, _) => TextButton(onPressed: c.back, child: const Text('game'))),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('game'));
    await tester.pumpAndSettle();
    expect(find.text('map math'), findsOneWidget);
    await tester.tap(find.text('map math'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
