/// دليل ولي الأمر ❤️ — منقول من js/parentGuide.js.
///
/// مفيش بيانات بتتبعت لأي مكان. خطط المتابعة بتتخزّن في ملف التقدّم على الجهاز بس.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/parent_guide.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import 'pg_search.dart';

PgBehavior? pgById(String id) => pgBehaviors.where((b) => b.id == id).firstOrNull;
String pgGoal(PgBehavior b) => pgGoals[b.id] ?? b.label;
const _okBg = Color(0xFFDDF6E2);

// ---------------------------------------------------------------- الصفحة الرئيسية

class PgHomeScreen extends ConsumerStatefulWidget {
  const PgHomeScreen({super.key});

  @override
  ConsumerState<PgHomeScreen> createState() => _PgHomeScreenState();
}

class _PgHomeScreenState extends ConsumerState<PgHomeScreen> {
  String _cat = 'all';
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(progressProvider.select((p) => p.pgFocus.keys.where((k) => pgById(k) != null).length));
    final q = _q.text.trim();
    final chips = [const PgCategory('all', '🗂️', 'الكل'), ...pgCategories];

    Widget results;
    if (q.isNotEmpty) {
      final hits = pgSearch(q).take(6).toList();
      results = hits.isEmpty
          ? Text('مفيش نتيجة لـ «$q». جرّب كلمات تانية (زي: بيضرب، مش بيسمع الكلام، بيعيط)، أو اختار من التصنيفات تحت.',
              style: kidText(15, weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.7))
          : Column(children: [
              for (final b in hits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Tile(icon: b.icon, title: b.label, sub: b.alt != null ? b.title : null, onTap: () => _open(b)),
                ),
            ]);
    } else {
      final list = _cat == 'all'
          ? [
              ...pgFeatured.map(pgById).whereType<PgBehavior>(),
              ...pgBehaviors.where((b) => !pgFeatured.contains(b.id)),
            ]
          : pgBehaviors.where((b) => b.cat == _cat).toList();
      results = TileWrap(minTileWidth: 140, children: [
        for (final b in list) _Card(icon: b.icon, title: b.title, onTap: () => _open(b)),
      ]);
    }

    return ScreenFrame(
      onBack: () => context.back(),
      title: 'دليل ولي الأمر',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('دليل ولي الأمر ❤️', textAlign: TextAlign.center, style: kidText(24)),
          const SizedBox(height: 6),
          Text('🦁 مش لازم تكون أب أو أم مثالي... المهم تعرف تساعد طفلك.',
              textAlign: TextAlign.center, style: kidText(context.clampVw(15, 3.8, 18), weight: FontWeight.w700, color: AppColors.inkSoft, height: 1.7)),
          const SizedBox(height: 14),
          Text('طفلك بيعمل إيه؟', style: kidText(16)),
          const SizedBox(height: 6),
          TextField(
            controller: _q,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            style: kidText(17, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'اكتب مثلًا: ابني بيضرب',
              filled: true,
              fillColor: AppColors.paper2,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close), tooltip: 'مسح', onPressed: () => setState(_q.clear)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in chips)
              ChoiceChip(
                label: Text('${c.icon} ${c.name}'),
                selected: q.isEmpty && _cat == c.id,
                showCheckmark: false,
                labelStyle: kidText(14, color: q.isEmpty && _cat == c.id ? Colors.white : AppColors.ink),
                selectedColor: AppColors.ink,
                backgroundColor: AppColors.paper2,
                onSelected: (_) => setState(() {
                  _cat = c.id;
                  _q.clear();
                }),
              ),
          ]),
          const SizedBox(height: 14),
          results,
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('🧒 أتعلم أتصرف إزاي؟', onTap: () => context.push('/pg/kids')),
            if (goals > 0) KidButton('⭐ أهدافي (${ar(goals)})', kind: BtnKind.ghost, onTap: () => context.push('/pg/goals')),
          ]),
          const SizedBox(height: 12),
          Text('دليل للتربية الهادئة بمعلومات عامة — مش تشخيص نفسي أو طبي. أي خطط بتحفظها بتفضل على الجهاز ده بس ومابتتبعتش لأي مكان.',
              textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.6)),
        ]),
      ),
    );
  }

  void _open(PgBehavior b) {
    FocusScope.of(context).unfocus();
    context.push('/pg/b/${b.id}');
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.onTap});
  final String icon, title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: 18,
        depth: 4,
        color: AppColors.paper2,
        shadowColor: AppColors.shadow,
        border: Border.all(color: AppColors.line, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        semanticLabel: title,
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: kidText(14.5, height: 1.4)),
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap, this.sub});
  final String icon, title;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: 16,
        depth: 4,
        color: AppColors.paper2,
        shadowColor: AppColors.shadow,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        semanticLabel: title,
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: kidText(16)),
              if (sub != null) Text(sub!, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            ]),
          ),
        ]),
      );
}

