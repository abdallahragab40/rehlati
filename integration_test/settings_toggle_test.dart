import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rehlati/main.dart' as app;

/// التطبيق الحقيقي على جهاز: زرار الإعدادات لازم يتقلب لما يتلمس.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings switch flips in the real app', (tester) async {
    await app.main();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('⚙️').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final sw = find.descendant(
        of: find.ancestor(of: find.text('🎵 أصوات اللعبة'), matching: find.byType(Row)), matching: find.byType(Switch));
    final before = tester.widget<Switch>(sw).value;
    await tester.tap(sw);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final after = tester.widget<Switch>(sw).value;
    debugPrint('SWITCH before=$before after=$after');
    expect(after, !before);
  });
}
