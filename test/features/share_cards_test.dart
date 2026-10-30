import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rehlati/domain/certificates.dart';
import 'package:rehlati/domain/paths.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/features/parent/share_cards.dart';
import 'package:rehlati/features/parent/worksheet_card.dart';

void main() {
  test('a memorized surah earns a certificate, a listened one does not', () {
    final p = ProgressData()
      ..quranMark(112, 'memorize', 1)
      ..quranMark(113, 'listen', 1);
    final certs = certificates(p, {112: 'سُورَةُ الإِخۡلَاصِ'});
    expect(certs.map((c) => c.id), ['surah:112']);
    expect(certs.single.title, 'حفظ سُورَةُ الإِخۡلَاصِ');
  });

  test('surah titles add "سورة" only when the source left it out', () {
    expect(surahTitle(112, 'الإخلاص'), 'سورة الإخلاص');
    expect(surahTitle(112, 'سُورَةُ الإِخۡلَاصِ'), 'سُورَةُ الإِخۡلَاصِ');
    expect(surahTitle(112, null), 'السورة رقم ١١٢');
  });

  test('a finished learning path earns a certificate', () {
    final p = ProgressData();
    final path = learningPaths.first;
    for (final l in path.lessons) {
      for (final s in l.stages) {
        p.pathDone.putIfAbsent(path.id, () => {}).add('${l.id}:$s');
      }
    }
    expect(certificates(p, const {}).map((c) => c.id), ['path:${path.id}']);
  });

  test('worksheet pages become one A4 page each in a PDF', () async {
    final png = img.encodePng(img.Image(width: 20, height: 28));
    final pdf = String.fromCharCodes(await pagesToPdf([png, png]));
    expect(pdf, startsWith('%PDF'));
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(pdf), hasLength(2));
  });

  test('long dates read in Arabic', () {
    expect(fmtLongDate(DateTime(2026, 10, 30)), '٣٠ أكتوبر ٢٠٢٦');
  });

  Future<void> pumpImage(WidgetTester tester, Widget card) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 900 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: shareWidth, child: card))),
    ));
  }

  testWidgets('the weekly report image lays out with a busy week', (tester) async {
    final p = ProgressData(name: 'عبدالرحمن محمد')
      ..quranMark(112, 'memorize', 1)
      ..quranMark(113, 'memorize', 1);
    for (var i = 0; i < 6; i++) {
      p.miss('add', 'add:7+$i');
      p.miss('add', 'add:7+$i');
    }
    await pumpImage(tester, WeekReportImage(p: p, surahNames: const {112: 'الإخلاص'}, today: DateTime(2026, 10, 30)));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('تقرير عبدالرحمن محمد'), findsOneWidget);
    expect(find.textContaining('حفظ سورتين'), findsOneWidget);
  });

  testWidgets('the certificate image shows the name and the achievement', (tester) async {
    await pumpImage(
      tester,
      CertificateImage(
        name: 'مريم',
        cert: const Certificate('surah:112', '📖', 'حفظ سورة الإخلاص'),
        date: DateTime(2026, 10, 30),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('مريم'), findsOneWidget);
    expect(find.text('📖 حفظ سورة الإخلاص'), findsOneWidget);
  });
}