// ---------------------------------------------------------------- صفحة السلوك

class PgDetailScreen extends ConsumerWidget {
  const PgDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = pgById(id);
    if (b == null) return const PgHomeScreen();
    final cat = pgCategories.where((c) => c.id == b.cat).firstOrNull;
    final body = kidText(15, weight: FontWeight.w600, height: 1.8);

    Widget bullets(List<String> items, {String prefix = '•', Color? color}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final t in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 22, child: Text(prefix, style: body.copyWith(color: color))),
                  Expanded(child: Text(t, style: body)),
                ]),
              ),
          ],
        );

    String helpText() {
      if (b.help == null) return '';
      var t = b.help!.replaceFirst(RegExp(r'^و?لو'), 'لو').replaceFirst(RegExp(r'\.$'), '');
      if (!t.contains('استشر')) t = '$t — فمن الأفضل عرض الأمر على طبيب الأطفال أو مختص مناسب';
      return 'وبشكل خاص: $t.';
    }

    return ScreenFrame(
      onBack: () => context.back(),
      title: '${b.icon} ${b.label}',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(b.icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
          Text(b.title, textAlign: TextAlign.center, style: kidText(24)),
          if (cat != null)
            Text('${cat.icon} ${cat.name}', textAlign: TextAlign.center, style: kidText(14, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          PgSection('🔎', 'ما الذي يحدث؟', [Text(b.what, style: body)]),
          PgSection('🤔', 'لماذا قد يحدث هذا؟', sub: 'دي احتمالات مش تشخيص مؤكد. وطفلك مش مُلام.', [
            bullets([for (final w in b.why) 'قد يكون: $w']),
          ]),
          PgSection('🧭', 'ماذا أفعل الآن؟', [
            for (final (i, st) in b.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 24, child: Text('${ar(i + 1)}.', style: body)),
                  Expanded(
                    child: Text.rich(TextSpan(style: body, children: [
                      TextSpan(text: st.t, style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (st.say != null)
                        TextSpan(text: '  « ${st.say} »', style: const TextStyle(color: Color(0xFF6A4CD8))),
                    ])),
                  ),
                ]),
              ),
          ]),
          PgSection('💬', 'ماذا أقول لطفلي؟', sub: 'جمل جاهزة — اضغط نسخ وعدّلها بكلامك.', [
            for (final p in b.phrases) _Quote(p),
          ]),
          PgSection('❌', 'تجنّب', [bullets(b.avoid, prefix: '✕', color: const Color(0xFFB5473F))]),
          PgSection('🌱', 'ماذا أعلّمه بدلًا من ذلك؟', [_TeachTable(b.teach)]),
          PgSection('❤️', 'بعد ما يهدأ', sub: 'الهدف هو التعليم، مش إذلال الطفل.', [
            bullets(b.calm),
            if (b.calmSay != null) _Quote(b.calmSay!),
          ]),
          if (b.game != null)
            PgSection('🧒', 'أتعلم أتصرف إزاي؟', [
              Text('لعبة قصيرة للطفل: موقف بسيط، واختيارات، وتشجيع على الاختيار الهادي. مفيش خسارة ولا عقاب.', style: body),
              const SizedBox(height: 10),
              Center(child: KidButton('🧒 العب مع طفلك', onTap: () => context.push('/pg/play', extra: [b.id]))),
            ]),
          PgSection('⭐', 'متابعة: نعمل على ده حاليًا', [_Plan(b)]),
          PgSection('⚠️', 'متى أحتاج لاستشارة مختص؟', open: false, [
            Text(pgHelpBase, style: body),
            if (b.help != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(helpText(), style: body)),
          ]),
          const SizedBox(height: 10),
          Center(child: KidButton('رجوع للدليل', kind: BtnKind.ghost, onTap: () => context.back())),
        ]),
      ),
    );
  }
}

