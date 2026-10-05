/// شاشة الدرس قبل كل مرحلة مدود، و"تدريب صغير" لو الطفل بيغلط كتير في نوع — منقولة من js/madd.js.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/madd.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/generators/madd_generators.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/stages.dart';
import 'madd_style.dart';

class MaddLessonScreen extends ConsumerStatefulWidget {
  const MaddLessonScreen({super.key, required this.stageId});
  final String stageId;

  @override
  ConsumerState<MaddLessonScreen> createState() => _MaddLessonScreenState();
}

class _MaddLessonScreenState extends ConsumerState<MaddLessonScreen> {
  /// النوع اللي محتاج تدريب صغير قبل الدرس (null = على الدرس على طول).
  String? _remedial;
  final _heard = <int>{};

  Stage get pack => packs[widget.stageId]!;

  @override
  void initState() {
    super.initState();
    final p = ref.read(progressProvider);
    _remedial = maddWeakType(p);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_remedial != null) {
        ref.read(progressProvider.notifier).update((p) => p.madd.review.add(_remedial!));
        _say('تحتاج إلى تدريب صغير على ${maddType(_remedial!).name}');
      } else {
        _markLesson();
      }
    });
  }

  void _say(String t) => ref.read(speechProvider).speak(t);

  void _markLesson() {
    final key = pack.madd!.lesson;
    if (maddTypes.any((t) => t.key == key)) {
      ref.read(progressProvider.notifier).update((p) => p.madd.lessons.add(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final remedial = _remedial;
    return ScreenFrame(
      onBack: () => context.pop(),
      title: remedial != null ? 'تدريب صغير' : pack.name,
      child: Column(children: [
        const SizedBox(height: 6),
        if (remedial != null)
          Banner3D('${maddType(remedial).box} ${maddType(remedial).name}',
              color: maddColors(remedial).$1, tone: const Color(0x33000000), ink: Colors.white)
        else
          Banner3D('${pack.icon} ${pack.name}', color: pack.color, tone: const Color(0x33000000), ink: Colors.white),
        const SizedBox(height: 14),
        QCard(child: remedial != null ? _remedialBody(remedial) : _lessonBody()),
        const SizedBox(height: 16),
        if (remedial != null)
          KidButton('▶️ يلا نكمل',
              kind: BtnKind.go,
              onTap: _heard.length < 4
                  ? null
                  : () {
                      ref.read(progressProvider.notifier).update((p) => maddEaseMisses(p, remedial));
                      setState(() => _remedial = null);
                      _markLesson();
                    })
        else
          KidButton('▶️ يلا نلعب', kind: BtnKind.go, onTap: () => context.pushReplacement('/play/${pack.id}')),
      ]),
    );
  }

  // ---------------------------------------------------------------- الدرس

  Widget _rule(String text, [String? key]) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(20, 5.6, 28), color: key == null ? AppColors.ink : maddColors(key).$1, height: 1.5)),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(t, textAlign: TextAlign.center, style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  Widget _lessonBody() {
    final lesson = pack.madd!.lesson;
    final single = maddTypes.where((t) => t.key == lesson).firstOrNull;
    if (single != null) {
      // المراحل ١–٣: درس نوع واحد
      return Column(children: [
        _rule(single.rule, single.key),
        _Formula(single, big: true),
        KidButton('🔊 اسمع', onTap: () => _say(saySyl(single.result))),
        _hint('اضغط أي مقطع لتسمعه'),
        const SizedBox(height: 10),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
          for (final e in single.examples) _ExampleChip(syl: e, typeKey: single.key, onTap: () => _say(saySyl(e))),
        ]),
      ]);
    }
    if (lesson == 'find' || lesson == 'read') {
      // المراحل ٧–٨: كلمات
      final words = [for (final t in maddTypes) maddWords.firstWhere((w) => w.type == t.key && w.lvl == 1)];
      return Column(children: [
        _rule(lesson == 'find' ? 'ابحث عن المقطع الممدود داخل الكلمة' : 'اقرأ الكلمات التي فيها مد'),
        const SizedBox(height: 10),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
          for (final w in words) _WordChip(w, onTap: () => _say(w.w)),
        ]),
        _hint('اضغط أي كلمة لتسمعها'),
      ]);
    }
    // المراحل ٤–٦: تذكير بالأنواع الثلاثة
    const intro = {
      'types': 'ثلاثة مدود: ألف وواو وياء',
      'complete': 'أكمل المقطع بحرف المد المناسب',
      'compose': 'رتّب البطاقتين لتكوين المقطع',
    };
    return Column(children: [
      _rule(intro[lesson] ?? ''),
      for (final t in maddTypes) _TypeRow(t, onTap: () => _say(saySyl(t.result))),
    ]);
  }

  // ---------------------------------------------------------------- التدريب الصغير

  Widget _remedialBody(String key) {
    final t = maddType(key);
    final ex = t.examples.take(4).toList();
    return Column(children: [
      _rule('يبدو أنك تحتاج إلى تدريب صغير على ${t.name} 💪'),
      _hint('اضغط كل بطاقة واسمعها'),
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
        for (final (i, e) in ex.indexed)
          _ExampleChip(
            syl: e,
            typeKey: key,
            big: true,
            done: _heard.contains(i),
            onTap: () {
              _say(saySyl(e));
              setState(() => _heard.add(i));
            },
          ),
      ]),
      SpeechBubble('${ar(_heard.length)} / ${ar(ex.length)}',
          kind: _heard.length == ex.length ? BubbleKind.ok : BubbleKind.plain),
    ]);
  }
}

