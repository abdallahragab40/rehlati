// يرسم أيقونة التطبيق من رسومات التطبيق نفسه (السما، التلال، الشمس) + حرف «ر» بخط Baloo.
//
//   flutter test tool/render_icon_test.dart
//
// بيطلع assets/icon/icon.png (١٠٢٤ — iOS والمتاجر) و icon_fg.png (الطبقة الأمامية لأيقونة أندرويد المتكيّفة).
// بعدها: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/theme/app_theme.dart';
import 'package:rehlati/features/scenes/art.dart';

const size = 1024.0;

Future<void> _loadFont() async {
  final loader = FontLoader('Baloo')
    ..addFont(rootBundle.load('assets/fonts/BalooBhaijaan2-ExtraBold.ttf'));
  await loader.load();
}

/// الحرف والنجمة — مشتركين بين الأيقونة الكاملة والطبقة الأمامية.
Widget _mark(double s) => Stack(alignment: Alignment.center, children: [
      Transform.translate(
        offset: Offset(0, -s * .02),
        child: Text(
          'ر',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Baloo',
            fontWeight: FontWeight.w800,
            fontSize: s * .62,
            height: 1,
            color: AppColors.grape,
            // ظل صلب تحت زي اللافتات في التطبيق
            shadows: [Shadow(color: const Color(0xFF5B3FD6), offset: Offset(0, s * .025))],
          ),
        ),
      ),
      Positioned(
        right: s * .2,
        top: s * .2,
        child: Icon(Icons.star_rounded, size: s * .16, color: AppColors.gold, shadows: [
          Shadow(color: AppColors.goldDark, offset: Offset(0, s * .008)),
        ]),
      ),
    ]);

Widget _full() => SizedBox.square(
      dimension: size,
      child: Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.sky1, AppColors.sky2],
              ),
            ),
          ),
        ),
        Positioned(left: size * .07, top: size * .07, child: ArtBox(painter: SunPainter(0), width: size * .26)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size * .3,
          child: CustomPaint(painter: HillsPainter(const Color(0xFF63C96A), const Color(0xFF8ADB7E))),
        ),
        Positioned.fill(child: _mark(size)),
      ]),
    );

/// أندرويد بيقص الأيقونة المتكيّفة لدايرة أو مربّع — المحتوى لازم يفضل في النص (٦٦٪).
Widget _foreground() => SizedBox.square(
      dimension: size,
      child: Center(child: SizedBox.square(dimension: size * .8, child: _mark(size * .8))),
    );

Future<void> _render(WidgetTester tester, Widget w, String path) async {
  final key = GlobalKey();
  tester.view
    ..physicalSize = const Size(size, size)
    ..devicePixelRatio = 1;
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.rtl,
    child: Center(child: RepaintBoundary(key: key, child: w)),
  ));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('render app icon', (tester) async {
    await tester.runAsync(_loadFont);
    // أيقونات Material (النجمة) محتاجة الخط بتاعها في الاختبار
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    await _render(tester, _full(), 'assets/icon/icon.png');
    await _render(tester, _foreground(), 'assets/icon/icon_fg.png');
    addTearDown(tester.view.reset);
  });
}
