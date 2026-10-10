/// عناصر الواجهة المشتركة — زراير ثلاثية الأبعاد، كروت، الأسد، الفقاعة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion.dart';
import '../theme/app_theme.dart';
import '../ui_state.dart';

export '../ui_state.dart';

/// زرار "بيتداس" — ظل صلب تحته وبينزل لما الطفل يضغطه (زي .btn و .choice في الويب).
class Pressable3D extends StatefulWidget {
  const Pressable3D({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.paper,
    this.shadowColor = const Color(0x38000000),
    this.radius = 26,
    this.depth = 7,
    this.padding = EdgeInsets.zero,
    this.border,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final double radius;
  final double depth;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;
  final String? semanticLabel;

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.depth;
    final shift = _down ? d * .7 : 0.0;
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.only(bottom: d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            transform: Matrix4.translationValues(0, shift, 0),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(widget.radius),
              border: widget.border,
              boxShadow: [BoxShadow(color: widget.shadowColor, offset: Offset(0, d - shift))],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum BtnKind { primary, ghost, go, train }

/// زرار نصّي (.btn).
class KidButton extends StatelessWidget {
  const KidButton(this.label, {super.key, this.onTap, this.kind = BtnKind.primary});
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, sh) = switch (kind) {
      BtnKind.primary => (AppColors.grape, Colors.white, const Color(0x40000000)),
      BtnKind.ghost => (AppColors.paper, AppColors.ink, AppColors.shadow),
      BtnKind.go => (AppColors.grassDark, Colors.white, const Color(0x40000000)),
      BtnKind.train => (AppColors.coral, Colors.white, const Color(0x40000000)),
    };
    return Pressable3D(
      onTap: onTap,
      color: bg,
      shadowColor: sh,
      radius: 22,
      depth: 6,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(label, textAlign: TextAlign.center, style: kidText(context.clampVw(17, 4.4, 21), color: fg)),
    );
  }
}

/// زرار دائري صغير (.icon-btn).
class IconBubbleButton extends StatelessWidget {
  const IconBubbleButton(this.emoji, {super.key, required this.onTap, required this.label, this.size = 48});
  final String emoji;
  final VoidCallback onTap;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: size,
        depth: 4,
        shadowColor: AppColors.shadow,
        semanticLabel: label,
        child: SizedBox.square(dimension: size, child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24)))),
      );
}

/// كبسولة (.pill) — عدّاد النجوم وعنوان الشاشة.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.child, this.color = AppColors.paper});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 4))],
        ),
        child: DefaultTextStyle(style: kidText(context.clampVw(15, 3.6, 19)), child: child),
      );
}

/// خلفية السماء مع التل الأخضر تحت (زي body في الويب).
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SkyPainter(), child: child);
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sky1, AppColors.sky2, AppColors.sky2],
          stops: [0, .58, 1],
        ).createShader(r),
    );
    // radial-gradient(120% 70% at 50% 108%, grass 0 42%, transparent 43%)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s.width / 2, s.height * 1.08), width: s.width * 1.008, height: s.height * .588),
      Paint()..color = AppColors.grass,
    );
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => false;
}

/// الأسد صاحب الطفل — بيتنطط لما يجاوب صح وبيميل لما يغلط.
class LionMascot extends StatefulWidget {
  const LionMascot({super.key, this.mood = LionMood.idle, this.tick = 0, this.emoji = '🦁'});
  final LionMood mood;

  /// كل ما الرقم يتغير الحركة تتعاد.
  final int tick;
  final String emoji;

  @override
  State<LionMascot> createState() => _LionMascotState();
}