/// قسم قابل للطي (details في الويب).
class PgSection extends StatelessWidget {
  const PgSection(this.icon, this.title, this.children, {super.key, this.sub, this.open = true});
  final String icon, title;
  final String? sub;
  final bool open;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.line, width: 2),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ExpansionTile(
        initiallyExpanded: open,
        backgroundColor: AppColors.paper2,
        collapsedBackgroundColor: AppColors.paper2,
        shape: shape,
        collapsedShape: shape,
        iconColor: AppColors.inkSoft,
        collapsedIconColor: AppColors.inkSoft,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 21)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: kidText(17))),
        ]),
        children: [
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(sub!, style: kidText(13.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// جملة جاهزة بزرار نسخ.
class _Quote extends StatefulWidget {
  const _Quote(this.text);
  final String text;

  @override
  State<_Quote> createState() => _QuoteState();
}

class _QuoteState extends State<_Quote> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: const BorderDirectional(start: BorderSide(color: AppColors.grape, width: 4)),
        ),
        child: Row(children: [
          Expanded(child: Text(widget.text, style: kidText(15, weight: FontWeight.w700, height: 1.8))),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.text));
              if (!mounted) return;
              setState(() => _copied = true);
              Timer(const Duration(milliseconds: 1600), () {
                if (mounted) setState(() => _copied = false);
              });
            },
            child: Text(_copied ? '✓ اتنسخت' : '📋 نسخ', style: kidText(14, color: AppColors.grape)),
          ),
        ]),
      );
}

class _TeachTable extends StatelessWidget {
  const _TeachTable(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final head = kidText(13, weight: FontWeight.w700, color: AppColors.inkSoft);
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
      children: [
        TableRow(children: [
          Padding(padding: const EdgeInsets.all(6), child: Text('بدل ❌', style: head)),
          Padding(padding: const EdgeInsets.all(6), child: Text('علّمه ✅', style: head)),
        ]),
        for (final (a, b) in rows)
          TableRow(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: 2))),
            children: [
              Padding(
                padding: const EdgeInsets.all(9),
                child: Text(a, style: kidText(15, weight: FontWeight.w700, color: const Color(0xFF8A3B35))),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: _okBg, borderRadius: BorderRadius.circular(10)),
                child: Text(b, style: kidText(15, weight: FontWeight.w700)),
              ),
            ],
          ),
      ],
    );
  }
}

/// متابعة ٧ أيام — تذكير لولي الأمر بالاستمرار، مش تقييم للطفل.
class _Plan extends ConsumerWidget {
  const _Plan(this.b);
  final PgBehavior b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الهدف بيتعدّل في مكانه (الأيام، الإيقاف) فلازم نسمع للتقدّم كله مش select
    final goal = ref.watch(progressProvider).pgFocus[b.id];
    final progress = ref.read(progressProvider.notifier);
    final body = kidText(15, weight: FontWeight.w600, height: 1.7);
    void fresh() => progress.update((p) => p.pgFocus[b.id] = PgGoal(start: DateTime.now().millisecondsSinceEpoch));

