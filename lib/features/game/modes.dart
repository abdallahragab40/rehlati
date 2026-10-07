/// واجهات أوضاع الأسئلة الستة: اختيار، ترتيب، جدول، توصيل، دوائر، ذاكرة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/features.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/dashed_box.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/question.dart';
import '../madd/madd_style.dart';
import 'games_modes.dart';
import 'visuals.dart';

typedef KeyFor = GlobalKey Function(String anchor);

enum TileSize { number, text, wide, pair, pairText, madd, maddWide }

/// زرار الإجابة (.choice) بكل حالاته: صح، غلط، تلميح، مستخدم، متحدد، متوصّل.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
    this.size = TileSize.number,
    this.right = false,
    this.wrongTick,
    this.hint = false,
    this.used = false,
    this.selected = false,
    this.matched = false,
    this.content,
  });

  final String label;

  /// بدل النص: شكل أو صورة بحجم (عالم الألعاب).
  final Widget? content;
  final Color color;
  final VoidCallback? onTap;
  final TileSize size;
  final bool right;

  /// لو مش null الزرار أحمر وبيتهز (والرقم بيعيد الحركة).
  final int? wrongTick;
  final bool hint;
  final bool used;
  final bool selected;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final (minW, minH, font, padH) = switch (size) {
      TileSize.number => (context.clampVw(86, 24, 120), context.clampVw(86, 24, 112), context.clampVw(38, 11, 54), 8.0),
      TileSize.text => (context.clampVw(86, 24, 120), context.clampVw(86, 24, 112), context.clampVw(22, 5.6, 30), 18.0),
      TileSize.wide => (double.infinity, 66.0, context.clampVw(22, 5.6, 30), 18.0),
      TileSize.pair => (context.clampVw(74, 19, 96), context.clampVw(60, 15, 76), context.clampVw(28, 8, 40), 8.0),
      TileSize.pairText => (context.clampVw(120, 34, 190), 62.0, context.clampVw(20, 5, 27), 12.0),
      // مقاطع وكلمات مشكولة: خط كبير (.choice.mbig)
      TileSize.madd => (context.clampVw(92, 26, 130), context.clampVw(86, 24, 112), context.clampVw(40, 11, 58), 16.0),
      TileSize.maddWide => (double.infinity, 84.0, context.clampVw(40, 11, 58), 16.0),
    };
    final wrong = wrongTick != null;
    Widget tile = Pressable3D(
      onTap: (used || matched) ? null : onTap,
      color: wrong ? AppColors.coral : color,
      radius: 26,
      depth: matched ? 2 : 7,
      border: selected ? Border.all(color: AppColors.gold, width: 6) : null,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minW.isInfinite ? 0 : minW, minHeight: minH),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: 6),
          child: Center(
            widthFactor: minW.isInfinite ? null : 1,
            child: ExcludeSemantics(
              child: content ??
                  Text(
                    ar(label),
                    textAlign: TextAlign.center,
                    style: kidText(font, color: Colors.white, height: 1.2)
                        .copyWith(shadows: const [Shadow(color: Color(0x2E000000), offset: Offset(0, 2))]),
                  ),
            ),
          ),
        ),
      ),
    );
    if (minW.isInfinite) tile = SizedBox(width: double.infinity, child: tile);
    if (used) return Opacity(opacity: .25, child: tile);
    if (matched) return Opacity(opacity: .35, child: tile);
    if (selected) return Transform.translate(offset: const Offset(0, 3), child: tile);
    if (wrong) return tile.animate(key: ValueKey('w$wrongTick')).shakeX(hz: 5, amount: 9, duration: 400.ms);
    if (right) return tile.animate(key: const ValueKey('right')).scaleXY(begin: 1, end: 1.18, duration: 200.ms).then().scaleXY(begin: 1, end: 1 / 1.18, duration: 250.ms);
    if (hint) {
      return tile.animate(onPlay: (c) => c.repeat(reverse: true)).custom(
            duration: 500.ms,
            builder: (_, v, child) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .6 * v), spreadRadius: 10 * v)],
              ),
              child: child,
            ),
          );
    }
    return tile;
  }
}

