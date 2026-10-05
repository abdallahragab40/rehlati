import 'package:flutter/material.dart';

/// خانة بحدود متقطّعة (border-style: dashed) — Flutter مالوش ده جاهز.
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.color = const Color(0x241B3557),
    this.width = 4,
    this.radius = 22,
    this.dash = 8,
    this.gap = 6,
    this.padding = EdgeInsets.zero,
    this.constraints,
  });

  final Widget child;
  final Color color;
  final double width;
  final double radius;
  final double dash;
  final double gap;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(color, width, radius, dash, gap),
        child: Container(constraints: constraints, padding: padding, child: child),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.width, this.radius, this.dash, this.gap);
  final Color color;
  final double width, radius, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(width / 2), Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.width != width;
}
