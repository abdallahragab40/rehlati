import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/widgets/kid_widgets.dart';
import 'package:rehlati/domain/progress/progress_data.dart';

/// شكل الكبار: تلقائي من سن ٩، وولي الأمر يغيّره، والأسد بيستخبى.
void main() {
  test('on automatically from age 9, and the parent choice wins either way', () {
    expect([for (final a in [null, 4, 8, 9, 12]) ProgressData(age: a).grownUpLook], [false, false, false, true, true]);
    expect((ProgressData(age: 12)..settings.grownUp = false).grownUpLook, isFalse);
    expect((ProgressData(age: 6)..settings.grownUp = true).grownUpLook, isTrue);
    expect(Settings.fromJson((Settings()..grownUp = true).toJson()).grownUp, isTrue);
    expect(Settings().toJson().containsKey('grownUp'), isFalse, reason: 'old settings stay unchanged');
    expect(Settings.fromJson({}).grownUp, isNull);
  });

  testWidgets('the lion hides in the grown-up look but stays in the tree for effects', (tester) async {
    Future<void> pump(bool on) => tester.pumpWidget(Directionality(
          textDirection: TextDirection.rtl,
          child: GrownUpLook(on: on, child: const Center(child: LionMascot())),
        ));
    await pump(false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('🦁'), findsOneWidget);
    await pump(true);
    expect(find.text('🦁'), findsNothing);
    expect(find.byType(LionMascot), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
  });
}