/// المعادلة: بَ + ا = بَا
class _Formula extends StatelessWidget {
  const _Formula(this.t, {this.big = false});
  final MaddType t;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final (tc, tb) = maddColors(t.key);
    final syl = t.examples.first;
    final font = big ? context.clampVw(34, 10, 52) : 30.0;
    Widget part(Widget child, {bool tinted = false}) => Container(
          constraints: BoxConstraints(minWidth: big ? context.clampVw(58, 16, 84) : 46),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: tinted ? tb : AppColors.paper2,
            borderRadius: BorderRadius.circular(big ? 22 : 16),
            border: Border.all(color: tinted ? tc : AppColors.line, width: 3),
          ),
          child: Center(widthFactor: 1, child: child),
        );
    final op = kidText(big ? context.clampVw(26, 7, 38) : 22, color: AppColors.inkSoft);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: big ? 10 : 6,
        children: [
          part(Text(baseOf(syl), style: kidText(font, height: 1.6))),
          Text('+', style: op),
          part(Text(t.maddLetter, style: kidText(font, color: tc, height: 1.6)), tinted: true),
          Text('=', style: op),
          part(Text.rich(maddSpan(syl, hl: syl.length - 1, typeKey: t.key, style: kidText(font, height: 1.6))), tinted: true),
        ],
      ),
    );
  }
}

/// مثال: مَ ← مَا (بتتسمع بالضغط).
class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.syl, required this.typeKey, required this.onTap, this.big = false, this.done = false});
  final String syl;
  final String typeKey;
  final VoidCallback onTap;
  final bool big;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final (tc, tb) = maddColors(typeKey);
    final font = big ? context.clampVw(32, 9, 46) : context.clampVw(26, 7, 36);
    return Pressable3D(
      onTap: onTap,
      color: tb,
      radius: 22,
      depth: 5,
      shadowColor: done ? AppColors.mint : AppColors.shadow,
      border: Border.all(color: tc, width: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      semanticLabel: syl,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(baseOf(syl), style: kidText(font, color: AppColors.inkSoft, height: 1.7)),
          Text('  ←  ', style: kidText(font * .6, color: AppColors.inkSoft)),
          Text.rich(maddSpan(syl, hl: syl.length - 1, typeKey: typeKey, style: kidText(font, height: 1.7))),
          if (done) Text(' ✅', style: TextStyle(fontSize: font * .6)),
        ]),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip(this.w, {required this.onTap});
  final MaddWord w;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (tc, tb) = maddColors(w.type);
    final font = context.clampVw(26, 7, 36);
    return Pressable3D(
      onTap: onTap,
      color: tb,
      radius: 22,
      depth: 5,
      shadowColor: AppColors.shadow,
      border: Border.all(color: tc, width: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      semanticLabel: w.w,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(w.e, style: TextStyle(fontSize: font)),
          const SizedBox(width: 8),
          Text.rich(maddSpan(w.w, hl: maddIndexIn(w), typeKey: w.type, style: kidText(font, height: 1.7))),
        ]),
      ),
    );
  }
}

/// صف نوع مد: الاسم والمعادلة الصغيرة.
class _TypeRow extends StatelessWidget {
  const _TypeRow(this.t, {required this.onTap});
  final MaddType t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (tc, tb) = maddColors(t.key);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Pressable3D(
        onTap: onTap,
        color: tb,
        radius: 22,
        depth: 5,
        shadowColor: AppColors.shadow,
        border: Border.all(color: tc, width: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        semanticLabel: t.name,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(t.label, style: kidText(context.clampVw(16, 4.4, 20), color: tc)),
            _Formula(t),
          ],
        ),
      ),
    );
  }
}
