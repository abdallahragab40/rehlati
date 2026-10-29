import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/features/game/modes.dart';

void main() {
  testWidgets('RTL fraction choices stack numerator above denominator with a spoken label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Center(child: SizedBox(width: 320, child: ChoiceTile(
            label: '3/4', semanticLabel: 'تلاتة على أربعة', color: Colors.blue,
            onTap: () {}, content: const FractionChoice('3/4'),
          )))),
        ),
      ),
    ));
    expect(tester.getTopLeft(find.text('٣')).dy, lessThan(tester.getTopLeft(find.text('٤')).dy));
    expect(find.bySemanticsLabel('تلاتة على أربعة'), findsOneWidget);
    expect(find.text('3/4'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
