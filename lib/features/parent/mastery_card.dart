/// لوحة ولي الأمر: حالة المراحل (جديد / بيتدرّب / جاهز للمراجعة / متقن) ومستوى البداية، كله ولكل مادة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';

String masteryLabel(MasteryState s) => switch (s) {
      MasteryState.fresh => '🌱 جديد',
      MasteryState.practicing => '🔄 بيتدرّب',
      MasteryState.review => '🔁 جاهز للمراجعة',
      MasteryState.mastered => '🏅 متقن',
    };

class MasteryCard extends ConsumerWidget {
  const MasteryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final body = kidText(14, weight: FontWeight.w600, color: AppColors.inkSoft);
    final due = [for (final id in p.dueForReview) ?packs[id]];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final w in worldStages.keys)
        () {
          final stages = [for (final s in worldStages[w]!) if (!s.isLearn && p.isUnlocked(s.id)) s];
          final count = {for (final m in MasteryState.values) m: 0};
          for (final s in stages) {
            count[p.masteryOf(s.id)] = count[p.masteryOf(s.id)]! + 1;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${worldMeta(w).icon} ${worldMeta(w).name}: '
              '${[for (final m in MasteryState.values) if (count[m]! > 0) '${masteryLabel(m)} ${ar(count[m]!)}'].join(' • ')}',
              style: kidText(14.5),
            ),
          );
        }(),
      if (due.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text('جاهز للمراجعة: ${due.map((s) => '${s.icon} ${s.name}').join('، ')}', style: kidText(14.5)),
      ],
      const SizedBox(height: 6),
      Text(
        'الإتقان غير النجوم: المرحلة بتبقى "متقنة" بعد ٣ جولات على الأقل ومراجعات ناجحة على أيام متباعدة '
        '(١ ثم ٣ ثم ٧ أيام) بدقة ٨٠٪ من أول محاولة. تفويت ميعاد المراجعة مابيمسحش حاجة.',
        style: body,
      ),
      const SizedBox(height: 10),
      Text('🎚️ مستوى البداية', style: kidText(15)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 4, children: [
        for (final (v, label) in [(null, 'حسب السن'), (1, 'سهل'), (2, 'متوسط'), (3, 'أصعب')])
          ChoiceChip(
            label: Text(label),
            selected: p.settings.startLevel == v,
            onSelected: (_) => ref.read(progressProvider.notifier).update((p) => p.settings.startLevel = v),
          ),
      ]),
      const SizedBox(height: 10),
      Text('📚 مستوى كل مادة', style: kidText(15)),
      const SizedBox(height: 4),
      for (final w in subjectWorlds) ...[
        Text('${worldMeta(w).icon} ${worldMeta(w).name}', style: kidText(14.5)),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(key: Key('level-$w'), spacing: 6, runSpacing: 4, children: [
            for (final (v, label) in [(null, 'زي الباقي'), (1, 'سهل'), (2, 'متوسط'), (3, 'أصعب')])
              ChoiceChip(
                label: Text(label),
                selected: p.settings.worldLevel[w] == v,
                onSelected: (_) => ref.read(progressProvider.notifier).update((p) {
                  v == null ? p.settings.worldLevel.remove(w) : p.settings.worldLevel[w] = v;
                }),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 4),
      Text('مثلًا سهل في الإنجليزي وأصعب في الحساب. "زي الباقي" بيمشي على مستوى البداية اللي فوق.', style: body),
      const SizedBox(height: 4),
      Text('لو الطفل اتعثر في مرحلة جولتين ورا بعض، الجولة الجاية بتبدأ من أسهل مستوى ليها تلقائيًا.', style: body),
    ]);
  }
}
