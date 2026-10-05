/// كارت "المدود" في لوحة ولي الأمر — منقول من Madd.dashCard في js/madd.js.
library;

import 'package:flutter/material.dart';

import '../../content/madd.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../domain/generators/madd_generators.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';

enum _State { done, doing, todo }

class MaddDashboardCard extends StatelessWidget {
  const MaddDashboardCard(this.p, {super.key});
  final ProgressData p;

  List<Stage> get _stages => packs.values.where((s) => s.isMadd).toList();

  _State _stage(String id) {
    final best = p.best[id] ?? 0;
    if (best >= 2) return _State.done;
    if (best > 0 || p.madd.started.contains(id)) return _State.doing;
    return _State.todo;
  }

  /// مكتمل لو كلها اكتملت، يتدرب لو أي واحدة بدأت.
  _State _group(List<String> ids) {
    final st = ids.map(_stage).toList();
    if (st.every((s) => s == _State.done)) return _State.done;
    if (st.any((s) => s != _State.todo)) return _State.doing;
    return _State.todo;
  }

  int get _pct {
    final ids = _stages;
    final got = ids.fold<int>(0, (s, st) => s + ((p.best[st.id] ?? 0).clamp(0, 3)));
    return ids.isEmpty ? 0 : (got / (ids.length * 3) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('المد بالألف', _group(['madd_alif'])),
      ('المد بالواو', _group(['madd_waw'])),
      ('المد بالياء', _group(['madd_yaa'])),
      ('التمييز بين المدود', _group(['madd_types'])),
      ('المقاطع', _group(['madd_complete', 'madd_compose'])),
      ('الكلمات', _group(['madd_find', 'madd_read'])),
      ('المد والممدود', _group(['madd_mamdoud'])),
    ];
    final ok = p.madd.types.values.fold(0, (s, t) => s + t.ok);
    final tries = p.madd.types.values.fold(0, (s, t) => s + t.tries);
    final level = _stages.where((s) => p.isUnlocked(s.id)).length;
    final words = [for (final w in maddWords) if (MaddStats.wordMastered(p.madd.words[w.plain])) w.w];
    final review = [for (final k in maddReviewList(p)) maddType(k).name];
    final note = kidText(14.5, weight: FontWeight.w700, color: AppColors.inkSoft, height: 1.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(TextSpan(style: kidText(17, weight: FontWeight.w600), children: [
          const TextSpan(text: 'تقدم الطفل في المدود: '),
          TextSpan(text: '${ar(_pct)}٪', style: const TextStyle(fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(height: 6),
        Semantics(
          label: 'تقدم المدود ${ar(_pct)}٪',
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line, width: 3),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: _pct / 100,
              child: Container(decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(999))),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final (name, st) in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 2))),
            child: Row(children: [
              Expanded(child: Text(name, style: kidText(15, weight: FontWeight.w600))),
              Text(
                switch (st) { _State.done => '✅ مكتمل', _State.doing => '🟡 يتدرب', _State.todo => '🔴 لم يبدأ' },
                style: kidText(15, color: switch (st) {
                  _State.done => AppColors.okInk,
                  _State.doing => const Color(0xFF8A5A00),
                  _State.todo => AppColors.noInk,
                }),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Text('المستوى الحالي: ${ar(level.clamp(1, 99))} من ${ar(_stages.length)} • '
            'إجابات صحيحة من أول محاولة: ${ar(ok)} من ${ar(tries)}', style: note),
        Text(review.isEmpty ? '🔁 لا توجد أنواع تحتاج إلى مراجعة' : '🔁 تحتاج إلى مراجعة: ${review.join('، ')}', style: note),
        Text(words.isEmpty ? '📖 لم يُتقن كلمات بعد' : '📖 كلمات أتقنها: ${words.join('، ')}', style: note),
      ]),
    );
  }
}
