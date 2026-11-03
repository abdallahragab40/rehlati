/// أنشطة «جرّب بنفسك» و«تأكد من فهمك» في شرح الدرس: اختار، المس كل الصح، رتّب، وصّل، صنّف.
/// كلها باللمس (من غير سحب) عشان تنفع لإيد صغيرة. النشاط بيبلّغ الشاشة بكل غلطة والعنصر الغلط
/// (عشان التلميح يبقى على قدّها) ولما يتحل — الصوت والتلميح والمساعدة عند الشاشة.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/lesson_content.dart';

class TaskView extends StatefulWidget {
  const TaskView(this.task, {super.key, required this.seed, required this.onWrong, required this.onSolved});
  final LessonTask task;

  /// بذرة اللخبطة — ثابتة للنشاط عشان الترتيب مايتغيّرش مع كل رسم.
  final int seed;
  final void Function(String wrong) onWrong;
  final VoidCallback onSolved;

  @override
  State<TaskView> createState() => _TaskViewState();
}

/// [other]: العمود التاني في «وصّل» — لون تاني عشان الطفل يفرّق بين المجموعتين.
enum _Look { idle, other, selected, ok, dim }

class _TaskViewState extends State<TaskView> {
  late final Rng _r = Rng.seeded(widget.seed);
  LessonTask get t => widget.task;

  // اختار / المس
  final _wrong = <String>{};
  final _found = <String>{};

  // رتّب: أماكن العناصر المتلخبطة اللي اتحطت بالترتيب
  late final List<String> _pool = _shuffled(t.items);
  final _placed = <int>[];

  // وصّل
  late final List<String> _rights = _shuffled([for (final p in t.pairs) p.$2]);
  int? _left;
  final _matched = <int>{};

  // صنّف
  late final List<String> _queue = _shuffled([for (final g in t.groups) ...g.$2]);
  final _sorted = <String, List<String>>{};

  bool _done = false;

  /// نسخة متلخبطة فعلًا — مش نفس الترتيب الصح بالصدفة. (Rng.shuffle بيلخبط القايمة نفسها.)
  List<String> _shuffled(List<String> l) {
    var s = _r.shuffle([...l]);
    for (var i = 0; i < 10 && l.toSet().length > 1 && _same(s, l); i++) {
      s = _r.shuffle([...l]);
    }
    return s;
  }

  static bool _same(List<String> a, List<String> b) => a.join('\u0000') == b.join('\u0000');

  void _solve() {
    setState(() => _done = true);
    widget.onSolved();
  }

  void _miss(String wrong) {
    setState(() {});
    widget.onWrong(wrong);
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: t.en ? TextDirection.ltr : TextDirection.rtl,
        child: switch (t.kind) {
          TaskKind.choice => _choice(),
          TaskKind.pick => _pick(),
          TaskKind.order => _order(),
          TaskKind.match => _match(),
          TaskKind.sort => _sort(),
        },
      );

  Widget _chip(String label, _Look look, VoidCallback? onTap, {bool big = false}) => _Chip(
        label: t.en ? label : ar(label),
        semantic: label,
        look: look,
        onTap: onTap,
        big: big,
      );

