/// شرح درس من دروس المدرسة بطاقة بطاقة: تمهيد، اكتشف المعلومة، شاهد التطبيق، جرّب بنفسك،
/// طبّق خارج الشاشة، تأكد من فهمك، وملخص — وفي الآخر «تدرّب لوحدك» بيفتح جولة أسئلة الدرس العادية.
///
/// الغلطة بتجيب تلميح على قدّها، والغلطة التانية في نفس النشاط بتجيب مثال أبسط. الطفل بيكمّل من
/// آخر بطاقة وقف عندها، وسجلّه ([LessonLog]) بيقول لولي الأمر شاف الشرح ولا احتاج مساعدة ولا أتقن.
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
import '../../domain/progress/extras.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/question.dart';
import '../../domain/school_lessons.dart';
import '../game/visuals.dart';
import '../madd/madd_style.dart';
import 'lesson_tasks.dart';

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

  /// «اقرا وبعدين اسمع»: الطفل سمع الكلمة دي واتأكد.
  bool _heard = false;

  /// النشاط الحالي في «جرّب بنفسك»، وغلطاته، والتلميح، وهل اتحل.
  int _q = 0;
  int _tries = 0;
  String? _hint;
  bool _solved = false;
  int _shake = 0;

  /// أول مرة الدرس بيتفتح: بنكمّل من آخر بطاقة — و[_resumed] بيقول للطفل كده.
  bool _started = false;
  bool _resumed = false;

  /// آخر بطاقة اتقالت — عشان كل بطاقة تتنطق مرة واحدة لما تظهر.
  String? _spoken;

  bool get _en => bookOfLesson(widget.id)?.subject == 'english';

  /// درس شرح بس (استماع، نشيد، قراءة) مالوش جولة أسئلة.
  bool get _hasPractice => schoolRound(widget.id) != null;

  void _say(Object t) => ref.read(speechProvider).speak(t);
  void _sayEn(String t) => ref.read(speechProvider).speakEn(t);

  void _log(LessonContent c, void Function(LessonLog l) change) =>
      ref.read(progressProvider.notifier).update((p) => change(p.lessonLog(c.uid)));

  /// الجملة اللي بتتقال لما البطاقة دي تظهر.
  Object _cardSpeech(LessonBlock b) => switch (b) {
        HookBlock(:final card, :final ask) => [..._parts(card.spoken), ?ask],
        ExplainBlock(:final card) => card.spoken,
        ExampleBlock(:final steps) => steps[_step].spoken,
        TryBlock(:final tasks) => tasks[_q].say ?? tasks[_q].ask,
        StoryBlock(:final pages) => pages[_step].spoken,
        PoemBlock(:final lines) => lines,
        // الكلمة نفسها ماتتقالش — الطفل يقراها لوحده الأول
        ReadBlock() => _step == 0 ? sayReadFirst : '',
        ActivityBlock(:final text) => text,
        SummaryBlock() => sayLessonDone,
      };

  static List<String> _parts(Object spoken) => spoken is List<String> ? spoken : ['$spoken'];

  void _speakOnce(LessonBlock b) {
    if (!voiceEnabled) return;
    final key = '$_page:$_step:$_q';
    if (_spoken == key) return;
    _spoken = key;
    final t = _cardSpeech(b);
    if (t == '') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _say(t);
    });
  }

  /// أول ما المحتوى يوصل: من آخر بطاقة لو الشرح ماخلصش، أو من الأول لو خلص قبل كده.
  void _start(LessonContent c) {
    _started = true;
    final log = ref.read(progressProvider).lessonLogs[c.uid];
    if (log != null && !log.done && log.page > 0 && log.page < c.blocks.length) {
      _page = log.page;
      _resumed = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restart(c, page: false);
      });
    }
  }

  /// مرة جديدة من الأول: غلطات المرة دي بتتعد من جديد. نتيجة آخر مرة خلّصها والإتقان بيفضلوا
  /// لحد ما يخلّص تاني — عشان «محتاج مراجعة» مايختفيش بمجرد ما يفتح الدرس.
  void _restart(LessonContent c, {bool page = true}) {
    _log(c, (l) => l
      ..page = 0
      ..current = 0
      ..checkMiss = false);
    if (page) _go(0, c);
  }

  void _go(int page, LessonContent c) {
    setState(() {
      _page = page;
      _step = 0;
      _heard = false;
      _q = 0;
      _resumed = false;
      _resetTask();
    });
    final hasCheck = c.blocks.any((b) => b is TryBlock && b.check);
    _log(c, (l) {
      l.page = page;
      if (c.blocks[page] is! SummaryBlock) return;
      // وصل للملخص: «تأكد من فهمك» اتحل في المرة دي (مفيش تخطّي للأنشطة)
      l.done = true;
      l.mistakes = l.current;
      // أتقن لوحده: «تأكد من فهمك» كله صح من أول مرة (ولو الدرس مافيهوش، مفيش ولا غلطة)
      l.independent = l.independent || (hasCheck ? !l.checkMiss : l.current == 0);
    });
  }

  void _resetTask() {
    _tries = 0;
    _hint = null;
    _solved = false;
  }

  void _wrong(LessonContent c, TryBlock b, String item) {
    ref.read(sfxProvider).bad();
    final hint = b.tasks[_q].hintFor(item);
    setState(() {
      _tries++;
      _hint = hint;
      _shake++;
    });
    _log(c, (l) {
      l.current++;
      if (b.check) l.checkMiss = true;
    });
    if (voiceEnabled) _say(hint);
  }

  void _right(TryBlock b) {
    ref.read(sfxProvider).good();
    setState(() => _solved = true);
    if (voiceEnabled) _say(b.tasks[_q].why);
  }

  void _practice() {
    if (!_hasPractice) return context.back();
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
    if (!_started) _start(c);

    final b = c.blocks[_page];
    _speakOnce(b);
    final last = _page == c.blocks.length - 1;
    final (nextLabel, VoidCallback? next) = switch (b) {
      ExampleBlock(:final steps) when _step < steps.length - 1 => (
          '👣 الخطوة الجاية',
          () => setState(() => _step++),
        ),
      StoryBlock(:final pages) when _step < pages.length - 1 => (
          '📖 الصفحة الجاية',
          () => setState(() => _step++),
        ),
      // «اقرا وبعدين اسمع»: الجاي بيفتح بعد ما الطفل يسمع ويتأكد
      ReadBlock(:final items) when _step < items.length - 1 => (
          'الجاية ⬅️',
          _heard || !voiceEnabled
              ? () => setState(() {
                    _step++;
                    _heard = false;
                  })
              : null,
        ),
      ReadBlock() => ('التالي ⬅️', _heard || !voiceEnabled ? () => _go(_page + 1, c) : null),
      TryBlock(:final tasks) when _q < tasks.length - 1 => (
          'النشاط الجاي ⬅️',
          _solved
              ? () => setState(() {
                    _q++;
                    _resetTask();
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
        if (_resumed) ...[
          const NoteBox(Text('👋 كمّلنا من آخر مكان وقفت فيه', textAlign: TextAlign.center)),
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
          KidButton(_hasPractice ? '▶️ تدرّب لوحدك' : '✅ خلّصت — ارجع للدروس', kind: BtnKind.go, onTap: _practice),
          const SizedBox(height: 10),
          KidButton('🔁 اشرح من الأول', kind: BtnKind.ghost, onTap: () => _restart(c)),
        ] else
          Row(children: [
            if (_page > 0) ...[
              Expanded(child: KidButton('➡️ السابق', kind: BtnKind.ghost, onTap: () => _go(_page - 1, c))),
              const SizedBox(width: 10),
            ],
            // مقفول لحد الحل — باهت عشان الطفل مايضغطش ويستنى
            Expanded(
              flex: 2,
              child: Opacity(opacity: next == null ? .4 : 1, child: KidButton(nextLabel, kind: BtnKind.go, onTap: next)),
            ),
          ]),
      ]),
    );
  }

  String _label(LessonBlock b) => switch (b) {
        HookBlock() => '🤔 تمهيد',
        ExplainBlock() => '💡 اكتشف المعلومة',
        ExampleBlock() => '👣 شاهد التطبيق',
        TryBlock(:final tasks, :final check) =>
          '${check ? '✅ تأكد من فهمك' : '✋ جرّب بنفسك'} — ${ar(_q + 1)} / ${ar(tasks.length)}',
        StoryBlock(:final pages) => '📖 قصة — صفحة ${ar(_step + 1)} / ${ar(pages.length)}',
        PoemBlock() => '🎵 نشيد',
        ReadBlock(:final items) => '👀 اقرا وبعدين اسمع — ${ar(_step + 1)} / ${ar(items.length)}',
        ActivityBlock() => '🏠 طبّق خارج الشاشة (مع ولي الأمر)',
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
        if (card.visual case EmojiVisual(:final emoji, caption: null) when emoji.characters.length > 3)
          // مشهد من كذا صورة: أصغر شوية عشان يفضل في سطر واحد
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(emoji, textAlign: TextAlign.center, style: TextStyle(fontSize: context.clampVw(46, 12, 64), height: 1.2)),
          )
        else if (card.visual != null)
          VisualView(card.visual!, ltr: _en && card.visual is! ExprVisual),
        _text(card.text),
        if (card.en != null) _EnLine(card.en!, onTap: () => _sayEn(card.en!)),
      ]);

  Widget _body(LessonBlock b, LessonContent c) => switch (b) {
        HookBlock(:final card, :final ask) => Column(children: [
            _card(card),
            if (ask != null) ...[
              const SizedBox(height: 10),
              Text('🤔 ${ar(ask)}',
                  textAlign: TextAlign.center, style: kidText(context.clampVw(21, 5.8, 29), color: AppColors.grape, height: 1.5)),
            ],
            if (voiceEnabled) _replay(_cardSpeech(b)),
          ]),
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
        TryBlock() => _taskBody(b, c),
        StoryBlock(:final title, :final pages) => Column(children: [
            _title(title),
            _card(pages[_step]),
            if (voiceEnabled) _replay(pages[_step].spoken),
          ]),
        PoemBlock(:final title, :final lines) => Column(children: [
            _title(title),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Pressable3D(
                  onTap: voiceEnabled ? () => _say(line) : null,
                  color: AppColors.paper2,
                  radius: 18,
                  depth: 4,
                  shadowColor: AppColors.shadow,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  semanticLabel: line,
                  child: Text('${voiceEnabled ? '🔊 ' : ''}${ar(line)}',
                      textAlign: TextAlign.center, style: kidText(context.clampVw(19, 5.2, 26), height: 1.5)),
                ),
              ),
            if (voiceEnabled) ...[
              const SizedBox(height: 8),
              Text('دوس على أي سطر وردّده بعده 🎤', style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
              _replay(lines),
            ],
          ]),
        ReadBlock(:final title, :final items) => Column(children: [
            _title(title),
            if (items[_step].visual != null) VisualView(items[_step].visual!),
            Text(ar(items[_step].text),
                textAlign: TextAlign.center, style: kidText(context.clampVw(40, 11, 60), height: 1.6)),
            const SizedBox(height: 10),
            if (voiceEnabled) ...[
              KidButton(_heard ? '🔊 اسمع تاني' : '🔊 اسمعها واتأكد', kind: BtnKind.ghost, onTap: () {
                _say(items[_step].spoken);
                setState(() => _heard = true);
              }),
              if (!_heard)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('اقرا لوحدك الأول 👀', style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
                ),
            ],
          ]),
        ActivityBlock(:final text) => Column(children: [
            const Text('👨‍👩‍👦', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 6),
            _text(text),
            const SizedBox(height: 12),
            if (ref.watch(progressProvider).lessonLogs[c.uid]?.activity == true)
              const SpeechBubble('✅ عملتوا النشاط — برافو!', kind: BubbleKind.ok)
            else
              KidButton('✅ عملنا النشاط', kind: BtnKind.ghost, onTap: () => _log(c, (l) => l.activity = true)),
          ]),
        SummaryBlock(:final points) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in points)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('✅ ${ar(p)}', style: kidText(context.clampVw(18, 5, 24), height: 1.5)),
              ),
            if (lessonStatus(ref.watch(progressProvider), c) == LessonStatus.helped)
              const NoteBox(Text('🔁 هنرجع للدرس ده تاني في المراجعة، وولي الأمر هيلاقيه في «محتاج مراجعة».')),
          ]),
      };

  Widget _taskBody(TryBlock b, LessonContent c) {
    final t = b.tasks[_q];
    return Column(children: [
      _text(t.ask),
      const SizedBox(height: 8),
      if (t.visual != null) VisualView(t.visual!, ltr: t.en),
      TaskView(
        t,
        key: ValueKey('task:$_page:$_q'),
        seed: _page * 31 + _q,
        onWrong: (item) => _wrong(c, b, item),
        onSolved: () => _right(b),
      ),
      if (_solved)
        SpeechBubble('👏 ${ar(t.why)}', kind: BubbleKind.ok)
      else if (_hint != null)
        SpeechBubble('🤔 ${ar(_hint!)}', kind: BubbleKind.no),
      // غلط مرتين: مثال أبسط
      if (!_solved && _tries >= 2 && t.help != null)
        NoteBox(Column(children: [
          const Text('💡 خلّينا نشوف مثال أسهل'),
          const SizedBox(height: 6),
          _card(t.help!),
          if (voiceEnabled) _replay(t.help!.spoken),
        ])),
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
