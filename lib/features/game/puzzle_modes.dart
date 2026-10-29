/// واجهات ألغاز الكبار: سودوكو، برج هانوي، والبازل المنزلق.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
import 'modes.dart';

Widget _hint(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text,
          textAlign: TextAlign.center,
          style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
    );

// ---------------------------------------------------------------- 🔢 سودوكو

class SudokuGame extends StatelessWidget {
  const SudokuGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q, n = q.gridSize;
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth, 340.0), cell = side / n;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: GridView.count(
                crossAxisCount: n,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (var i = 0; i < n * n; i++) _cell(context, i, cell)],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 14),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (var v = 1; v <= n; v++)
            Pressable3D(
              onTap: s.locked ? null : () => engine.sudokuPut(v),
              color: s.stage.color,
              radius: 18,
              depth: 5,
              semanticLabel: q.symbols[v - 1],
              child: SizedBox.square(
                dimension: context.clampVw(n > 4 ? 48 : 60, 12, 70),
                child: Center(child: Text(q.symbols[v - 1], style: kidText(context.clampVw(26, 7, 32), color: Colors.white))),
              ),
            ),
        ]),
      ),
      _hint(context, q.hint),
    ]);
  }

  Widget _cell(BuildContext context, int i, double size) {
    final q = s.q, n = q.gridSize, row = i ~/ n, col = i % n;
    final given = q.givens[i], v = given ? q.solution[i] : s.sudokuVals[i];
    final sel = s.sudokuSel == i;
    // خطوط تخينة بين المربعات
    final thick = AppColors.ink, thin = AppColors.line;
    Widget c = GestureDetector(
      onTap: given || v != null || s.locked ? null : () => engine.sudokuSelect(i),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFFFFE89A)
              : s.wrongAnchor == 'sq$i'
                  ? AppColors.noBg
                  : (given ? AppColors.paper2 : Colors.white),
          border: Border(
            right: BorderSide(color: (col + 1) % q.boxCols == 0 ? thick : thin, width: (col + 1) % q.boxCols == 0 ? 2.5 : 1),
            bottom: BorderSide(color: (row + 1) % q.boxRows == 0 ? thick : thin, width: (row + 1) % q.boxRows == 0 ? 2.5 : 1),
          ),
        ),
        child: v == null
            ? null
            : Text(q.symbols[v - 1], style: kidText(size * .5, color: given ? AppColors.ink : s.stage.color)),
      ),
    );
    if (v != null && !given) c = c.anim().scaleXY(begin: .6, end: 1, duration: 280.ms, curve: Curves.easeOutBack);
    if (s.wrongAnchor == 'sq$i') c = c.anim(key: ValueKey(s.wrongTick)).shakeX(hz: 5, amount: 4, duration: 350.ms);
    return KeyedSubtree(
      key: keyFor('sq$i'),
      child: Semantics(
        button: v == null,
        selected: sel,
        label: v == null ? 'خانة فاضية، صف ${ar(row + 1)} عمود ${ar(col + 1)}' : q.symbols[v - 1],
        child: c,
      ),
    );
  }
}

// ---------------------------------------------------------------- 🗼 برج هانوي

class HanoiGame extends StatelessWidget {
  const HanoiGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  static const _discColors = [Color(0xFFFF6B6B), Color(0xFFFFC43D), Color(0xFF4CC9A7), Color(0xFF4C9BFF)];

