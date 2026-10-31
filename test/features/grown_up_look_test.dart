import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/widgets/kid_widgets.dart';
import 'package:rehlati/domain/progress/progress_data.dart';

/// شكل الكبار: تلقائي من رابعة ابتدائي، وولي الأمر يغيّره، والأسد بيستخبى.
void main() {
  test('on automatically from grade 4, and the parent choice wins either way', () {
    expect([for (final g in [null, 'kg1', 'p3', 'p4', 'p6']) ProgressData(grade: g).grownUpLook], [false, false, false, true, true]);
    expect((ProgressData(grade: 'p6')..settings.grownUp = false).grownUpLook, isFalse);
    expect((ProgressData(grade: 'p1')..settings.grownUp = true).grownUpLook, isTrue);
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
