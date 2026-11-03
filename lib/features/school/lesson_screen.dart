/// شرح درس من دروس المدرسة: بطاقة بطاقة (شرح، مثال بخطوات، جرّب معايا، نشاط في البيت، ملخص)،
/// وفي الآخر «تدرّب لوحدك» بيفتح جولة أسئلة الدرس العادية — lib/domain/lesson_content.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/features.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/lesson_content.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/question.dart';
import '../../domain/school_lessons.dart';
import '../game/visuals.dart';
import '../madd/madd_style.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.id});

  /// مفتاح الدرس (`school:p1-t1-math:u1:l1`).
  final String id;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int _page = 0;

  /// خطوات المثال اللي اتكشفت لحد دلوقتي (من صفر).
  int _step = 0;

  /// سؤال «جرّب معايا» الحالي، والاختيارات الغلط اللي جرّبها، وهل حلّه.
  int _q = 0;
  final _wrong = <String>{};
  bool _solved = false;
  int _shake = 0;

  /// آخر بطاقة اتقالت — عشان كل بطاقة تتنطق مرة واحدة لما تظهر.
  String? _spoken;

  bool get _en => schoolRound(widget.id)?.book.subject == 'english';

  void _say(Object t) => ref.read(speechProvider).speak(t);
  void _sayEn(String t) => ref.read(speechProvider).speakEn(t);

  /// الجملة اللي بتتقال لما البطاقة دي تظهر.
  Object _cardSpeech(LessonBlock b) => switch (b) {
        ExplainBlock(:final card) => card.spoken,
        ExampleBlock(:final steps) => steps[_step].spoken,
        TryBlock(:final questions) => questions[_q].say ?? questions[_q].ask,
        ActivityBlock(:final text) => text,
        SummaryBlock() => sayLessonDone,
      };

  void _speakOnce(LessonBlock b) {
    if (!voiceEnabled) return;
    final key = '$_page:$_step:$_q';
    if (_spoken == key) return;
    _spoken = key;
    final t = _cardSpeech(b);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _say(t);
    });
  }

  void _go(int page, LessonContent c) {
    setState(() {
      _page = page;
      _step = 0;
      _q = 0;
      _wrong.clear();
      _solved = false;
    });
    if (c.blocks[page] is SummaryBlock) {
      ref.read(progressProvider.notifier).update((p) => p.explained.add(c.id));
    }
  }

  void _pick(TryQuestion q, String choice) {
    if (_solved || _wrong.contains(choice)) return;
    final sfx = ref.read(sfxProvider);
    if (choice == q.answer) {
      sfx.good();
      setState(() => _solved = true);
      if (voiceEnabled) _say(q.why);
    } else {
      sfx.bad();
      setState(() {
        _wrong.add(choice);
        _shake++;
      });
      if (voiceEnabled) _say(sayNotThis);
    }
  }

  void _practice() {
    final p = ref.read(progressProvider);
    context.pushReplacement(p.limitReached ? '/timeup' : '/play/${widget.id}');
  }

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(lessonsProvider);
    final c = lessons.value?[widget.id];
    if (c == null) {
      return ScreenFrame(
        onBack: () => context.back(),
        title: '📖 شرح الدرس',
        child: lessons.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                const NoteBox(Text('الدرس ده لسه مالوش شرح')),
                const SizedBox(height: 14),
                KidButton('▶️ ذاكر الدرس', kind: BtnKind.go, onTap: _practice),
              ]),
      );
    }
    if (!c.open) {
      return ScreenFrame(
        onBack: () => context.back(),
        title: c.title,
        child: Column(children: [
          const NoteBox(Text('🔒 شرح الدرس ده من المحتوى الكامل. تقدر تذاكر أسئلته دلوقتي.')),
          const SizedBox(height: 14),
          KidButton('▶️ ذاكر الدرس', kind: BtnKind.go, onTap: _practice),
        ]),
      );
    }

    final b = c.blocks[_page];
    _speakOnce(b);
    final last = _page == c.blocks.length - 1;
    final (nextLabel, VoidCallback? next) = switch (b) {
      ExampleBlock(:final steps) when _step < steps.length - 1 => (
          '👣 الخطوة الجاية',
          () => setState(() => _step++),
        ),
      TryBlock(:final questions) when _q < questions.length - 1 => (
          'السؤال الجاي ⬅️',
          _solved
              ? () => setState(() {
                    _q++;
                    _wrong.clear();
                    _solved = false;
                  })
              : null,
        ),
      TryBlock() => ('التالي ⬅️', _solved ? () => _go(_page + 1, c) : null),
      _ => ('التالي ⬅️', last ? null : () => _go(_page + 1, c)),
    };

    return ScreenFrame(
      onBack: () => context.back(),
      title: c.title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Dots(count: c.blocks.length, at: _page),
        const SizedBox(height: 10),
        if (_page == 0) ...[
          NoteBox(Text('🎯 هدف الدرس: ${ar(c.goal)}', textAlign: TextAlign.center)),
          const SizedBox(height: 10),
        ],
        QCard(
          key: ValueKey('$_page:$_q'),
          shakeTick: _shake,
          child: Column(children: [
            Text(_label(b), style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            _body(b, c),
          ]),
        ),
        const SizedBox(height: 16),
        if (b is SummaryBlock) ...[
          KidButton('▶️ تدرّب لوحدك', kind: BtnKind.go, onTap: _practice),
          const SizedBox(height: 10),
          KidButton('🔁 اشرح من الأول', kind: BtnKind.ghost, onTap: () => _go(0, c)),
        ] else
          Row(children: [
            if (_page > 0) ...[
              Expanded(child: KidButton('➡️ السابق', kind: BtnKind.ghost, onTap: () => _go(_page - 1, c))),
              const SizedBox(width: 10),
            ],
            // مقفول لحد الإجابة الصح — باهت عشان الطفل مايضغطش ويستنى
            Expanded(
              flex: 2,
              child: Opacity(opacity: next == null ? .4 : 1, child: KidButton(nextLabel, kind: BtnKind.go, onTap: next)),
            ),
          ]),
      ]),
    );
  }

  String _label(LessonBlock b) => switch (b) {
        ExplainBlock() => '💡 اشرح لي',
        ExampleBlock() => '👣 شوف المثال',
        TryBlock(:final questions) => '✋ جرّب معايا — ${ar(_q + 1)} / ${ar(questions.length)}',
        ActivityBlock() => '🏠 نشاط في البيت (لولي الأمر)',
        SummaryBlock() => '⭐ ملخص الدرس',
      };

  Widget _text(String t) => Text(ar(t), textAlign: TextAlign.center, style: kidText(context.clampVw(20, 5.6, 28), height: 1.5));

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(ar(t), textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30), color: AppColors.grape)),
      );

  Widget _replay(Object t) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: KidButton('🔊 اسمع تاني', kind: BtnKind.ghost, onTap: () => _say(t)),
      );

  Widget _card(LessonCard card) => Column(children: [
        if (card.visual != null) VisualView(card.visual!, ltr: _en && card.visual is! ExprVisual),
        _text(card.text),
        if (card.en != null) _EnLine(card.en!, onTap: () => _sayEn(card.en!)),
      ]);

  Widget _body(LessonBlock b, LessonContent c) => switch (b) {
        ExplainBlock(:final title, :final card) => Column(children: [
            if (title != null) _title(title),
            _card(card),
            if (voiceEnabled) _replay(card.spoken),
          ]),
        ExampleBlock(:final title, :final steps) => Column(children: [
            _title(title),
            for (var i = 0; i <= _step; i++) ...[
              if (i > 0) const Divider(height: 24),
              _card(steps[i]),
            ],
            if (voiceEnabled) _replay(steps[_step].spoken),
          ]),
        TryBlock(:final questions) => _tryBody(questions[_q]),
        ActivityBlock(:final text) => Column(children: [
            const Text('👨‍👩‍👦', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 6),
            _text(text),
          ]),
        SummaryBlock(:final points) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in points)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('✅ ${ar(p)}', style: kidText(context.clampVw(18, 5, 24), height: 1.5)),
              ),
          ]),
      };

  Widget _tryBody(TryQuestion q) {
    final dir = q.en ? TextDirection.ltr : TextDirection.rtl;
    return Column(children: [
      _text(q.ask),
      const SizedBox(height: 8),
      if (q.visual != null) VisualView(q.visual!, ltr: q.en),
      Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
        for (final ch in q.choices)
          Opacity(
            opacity: _wrong.contains(ch) ? .4 : 1,
            child: Pressable3D(
              onTap: () => _pick(q, ch),
              color: _solved && ch == q.answer ? AppColors.okBg : AppColors.paper2,
              radius: 22,
              depth: 5,
              shadowColor: AppColors.shadow,
              border: Border.all(color: _solved && ch == q.answer ? AppColors.okInk : AppColors.line, width: 3),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
              semanticLabel: ch,
              child: Directionality(
                textDirection: dir,
                child: Text(q.en ? ch : ar(ch), style: kidText(context.clampVw(26, 7, 36), height: 1.5)),
              ),
            ),
          ),
      ]),
      if (_solved)
        SpeechBubble('👏 ${ar(q.why)}', kind: BubbleKind.ok)
      else if (_wrong.isNotEmpty)
        const SpeechBubble('مش ده — فكّر تاني 🤔', kind: BubbleKind.no),
    ]);
  }
}

/// جملة إنجليزي كبيرة من الشمال، وجنبها 🔊.
class _EnLine extends StatelessWidget {
  const _EnLine(this.text, {required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
            Text(text, style: kidText(context.clampVw(28, 7.5, 40), color: AppColors.grape, height: 1.4)),
            if (voiceEnabled) ListenButton(text, en: true, size: 52),
          ]),
        ),
      );
}

/// نقطة لكل بطاقة — اللي خلصت ملوّنة.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.at});
  final int count, at;

  @override
  Widget build(BuildContext context) => Wrap(alignment: WrapAlignment.center, spacing: 6, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == at ? 26 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: i <= at ? AppColors.gold : AppColors.paper,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ]);
}