  Widget _wrap(List<Widget> children) =>
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: children);

  // ---------------------------------------------------------------- اختار

  Widget _choice() => _wrap([
        for (final c in t.choices)
          _chip(
            c,
            _done && c == t.answer ? _Look.ok : (_wrong.contains(c) ? _Look.dim : _Look.idle),
            _done || _wrong.contains(c)
                ? null
                : () {
                    if (c == t.answer) return _solve();
                    _wrong.add(c);
                    _miss(c);
                  },
            big: true,
          ),
      ]);

  // ---------------------------------------------------------------- المس كل الصح

  Widget _pick() => _wrap([
        for (final it in t.items)
          _chip(
            _found.contains(it) ? '✓ $it' : it,
            _found.contains(it) ? _Look.ok : (_wrong.contains(it) ? _Look.dim : _Look.idle),
            _done || _found.contains(it) || _wrong.contains(it)
                ? null
                : () {
                    if (!t.answers.contains(it)) {
                      _wrong.add(it);
                      return _miss(it);
                    }
                    setState(() => _found.add(it));
                    if (_found.length == t.answers.length) _solve();
                  },
          ),
      ]);

  // ---------------------------------------------------------------- رتّب

  Widget _order() => Column(children: [
        // صف الإجابة: اللي اترتّب، وبعده خانات فاضية
        _wrap([
          for (final i in _placed) _chip(_pool[i], _done ? _Look.ok : _Look.selected, null, big: true),
          for (var k = _placed.length; k < t.items.length; k++) const _Slot(),
        ]),
        const SizedBox(height: 14),
        _wrap([
          for (var i = 0; i < _pool.length; i++)
            if (!_placed.contains(i))
              _chip(_pool[i], _Look.idle, _done
                  ? null
                  : () {
                      // الطفل بيختار بالنص: أي «ب» من الاتنين تنفع
                      if (_pool[i] != t.items[_placed.length]) return _miss(_pool[i]);
                      setState(() => _placed.add(i));
                      if (_placed.length == t.items.length) _solve();
                    }, big: true),
        ]),
      ]);

  // ---------------------------------------------------------------- وصّل

  Widget _match() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            for (var i = 0; i < t.pairs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _chip(
                  t.pairs[i].$1,
                  _matched.contains(i) ? _Look.ok : (_left == i ? _Look.selected : _Look.idle),
                  _done || _matched.contains(i) ? null : () => setState(() => _left = i),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(children: [
            for (final r in _rights)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: () {
                  final taken = _matched.any((i) => t.pairs[i].$2 == r);
                  return _chip(r, taken ? _Look.ok : _Look.other, _done || taken || _left == null
                      ? null
                      : () {
                          final i = _left!;
                          if (t.pairs[i].$2 != r) return _miss(r);
                          setState(() {
                            _matched.add(i);
                            _left = null;
                          });
                          if (_matched.length == t.pairs.length) _solve();
                        });
                }(),
              ),
          ]),
        ),
      ]);

  // ---------------------------------------------------------------- صنّف

  Widget _sort() {
    final n = _sorted.values.fold(0, (a, l) => a + l.length);
    final current = n < _queue.length ? _queue[n] : null;
    return Column(children: [
      if (current != null) _chip(current, _Look.selected, null, big: true),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (i, (name, items)) in t.groups.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Column(children: [
              Pressable3D(
                onTap: current == null
                    ? null
                    : () {
                        if (!items.contains(current)) return _miss(current);
                        setState(() => _sorted.putIfAbsent(name, () => []).add(current));
                        if (n + 1 == _queue.length) _solve();
                      },
                color: AppColors.grape,
                radius: 18,
                depth: 5,
                shadowColor: const Color(0x40000000),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                semanticLabel: name,
                child: Center(
                  child: Text(t.en ? name : ar(name),
                      textAlign: TextAlign.center, style: kidText(context.clampVw(17, 4.6, 22), color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                for (final it in _sorted[name] ?? const <String>[])
                  Text(t.en ? it : ar(it), style: kidText(context.clampVw(16, 4.4, 20), color: AppColors.okInk)),
              ]),
            ]),
          ),
        ],
      ]),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.semantic, required this.look, required this.onTap, this.big = false});
  final String label;
  final String semantic;
  final _Look look;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final (bg, line) = switch (look) {
      _Look.idle => (AppColors.paper2, AppColors.line),
      _Look.other => (AppColors.noteBg, const Color(0x40E39A00)),
      _Look.selected => (const Color(0xFFEDE7FF), AppColors.grape),
      _Look.ok => (AppColors.okBg, AppColors.okInk),
      _Look.dim => (AppColors.paper2, AppColors.line),
    };
    final short = label.characters.length <= 4;
    return Opacity(
      opacity: look == _Look.dim ? .4 : 1,
      child: Pressable3D(
        onTap: onTap,
        color: bg,
        radius: 20,
        depth: 5,
        shadowColor: AppColors.shadow,
        border: Border.all(color: line, width: 3),
        padding: EdgeInsets.symmetric(horizontal: short ? 20 : 14, vertical: 6),
        semanticLabel: semantic,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: kidText(big && short ? context.clampVw(28, 7.5, 38) : context.clampVw(20, 5.4, 26), height: 1.5),
        ),
      ),
    );
  }
}

/// خانة فاضية في صف «رتّب».
class _Slot extends StatelessWidget {
  const _Slot();

  @override
  Widget build(BuildContext context) => Container(
        width: context.clampVw(48, 13, 60),
        height: context.clampVw(56, 15, 68),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 3),
        ),
        child: Center(child: Text('؟', style: kidText(24, color: AppColors.inkSoft))),
      );
}