/// عنوان السؤال + زرار 🔊.
class AskRow extends StatelessWidget {
  const AskRow({super.key, required this.q, required this.onSpeak});
  final Question q;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Directionality(
                textDirection: q.ltr ? TextDirection.ltr : TextDirection.rtl,
                child: Text(q.ask, textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30), height: 1.35)),
              ),
            ),
            const SizedBox(width: 10),
            if (voiceEnabled) _SpeakButton(onSpeak),
          ],
        ),
      );
}

class _SpeakButton extends StatefulWidget {
  const _SpeakButton(this.onTap);
  final VoidCallback onTap;

  @override
  State<_SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<_SpeakButton> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'اسمع السؤال تاني',
        child: GestureDetector(
          onTap: () {
            setState(() => _tick++);
            widget.onTap();
          },
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 3),
            ),
            child: const Text('🔊', style: TextStyle(fontSize: 24)),
          ).animate(key: ValueKey(_tick)).shake(hz: 3, rotation: .2, duration: _tick == 0 ? 1.ms : 600.ms),
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      );
}

/// جسم السؤال حسب الوضع.
class QuestionBody extends StatelessWidget {
  const QuestionBody({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  Question get q => s.q;
  Color get color => s.stage.color;

  bool _isHint(Object v) => s.hintTarget != null && v == s.hintTarget;
  int? _wrong(String a) => s.wrongAnchor == a ? s.wrongTick : null;

  @override
  Widget build(BuildContext context) {
    final dir = q.ltr ? TextDirection.ltr : TextDirection.rtl;
    // بعد الإجابة الصح بعض أسئلة المدود بتكشف المقطع بحرف المد ملوّن
    final shown = s.revealed && q.revealVisuals != null ? q.revealVisuals! : q.visuals;
    final visuals = [
      for (final v in shown) VisualView(v, ltr: q.ltr, picked: s.picked),
    ];
    final body = switch (q.mode) {
      QMode.choice => _choices(context),
      QMode.order => Column(children: [
          // لو الخانات جوه التعبير نفسه (السابق والتالي) مفيش داعي لصف خانات تاني
          if (!q.visuals.any((v) => v is ExprVisual && v.fillFromPicked)) _slots(context),
          _Hint(q.orderHint ?? 'اضغط الأرقام بالترتيب'),
          _bank(context),
        ]),
      QMode.grid => Column(children: [
          _Hint(q.orderHint ?? (q.isEnglish ? 'Tap the missing letter' : (q.numeric ? 'اضغط الرقم الناقص' : 'اضغط الحرف الناقص'))),
          _bank(context),
        ]),
      QMode.pairs => Column(children: [_Hint(q.hint), _pairs(context)]),
      QMode.find => Column(children: [_Hint(q.hint), _find(context)]),
      QMode.memory => Column(children: [_Hint(q.hint), _memory(context)]),
      QMode.read => Column(children: [
          _Hint(q.hint),
          KidButton(q.yes ?? 'نعم ⭐', kind: BtnKind.go, onTap: s.locked ? null : engine.readDone),
        ]),
      QMode.sort => _sort(context),
      QMode.balloon => Column(children: [_Hint(q.hint), BalloonSky(s: s, engine: engine, keyFor: keyFor)]),
      QMode.color => ColorGame(s: s, engine: engine, keyFor: keyFor),
      QMode.rhythm => RhythmGame(s: s, engine: engine, keyFor: keyFor),
    };
    return Column(children: [
      AskRow(q: q, onSpeak: engine.repeat),
      ...visuals,
      Directionality(textDirection: dir, child: body),
    ]);
  }

  Widget _choices(BuildContext context) {
    final wide = q.wide;
    final tiles = [
      for (var i = 0; i < q.choices.length; i++)
        KeyedSubtree(
          key: keyFor('c$i'),
          child: ChoiceTile(
            label: '${q.choices[i]}',
            content: q.look == ChoiceLook.shape ? ShapeIcon('${q.choices[i]}', size: context.clampVw(44, 12, 62)) : null,
            color: color,
            size: q.bigChoices
                ? (wide ? TileSize.maddWide : TileSize.madd)
                : wide
                    ? TileSize.wide
                    : ('${q.choices[i]}'.characters.length > 1 && q.choices[i] is String ? TileSize.text : TileSize.number),
            onTap: s.locked ? null : () => engine.answer(i),
            right: s.rightAnchor == 'c$i',
            wrongTick: _wrong('c$i'),
            hint: _isHint(q.choices[i]),
          ),
        )
            // الاختيارات بتنط واحدة ورا التانية مع كل سؤال جديد
            .animate()
            .scaleXY(delay: (180 + i * 80).ms, begin: .4, end: 1, duration: 420.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
    ];
    if (wide) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(children: [for (final t in tiles) Padding(padding: const EdgeInsets.only(bottom: 10), child: t)]),
      );
    }
    final gap = context.clampVw(10, 3, 18);
    return Wrap(alignment: WrapAlignment.center, spacing: gap, runSpacing: gap, children: tiles);
  }

  Widget _slots(BuildContext context) {
    final n = q.answerList.length;
    final size = context.clampVw(62, 16, 86);
    final font = kidText(context.clampVw(32, 9, 46));
    Widget slot(int k) {
      if (k < s.picked.length) {
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(22)),
          child: q.sizePic == null
              ? Text(ar(s.picked[k]), style: font.copyWith(color: Colors.white))
              : FittedBox(child: _sized('${s.picked[k]}', context)),
        ).animate().scaleXY(begin: 1.18, end: 1, duration: 300.ms);
      }
      final box = DashedBox(
        color: k == s.picked.length ? AppColors.grape : AppColors.line,
        child: SizedBox.square(dimension: size - 8),
      );
      return k == s.picked.length
          ? box.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.08, duration: 650.ms)
          : box;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Directionality(
        textDirection: q.rtlSlots ? TextDirection.rtl : TextDirection.ltr,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: context.clampVw(8, 2.4, 14),
          runSpacing: 10,
          children: [for (var k = 0; k < n; k++) slot(k)],
        ),
      ),
    );
  }

  /// رتّب بالحجم: الصورة بحجمها النسبي ('1'، '1.55'…).
  Widget _sized(String factor, BuildContext context) =>
      Text(q.sizePic!, style: TextStyle(fontSize: context.clampVw(18, 5, 24) * double.parse(factor), height: 1.1));

  Widget _bank(BuildContext context) {
    final gap = context.clampVw(10, 3, 18);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (var i = 0; i < q.items.length; i++)
          KeyedSubtree(
            key: keyFor('i$i'),
            child: ChoiceTile(
              label: '${q.items[i]}',
              content: q.sizePic == null ? null : _sized('${q.items[i]}', context),
              color: color,
              size: q.bigChoices ? TileSize.madd : (q.numeric ? TileSize.number : TileSize.text),
              onTap: s.locked ? null : () => engine.pick(i),
              used: s.used.contains(i),
              wrongTick: _wrong('i$i'),
              hint: !s.used.contains(i) && _isHint(q.items[i]),
            ),
          ),
      ],
    );
  }

  Widget _pairs(BuildContext context) {
    final size = q.wide ? TileSize.pairText : TileSize.pair;
    Widget col(List<Widget> c) => Column(
          crossAxisAlignment: q.wide ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [for (final w in c) Padding(padding: const EdgeInsets.only(bottom: 10), child: w)],
        );
    final left = col([
      for (var i = 0; i < q.items.length; i++)
        KeyedSubtree(
          key: keyFor('l$i'),
          child: ChoiceTile(
            label: '${q.items[i]}',
            color: color,
            size: size,
            onTap: () => engine.pairPick(left: true, i: i),
            selected: s.sel == i,
            matched: s.matchedLeft.contains(i),
          ),
        ),
    ]);
    final right = col([
      for (var i = 0; i < q.right.length; i++)
        KeyedSubtree(
          key: keyFor('r$i'),
          child: ChoiceTile(
            label: q.right[i],
            color: const Color(0xFF8FB9E8),
            size: size,
            onTap: () => engine.pairPick(left: false, i: i),
            matched: s.matchedRight.contains(i),
            wrongTick: _wrong('r$i'),
          ),
        ),
    ]);
    // الكلمات الطويلة: العمودين بياخدوا العرض بالنص عشان مايطلعوش بره الشاشة
    final gap = SizedBox(width: q.wide ? context.clampVw(10, 4, 26) : context.clampVw(18, 8, 70));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: q.wide ? [Expanded(child: left), gap, Expanded(child: right)] : [left, gap, right],
      ),
    );
  }

  /// صنّف: اضغط المقطع ثم الصندوق، أو اسحبه للصندوق.
  Widget _sort(BuildContext context) {
    final cardFont = context.clampVw(32, 9, 44);
    Widget card(int i, {bool feedback = false}) {
      final c = q.sortCards[i];
      final sel = s.sel == i;
      return Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(minWidth: context.clampVw(78, 22, 104), minHeight: context.clampVw(68, 18, 84)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.grape,
            borderRadius: BorderRadius.circular(22),
            border: sel ? Border.all(color: AppColors.gold, width: 5) : null,
            boxShadow: feedback ? null : const [BoxShadow(color: Color(0x38000000), offset: Offset(0, 6))],
          ),
          child: Text(c.text, textDirection: TextDirection.rtl, style: kidText(cardFont, color: Colors.white, height: 1.5)),
        ),
      );
    }

    final boxes = [
      for (final b in q.boxes)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.clampVw(4, 1, 7)),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => !s.locked,
              onAcceptWithDetails: (d) => engine.sortPlace(b.key, card: d.data),
              builder: (context, candidates, _) {
                final (tc, tb) = maddColors(b.key);
                final over = candidates.isNotEmpty;
                Widget box = GestureDetector(
                  key: keyFor('b${b.key}'),
                  onTap: () => engine.sortPlace(b.key),
                  child: AnimatedScale(
                    scale: over ? 1.04 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: DashedBox(
                      color: tc,
                      radius: 22,
                      dash: over ? 400 : 8,
                      constraints: BoxConstraints(minHeight: context.clampVw(120, 32, 160)),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Container(
                        color: tb.withValues(alpha: .6),
                        child: Column(children: [
                          Text(b.label, textAlign: TextAlign.center, style: kidText(context.clampVw(14, 3.8, 18), color: tc, height: 1.3)),
                          const SizedBox(height: 6),
                          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                            for (final e in s.placed.entries.where((e) => e.value == b.key))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: tc, width: 3),
                                ),
                                child: Text(q.sortCards[e.key].text,
                                    textDirection: TextDirection.rtl, style: kidText(context.clampVw(22, 6, 28), height: 1.5)),
                              ).animate().scaleXY(begin: 1.18, end: 1, duration: 300.ms),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                );
                if (_wrong('b${b.key}') != null) {
                  box = box.animate(key: ValueKey('bw${s.wrongTick}')).shakeX(hz: 5, amount: 9, duration: 400.ms);
                }
                return Semantics(button: true, label: b.label, child: box);
              },
            ),
          ),
        ),
    ];

    return Column(children: [
      Directionality(textDirection: TextDirection.rtl, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: boxes)),
      const SizedBox(height: 14),
      _Hint(q.orderHint ?? ''),
      Wrap(alignment: WrapAlignment.center, spacing: context.clampVw(8, 2.4, 14), runSpacing: 10, children: [
        for (var i = 0; i < q.sortCards.length; i++)
          if (!s.placed.containsKey(i))
            Semantics(
              button: true,
              label: q.sortCards[i].text,
              child: Draggable<int>(
                data: i,
                maxSimultaneousDrags: s.locked ? 0 : 1,
                onDragStarted: () => engine.sortSelect(i),
                feedback: Transform.scale(scale: 1.08, child: card(i, feedback: true)),
                childWhenDragging: Opacity(opacity: .3, child: card(i)),
                child: GestureDetector(onTap: () => engine.sortSelect(i), child: card(i)),
              ),
            ),
      ]),
    ]);
  }

  Widget _find(BuildContext context) {
    final font = context.clampVw(24, 6.4, 34);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GridView.extent(
          maxCrossAxisExtent: 76,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < q.cells.length; i++) _findCell(i, font),
          ],
        ),
      ),
    );
  }

  Widget _findCell(int i, double font) {
    final circled = s.circled.contains(i);
    final wrong = _wrong('f$i') != null;
    Widget cell = GestureDetector(
      key: keyFor('f$i'),
      onTap: () => engine.findPick(i),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: circled ? const Color(0x2E64D16B) : (wrong ? AppColors.noBg : AppColors.paper2),
          border: Border.all(
            color: circled ? AppColors.grassDark : (wrong ? AppColors.coral : AppColors.line),
            width: circled ? 6 : 3,
          ),
        ),
        child: Text(q.cells[i].ch, style: kidText(font, color: circled ? AppColors.grassDark : AppColors.ink)),
      ),
    );
    if (circled) cell = cell.animate().scaleXY(begin: 1.18, end: 1, duration: 350.ms);
    if (wrong) cell = cell.animate(key: ValueKey('fw${s.wrongTick}')).shakeX(hz: 5, amount: 9, duration: 400.ms);
    return Semantics(button: true, label: q.cells[i].ch, child: cell);
  }

  Widget _memory(BuildContext context) {
    final font = context.clampVw(26, 7, 38);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        // أعمدة = عدد الأزواج (لحد ٥) فالكروت بتنزل صفّين متساويين بالظبط
        child: GridView.count(
          crossAxisCount: (q.cards.length ~/ 2).clamp(2, 5),
          mainAxisSpacing: context.clampVw(8, 2.4, 13),
          crossAxisSpacing: context.clampVw(8, 2.4, 13),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < q.cards.length; i++)
              KeyedSubtree(
                key: keyFor('m$i'),
                child: _memCard(i, font),
              ),
          ],
        ),
      ),
    );
  }

  Widget _memCard(int i, double font) {
    final matched = s.memMatched.contains(i);
    final open = matched || s.flipped.contains(i);
    final card = Pressable3D(
      onTap: open ? null : () => engine.memoryPick(i),
      color: matched ? AppColors.grass : (open ? AppColors.paper : AppColors.grape),
      shadowColor: matched ? AppColors.grassDark : const Color(0x40000000),
      radius: 20,
      depth: 6,
      semanticLabel: open ? q.cards[i].ch : 'كارت مقلوب',
      child: Center(
        child: open && q.cards[i].dots != null
            ? DotCount(q.cards[i].dots!, color: matched ? Colors.white : AppColors.grape, dot: font * .38)
            // وجه الكارت المقلوب: علامة استفهام هادية بدل الإيموجي (زي الويب)
            : Text(open ? ar(q.cards[i].ch) : '?',
                style: kidText(font, color: open && !matched ? AppColors.ink : Colors.white)),
      ),
    );
    final shown = matched ? Opacity(opacity: .75, child: card) : card;
    return open ? shown.animate(key: ValueKey('o$i')).scaleXY(begin: 1.18, end: 1, duration: 300.ms) : shown;
  }
}