/// الأسد بيتلمس: بيتكمّش وينط ويطلّع قلب أو نجمة — لعبة صغيرة في أي وقت.
class _LionMascotState extends State<LionMascot> {
  static const _hearts = ['❤️', '⭐', '💛', '😄', '🎈', '💜'];
  int _pokes = 0;

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood, tick = widget.tick, emoji = widget.emoji;
    final size = context.clampVw(54, 14, 78);
    final lion = Text(emoji, style: TextStyle(fontSize: size, height: 1));
    final anim = switch (mood) {
      LionMood.cheer => lion
          .anim(key: ValueKey('c$tick'))
          .moveY(begin: 0, end: -26, duration: 190.ms, curve: Curves.easeOut)
          .scaleXY(begin: 1, end: 1.12, duration: 190.ms)
          .then()
          .moveY(begin: 0, end: 26, duration: 360.ms, curve: Curves.bounceOut)
          .scaleXY(begin: 1, end: 1 / 1.12, duration: 360.ms),
      LionMood.sad => lion
          .anim(key: ValueKey('s$tick'))
          .rotate(begin: 0, end: -.025, duration: 150.ms, alignment: const Alignment(0, .8))
          .then()
          .rotate(begin: 0, end: .045, duration: 175.ms, alignment: const Alignment(0, .8))
          .then()
          .rotate(begin: 0, end: -.02, duration: 175.ms, alignment: const Alignment(0, .8)),
      LionMood.idle => lion,
    };
    return ExcludeSemantics(
      child: Center(
        child: GestureDetector(
          onTap: _poke,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            anim
                // قبل أول لمسة الحركة واقفة على البداية (من غير تغيير) عشان شكل الشجرة مايتغيرش
                .anim(key: ValueKey('p$_pokes'), autoPlay: _pokes > 0)
                .scaleXY(begin: 1, end: .82, duration: 90.ms, alignment: Alignment.bottomCenter)
                .then()
                .scaleXY(begin: 1, end: 1 / .82, duration: 380.ms, curve: Curves.elasticOut, alignment: Alignment.bottomCenter)
                .moveY(begin: 0, end: -14, duration: 160.ms, curve: Curves.easeOut)
                .then()
                .moveY(begin: 0, end: 14, duration: 260.ms, curve: Curves.bounceOut),
            if (_pokes > 0)
              Positioned(
                top: -size * .3,
                child: Text(_hearts[_pokes % _hearts.length], style: TextStyle(fontSize: size * .45))
                    .anim(key: ValueKey('h$_pokes'))
                    .moveY(begin: 0, end: -size * .9, duration: 900.ms, curve: Curves.easeOut)
                    .scaleXY(begin: .4, end: 1.2, duration: 900.ms)
                    .fadeOut(delay: 400.ms, duration: 500.ms),
              ),
          ]),
        ),
      ),
    );
  }

  void _poke() => setState(() => _pokes++);
}

/// فقاعة الكلام تحت الأسد.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(this.text, {super.key, this.kind = BubbleKind.plain});
  final String text;
  final BubbleKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      BubbleKind.plain => (AppColors.paper, AppColors.ink),
      BubbleKind.ok => (AppColors.okBg, AppColors.okInk),
      BubbleKind.no => (AppColors.noBg, AppColors.noInk),
    };
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 5))],
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(16, 4.2, 20), weight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

/// الكارت الأبيض الكبير (.qcard) — بيظهر بنطّة وبيتهز لما [shakeTick] يتغير.
class QCard extends StatelessWidget {
  const QCard({super.key, required this.child, this.shakeTick = 0});
  final Widget child;
  final int shakeTick;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.clampVw(14, 4, 24),
        vertical: context.clampVw(16, 4, 26),
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 10))],
      ),
      child: child,
    );
    if (shakeTick == 0) {
      return card
          .anim()
          .fadeIn(duration: 250.ms)
          .slideY(begin: .08, end: 0, duration: 450.ms, curve: Curves.easeOutBack)
          .scaleXY(begin: .9, end: 1, duration: 450.ms, curve: Curves.easeOutBack);
    }
    return card.anim(key: ValueKey(shakeTick)).shakeX(hz: 5, amount: 9, duration: 400.ms);
  }
}

/// ملاحظة صفرا (.note).
class NoteBox extends StatelessWidget {
  const NoteBox(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.noteBg, borderRadius: BorderRadius.circular(18)),
        child: DefaultTextStyle(
          style: kidText(15, weight: FontWeight.w700, color: AppColors.noteInk, height: 1.5),
          child: child,
        ),
      );
}

/// اللافتة الكبيرة أعلى الشاشة (.banner).
class Banner3D extends StatelessWidget {
  const Banner3D(this.text, {super.key, this.color = AppColors.gold, this.tone = AppColors.goldDark, this.ink});
  final String text;
  final Color color;
  final Color tone;
  final Color? ink;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: tone, offset: const Offset(0, 7))],
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(26, 7, 42), color: ink ?? const Color(0xFF4A2B00), height: 1.3)),
      );
}

/// سطر الشرح تحت اللافتة (.hero p) — أبيض على السما.
class HeroText extends StatelessWidget {
  const HeroText(this.text, {super.key, this.size, this.align = TextAlign.center});
  final String text;
  final double? size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        style: kidText(size ?? context.clampVw(15, 4, 20), weight: FontWeight.w700, color: Colors.white).copyWith(
          shadows: const [Shadow(color: Color(0x381B3557), offset: Offset(0, 2))],
        ),
      );
}

/// شبكة كروت بعرض أدنى وارتفاع طبيعي — بدل GridView بنسبة ثابتة اللي بتقطع
/// النص لو خط الجهاز كبير.
class TileWrap extends StatelessWidget {
  const TileWrap({super.key, required this.minTileWidth, required this.children, this.spacing = 10, this.maxColumns = 6});
  final double minTileWidth;
  final double spacing;
  final int maxColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = ((box.maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
        final w = (box.maxWidth - spacing * (cols - 1)) / cols;
        // كل صف بارتفاع أطول كارت فيه عشان الكروت تبان متساوية
        return Column(children: [
          for (var r = 0; r < children.length; r += cols)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : spacing),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = r; i < r + cols && i < children.length; i++) ...[
                    if (i > r) SizedBox(width: spacing),
                    SizedBox(width: w, child: children[i]),
                  ],
                ]),
              ),
            ),
        ]);
      });
}