  @override
  Widget build(BuildContext context) {
    final q = s.q;
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth, 420.0), pegW = w / 3;
        final discH = math.min(30.0, pegW * .26), h = discH * (q.discs + 2.4);
        // العمود الأول على اليمين والهدف على الشمال (من اليمين للشمال زي القراية)
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var peg = 0; peg < 3; peg++) _peg(context, peg, pegW, discH, h),
          ]),
        );
      }),
      const SizedBox(height: 8),
      Text('الحركات: ${ar(s.moves)} • أقل عدد: ${ar((1 << q.discs) - 1)}',
          style: kidText(context.clampVw(15, 4, 18), color: AppColors.inkSoft)),
      _hint(context, q.hint),
    ]);
  }

  Widget _peg(BuildContext context, int peg, double w, double discH, double h) {
    final q = s.q, stack = s.pegs.length == 3 ? s.pegs[peg] : const <int>[];
    final held = s.hanoiHeld == peg;
    Widget col = SizedBox(
      width: w,
      height: h + 30,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        // العمود والقاعدة
        Positioned(bottom: 30, child: Container(width: 8, height: h - discH * .4, decoration: BoxDecoration(color: const Color(0xFF8B5E3C), borderRadius: BorderRadius.circular(4)))),
        Positioned(
          bottom: 24,
          child: Container(width: w * .9, height: 8, decoration: BoxDecoration(color: const Color(0xFF8B5E3C), borderRadius: BorderRadius.circular(4))),
        ),
        for (var k = 0; k < stack.length; k++)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            bottom: 32 + k * discH + (held && k == stack.length - 1 ? discH * 1.2 : 0),
            child: Container(
              width: w * (.3 + .6 * stack[k] / q.discs),
              height: discH - 3,
              decoration: BoxDecoration(
                color: _discColors[(stack[k] - 1) % _discColors.length],
                borderRadius: BorderRadius.circular(discH),
                border: held && k == stack.length - 1 ? Border.all(color: AppColors.ink, width: 3) : null,
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          child: Text(peg == 2 ? '🏁' : (peg == 0 ? '▶️' : ''), style: const TextStyle(fontSize: 18)),
        ),
      ]),
    );
    if (s.wrongAnchor == 'peg$peg') col = col.anim(key: ValueKey(s.wrongTick)).shakeX(hz: 5, amount: 6, duration: 380.ms);
    return KeyedSubtree(
      key: keyFor('peg$peg'),
      child: Semantics(
        button: true,
        selected: held,
        label: 'العمود ${ar(peg + 1)}${peg == 2 ? '، الهدف' : ''}: ${ar(stack.length)} حلقة',
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: s.locked ? null : () => engine.hanoiTap(peg), child: col),
      ),
    );
  }
}

// ---------------------------------------------------------------- 🔲 البازل المنزلق

class SlideGame extends StatelessWidget {
  const SlideGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q, n = q.slideSize;
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth, 320.0), cell = side / n;
        final tiles = s.slideTiles;
        Widget board = Container(
          width: side,
          height: side,
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(18)),
          child: Stack(children: [
            for (var i = 0; i < tiles.length; i++)
              if (tiles[i] != 0)
                AnimatedPositioned(
                  key: ValueKey('t${tiles[i]}'),
                  duration: const Duration(milliseconds: 140),
                  // من اليمين: ١ فوق على اليمين زي القراية
                  left: (n - 1 - i % n) * cell,
                  top: (i ~/ n) * cell,
                  width: cell,
                  height: cell,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Pressable3D(
                      onTap: s.locked ? null : () => engine.slideTap(i),
                      color: tiles[i] == i + 1 ? AppColors.grass : s.stage.color,
                      radius: 16,
                      depth: 5,
                      semanticLabel: ar(tiles[i]),
                      child: Center(child: Text(ar(tiles[i]), style: kidText(cell * .42, color: Colors.white))),
                    ),
                  ),
                ),
          ]),
        );
        if (s.puzzleBump > 0) board = board.anim(key: ValueKey('b${s.puzzleBump}')).shakeX(hz: 6, amount: 4, duration: 260.ms);
        return board;
      }),
      const SizedBox(height: 8),
      Text('الحركات: ${ar(s.moves)}', style: kidText(context.clampVw(15, 4, 18), color: AppColors.inkSoft)),
      _hint(context, q.hint),
    ]);
  }
}
