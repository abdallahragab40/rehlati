import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/settings/settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// الإعدادات بتتعدّل في مكانها — الزرار لازم يتحدّث على الشاشة فورًا.
void main() {
  testWidgets('settings switches and choices update when tapped', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(builder: (c) => TextButton(onPressed: () => showSettingsSheet(c), child: const Text('open'))),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    bool switchOf(String label) => tester
        .widget<Switch>(find.descendant(
            of: find.ancestor(of: find.text(label), matching: find.byType(Row)), matching: find.byType(Switch)))
        .value;

    expect(switchOf('🎵 أصوات اللعبة'), isTrue);
    await tester.tap(find.descendant(
        of: find.ancestor(of: find.text('🎵 أصوات اللعبة'), matching: find.byType(Row)), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(switchOf('🎵 أصوات اللعبة'), isFalse);

    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '123')).selected, isFalse);
    await tester.tap(find.text('123'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '123')).selected, isTrue);
  });
}