    if (goal == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('لو قررت تشتغل على السلوك ده، اعمله هدف وتابع ٧ أيام.', style: body),
        const SizedBox(height: 10),
        Center(child: KidButton('☑️ نعمل حاليًا على هذا السلوك', onTap: fresh)),
      ]);
    }
    final n = goal.done;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('☑️ ${pgGoal(b)}${goal.paused ? '  (موقوف مؤقتًا)' : ''}', style: kidText(16)),
      const SizedBox(height: 8),
      TileWrap(minTileWidth: 70, spacing: 8, children: [
        for (var i = 0; i < PgGoal.length; i++)
          Semantics(
            button: true,
            toggled: goal.days[i],
            label: 'اليوم ${ar(i + 1)}',
            child: GestureDetector(
              onTap: () => progress.update((p) => p.pgFocus[b.id]!.days[i] = !p.pgFocus[b.id]!.days[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: goal.days[i] ? _okBg : AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: goal.days[i] ? const Color(0xFF9FD5AB) : AppColors.line, width: 2),
                ),
                child: Column(children: [
                  Text(goal.days[i] ? '✅' : '⬜', style: const TextStyle(fontSize: 22)),
                  Text('اليوم ${ar(i + 1)}', style: kidText(13)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      Text(
        '${n >= PgGoal.length ? '🎉 خلّصت ٧ أيام. تحب تكمل أسبوع تاني؟' : 'عملت ${ar(n)} من ${ar(PgGoal.length)} أيام.'} '
        'الخطة دي تذكير ليك إنت بالاستمرار — مش تقييم لطفلك.',
        style: kidText(13.5, weight: FontWeight.w700, color: AppColors.inkSoft, height: 1.6),
      ),
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 4, children: [
        KidButton(goal.paused ? '▶️ استئناف' : '⏸️ إيقاف مؤقت',
            kind: BtnKind.ghost, onTap: () => progress.update((p) => p.pgFocus[b.id]!.paused = !goal.paused)),
        KidButton('🔁 أسبوع جديد', kind: BtnKind.ghost, onTap: fresh),
        KidButton('🗑️ إزالة الهدف', kind: BtnKind.ghost, onTap: () async {
          if (await confirmRemoveGoal(context)) progress.update((p) => p.pgFocus.remove(b.id));
        }),
      ]),
    ]);
  }
}

Future<bool> confirmRemoveGoal(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text('تشيل الهدف ده؟', style: kidText(18, weight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
          TextButton(onPressed: () => c.pop(true), child: const Text('أيوه')),
        ],
      ),
    ) ??
    false;

// ---------------------------------------------------------------- أهدافي

/// قائمة السلوكيات اللي ولي الأمر بيشتغل عليها — في شاشة أهدافي وفي لوحة ولي الأمر.
class PgGoalsList extends ConsumerWidget {
  const PgGoalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(progressProvider).pgFocus;
    final progress = ref.read(progressProvider.notifier);
    final ids = focus.keys.where((k) => pgById(k) != null).toList();
    if (ids.isEmpty) {
      return const NoteBox(Text('لسه ما اخترتش سلوك تشتغل عليه. افتح دليل ولي الأمر واضغط «نعمل حاليًا على هذا السلوك».'));
    }
    String days(PgGoal g) => switch (g.done) {
          0 => 'لسه ما بدأتش',
          1 => 'يوم واحد',
          2 => 'يومان',
          _ => '${ar(g.done)} أيام',
        };
    return Column(children: [
      for (final id in ids)
        Opacity(
          opacity: focus[id]!.paused ? .7 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/pg/b/$id'),
                    child: Text('${pgById(id)!.icon} ${pgGoal(pgById(id)!)}', style: kidText(16)),
                  ),
                ),
                Text('${days(focus[id]!)}${focus[id]!.paused ? ' • موقوف' : ''}',
                    style: kidText(13.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
              ]),
              Wrap(spacing: 8, children: [
                TextButton(
                  onPressed: () => progress.update((p) => p.pgFocus[id]!.paused = !p.pgFocus[id]!.paused),
                  child: Text(focus[id]!.paused ? 'استئناف' : 'إيقاف مؤقت'),
                ),
                TextButton(
                  onPressed: () async {
                    if (await confirmRemoveGoal(context)) progress.update((p) => p.pgFocus.remove(id));
                  },
                  child: const Text('إزالة'),
                ),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

class PgGoalsScreen extends StatelessWidget {
  const PgGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        onBack: () => context.back(),
        title: '⭐ أهدافي',
        child: QCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('⭐ السلوكيات التي تعمل عليها', style: kidText(22)),
            const SizedBox(height: 4),
            Text('تقدر توقف أو تشيل أي هدف، وتفتحه تتابع الأيام.',
                style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            const PgGoalsList(),
            const SizedBox(height: 12),
            Center(child: KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back())),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- 🧒 أتعلم أتصرف إزاي؟

class KidHubScreen extends ConsumerWidget {
  const KidHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = pgBehaviors.where((b) => b.game != null).toList();
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🧒 أتعلم أتصرف إزاي؟',
      child: QCard(
        child: Column(children: [
          Text('🧒 أتعلم أتصرف إزاي؟', textAlign: TextAlign.center, style: kidText(24)),
          const SizedBox(height: 6),
          Text('مواقف بسيطة: اختار التصرف اللي يخلّي الكل مبسوط.',
              textAlign: TextAlign.center, style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          KidButton('🎲 العب ٥ مواقف', onTap: () {
            final ids = ref.read(rngProvider).shuffle([for (final b in games) b.id]).take(5).toList();
            context.push('/pg/play', extra: ids);
          }),
          const SizedBox(height: 14),
          TileWrap(minTileWidth: 140, children: [
            for (final b in games) _Card(icon: b.icon, title: pgGoal(b), onTap: () => context.push('/pg/play', extra: [b.id])),
          ]),
          const SizedBox(height: 12),
          KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back()),
        ]),
      ),
    );
  }
}

/// موقف + ٣ اختيارات + تشجيع. مفيش خسارة ولا عقاب.
class KidPlayScreen extends ConsumerStatefulWidget {
  const KidPlayScreen({super.key, required this.ids});
  final List<String> ids;

  @override
  ConsumerState<KidPlayScreen> createState() => _KidPlayScreenState();
}

class _KidPlayScreenState extends ConsumerState<KidPlayScreen> {
  late List<String> _ids = widget.ids;
  int _i = 0, _stars = 0, _wrong = 0;
  late List<(String, bool)> _opts;
  final _tried = <int>{};
  bool _solved = false, _end = false;

  PgBehavior get _b => pgById(_ids[_i])!;

  String _fill(String s) => fillChildName(s, ref.read(progressProvider).name.trim());

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _opts = ref.read(rngProvider).shuffle([..._b.game!.opts]);
    _tried.clear();
    _wrong = 0;
    _solved = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(speechProvider).speak(_fill(_b.game!.q)));
  }

  void _pick(int i) {
    if (_solved || _tried.contains(i)) return;
    if (_opts[i].$2) {
      if (_wrong == 0) _stars++;
      ref.read(sfxProvider).good();
      setState(() {
        _solved = true;
        _tried.add(i);
      });
    } else {
      ref.read(sfxProvider).bad();
      setState(() {
        _wrong++;
        _tried.add(i);
      });
    }
  }

  void _next() => setState(() {
        if (_i >= _ids.length - 1) {
          _end = true;
        } else {
          _i++;
          _load();
        }
      });

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🧒 أتعلم أتصرف إزاي؟',
      child: QCard(key: ValueKey('$_i$_end'), child: _end ? _endView() : _question()),
    );
  }

  Widget _question() {
    final g = _b.game!;
    final okHeader = RegExp(r'^(ممتاز|جميل|برافو)').hasMatch(g.ok);
    return Column(children: [
      if (_ids.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(spacing: 6, children: [
            for (var k = 0; k < _ids.length; k++)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: k < _i ? AppColors.gold : (k == _i ? AppColors.grape : AppColors.line),
                ),
              ),
          ]),
        ),
      Text(_b.icon, style: TextStyle(fontSize: context.clampVw(52, 16, 76))),
      const SizedBox(height: 6),
      Text(_fill(g.q), textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30), height: 1.5)),
      const SizedBox(height: 16),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(children: [
          for (var i = 0; i < _opts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Option(
                text: _opts[i].$1,
                state: _tried.contains(i)
                    ? (_opts[i].$2 ? _Opt.ok : _Opt.no)
                    : (_wrong >= 2 && _opts[i].$2 && !_solved ? _Opt.hint : _Opt.idle),
                onTap: _solved ? null : () => _pick(i),
              ),
            ),
        ]),
      ),
      if (_solved) ...[
        const Text('⭐', style: TextStyle(fontSize: 44)),
        if (!okHeader) Text('ممتاز!', style: kidText(18)),
        Text(g.ok, textAlign: TextAlign.center, style: kidText(context.clampVw(16, 4.4, 19), weight: FontWeight.w700, height: 1.7)),
        const SizedBox(height: 10),
        KidButton(_i >= _ids.length - 1 ? 'خلصت 🎉' : 'التالي', onTap: _next),
      ] else if (_wrong > 0)
        Text('قريب! جرّب اختيار تاني 💛 فيه تصرف أهدى.',
            textAlign: TextAlign.center, style: kidText(17, weight: FontWeight.w700, color: AppColors.inkSoft)),
    ]);
  }

  Widget _endView() {
    final n = ref.read(progressProvider).name.trim();
    final single = _ids.length == 1;
    return Column(children: [
      Text('🎉', style: TextStyle(fontSize: context.clampVw(52, 16, 76))),
      Text('أحسنت يا ${n.isEmpty ? 'بطل' : n}!', style: kidText(26)),
      const SizedBox(height: 6),
      Text(single ? 'خلّصت الموقف.' : 'اخترت التصرف الهادي من أول مرة في ${ar(_stars)} من ${ar(_ids.length)} مواقف.',
          textAlign: TextAlign.center, style: kidText(17, weight: FontWeight.w700)),
      const SizedBox(height: 14),
      Wrap(alignment: WrapAlignment.center, spacing: 10, children: [
        KidButton('العب تاني', onTap: () => setState(() {
          _ids = single ? _ids : ref.read(rngProvider).shuffle([..._ids]);
          _i = 0;
          _stars = 0;
          _end = false;
          _load();
        })),
        KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back()),
      ]),
    ]);
  }
}

enum _Opt { idle, ok, no, hint }

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.state, this.onTap});
  final String text;
  final _Opt state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border) = switch (state) {
      _Opt.ok => (_okBg, AppColors.grassDark),
      _Opt.no => (const Color(0xFFF6F1EC), AppColors.line),
      _Opt.hint => (AppColors.paper, AppColors.grassDark),
      _Opt.idle => (AppColors.paper, AppColors.line),
    };
    return Opacity(
      opacity: state == _Opt.no ? .65 : 1,
      child: Pressable3D(
        onTap: state == _Opt.no ? null : onTap,
        radius: 18,
        depth: 5,
        color: bg,
        shadowColor: AppColors.shadow,
        border: Border.all(color: border, width: state == _Opt.hint ? 4 : 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        semanticLabel: text,
        child: SizedBox(
          width: double.infinity,
          child: Text(text, textAlign: TextAlign.center, style: kidText(context.clampVw(17, 4.6, 21), height: 1.5)),
        ),
      ),
    );
  }
}
