/// أنشطة السورة الأربعة: الاستماع، الترديد، الحفظ، المراجعة.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/quran_config.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/dashed_box.dart';
import '../../core/widgets/fx_layer.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/progress_controller.dart';
import 'quran_screens.dart';
import 'quran_widgets.dart';
import 'recitation.dart';

/// الشاشة اللي بتفتح أي نشاط — [mode] من quranModes.
class QuranModeScreen extends StatelessWidget {
  const QuranModeScreen({super.key, required this.surah, required this.mode});
  final int surah;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final m = quranModes.firstWhere((x) => x.id == mode, orElse: () => quranModes.first);
    return SurahLoader(
      surah: surah,
      title: '${m.icon} ${m.name}',
      builder: (context, chapter, ayahs) => switch (m.id) {
        'repeat' => _Repeat(chapter: chapter, ayahs: ayahs),
        'memorize' => _Memorize(chapter: chapter, ayahs: ayahs),
        'review' => _Review(chapter: chapter, ayahs: ayahs),
        _ => _Listen(chapter: chapter, ayahs: ayahs),
      },
    );
  }
}

/// أساس مشترك: التلاوة، الفقاعة، والختام.
abstract class _ModeState<T extends ConsumerStatefulWidget> extends ConsumerState<T> {
  String bubble = '';
  BubbleKind bubbleKind = BubbleKind.plain;
  String? finished;
  LionMood lion = LionMood.idle;
  int lionTick = 0;

  QuranChapter get chapter;

  /// بيتمسك في initState — ref مينفعش يتقري في dispose.
  late final RecitationPlayer player;

  @override
  void initState() {
    player = ref.read(recitationProvider);
    super.initState();
  }

  void say(String text, [BubbleKind kind = BubbleKind.plain]) => setState(() {
        bubble = text;
        bubbleKind = kind;
      });

  void play(int ayah, {String? reciter, VoidCallback? onEnd}) => player.play(
        surah: chapter.number,
        ayah: ayah,
        reciterId: reciter ?? ref.read(reciterProvider).reciter,
        onEnd: onEnd,
        onIssue: (i) {
          if (!mounted) return;
          i == RecitationIssue.teacherFallback
              ? say('تلاوة المعلّم مش متاحة دلوقتي — بنشغّل القارئ العادي 🎙️', BubbleKind.no)
              : say('مش قادر أشغّل التلاوة — اتأكد من النت 📡', BubbleKind.no);
        },
      );

  /// النشاط بيدّي نجومه مرة واحدة — وبعدين نشيّك الإنجازات (الويب ماكانش بيشيّكها هنا).
  void complete(String mode, int stars, String text) {
    final progress = ref.read(progressProvider.notifier);
    if (stars > 0) progress.update((p) => p.quranMark(chapter.number, mode, stars));
    progress.checkRewards();
    finish(text);
  }

  void finish(String text) {
    player.stop();
    ref.read(sfxProvider).win();
    ref.read(fxProvider)
      ..confetti(50)
      ..popMsg('🌟 ما شاء الله!', big: true);
    setState(() => finished = text);
  }

  /// "تاني" بيعيد نفس النشاط (في الويب كان بيرجع لشاشة السورة).
  void restart();

  @override
  void dispose() {
    player.stop();
    super.dispose();
  }

  Widget buildMode(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (finished != null) {
      return QCard(
        child: Column(children: [
          const LionMascot(emoji: '🌟', mood: LionMood.cheer),
          const SizedBox(height: 8),
          Text(finished!, textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30))),
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('🔁 تاني', onTap: () => setState(() {
              finished = null;
              restart();
            })),
            KidButton('📖 ${chapter.name}', kind: BtnKind.go, onTap: () => context.back()),
            KidButton('🗺️ كل السور', kind: BtnKind.ghost, onTap: () {
              context.go('/quran');
            }),
          ]),
        ]),
      );
    }
    return Column(children: [
      buildMode(context),
      if (lion != LionMood.idle || bubble.isNotEmpty) ...[
        const SizedBox(height: 6),
        LionMascot(mood: lion, tick: lionTick),
      ],
      if (bubble.isNotEmpty) SpeechBubble(bubble, kind: bubbleKind),
    ]);
  }
}

// ---------------------------------------------------------------- ١) الاستماع

class _Listen extends ConsumerStatefulWidget {
  const _Listen({required this.chapter, required this.ayahs});
  final QuranChapter chapter;
  final List<Ayah> ayahs;

  @override
  ConsumerState<_Listen> createState() => _ListenState();
}

class _ListenState extends _ModeState<_Listen> {
  int idx = 0;
  bool playing = false;
  late final _keys = [for (final _ in widget.ayahs) GlobalKey()];

  @override
  QuranChapter get chapter => widget.chapter;

  @override
  void initState() {
    super.initState();
    bubble = 'آية ${ar(1)} من ${ar(widget.ayahs.length)}';
  }

  @override
  void restart() {
    idx = 0;
    playing = false;
    bubble = 'آية ${ar(1)} من ${ar(widget.ayahs.length)}';
  }

  void _mark() {
    say('آية ${ar(idx + 1)} من ${ar(widget.ayahs.length)}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _keys[idx].currentContext;
      if (c != null) Scrollable.ensureVisible(c, alignment: .5, duration: const Duration(milliseconds: 300));
    });
  }

  void _step() {
    if (!mounted) return;
    if (idx >= widget.ayahs.length) {
      setState(() {
        idx = 0;
        playing = false;
      });
      complete('listen', 1, 'خلّصت السورة كلها! ⭐');
      return;
    }
    _mark();
    play(widget.ayahs[idx].number, onEnd: () {
      if (playing && mounted) {
        idx++;
        _step();
      }
    });
  }

  void _toggle() {
    setState(() => playing = !playing);
    playing ? _step() : player.stop();
  }

  void _go(int to) {
    setState(() => idx = to.clamp(0, widget.ayahs.length - 1));
    playing ? _step() : _mark();
  }

  @override
  Widget buildMode(BuildContext context) => Column(children: [
        QCard(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .52),
            child: SingleChildScrollView(
              child: Column(children: [
                for (var i = 0; i < widget.ayahs.length; i++)
                  AyahBox(
                    widget.ayahs[i],
                    key: _keys[i],
                    active: i == idx,
                    onTap: () {
                      setState(() => idx = i);
                      _mark();
                      play(widget.ayahs[i].number);
                    },
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 14, children: [
          // في RTL الزرار اللي على اليمين هو "السابق"
          PlayerButton('⏮', semantic: 'الآية اللي قبلها', onTap: () => _go(idx - 1)),
          PlayerButton(playing ? '⏸' : '▶️', main: true, semantic: playing ? 'إيقاف' : 'تشغيل', onTap: _toggle),
          PlayerButton('⏭', semantic: 'الآية اللي بعدها', onTap: () => _go(idx + 1)),
        ]),
      ]);
}

// ---------------------------------------------------------------- ٢) الترديد

class _Repeat extends ConsumerStatefulWidget {
  const _Repeat({required this.chapter, required this.ayahs});
  final QuranChapter chapter;
  final List<Ayah> ayahs;

  @override
  ConsumerState<_Repeat> createState() => _RepeatState();
}

class _RepeatState extends _ModeState<_Repeat> {
  int idx = 0;

  @override
  QuranChapter get chapter => widget.chapter;

  String get rKey => ref.read(reciterProvider).repeat;

  @override
  void initState() {
    super.initState();
    lion = LionMood.cheer;
    _draw();
  }

  @override
  void restart() {
    idx = 0;
    _draw();
  }

  void _draw() {
    bubble = 'آية ${ar(idx + 1)} من ${ar(widget.ayahs.length)}';
    bubbleKind = BubbleKind.plain;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play(widget.ayahs[idx].number, reciter: rKey);
    });
  }

  @override
  Widget buildMode(BuildContext context) {
    final a = widget.ayahs[idx];
    final repeat = ref.watch(reciterProvider).repeat;
    final teach = QuranConfig.reciter(repeat).teacher;
    final options = [
      ...QuranConfig.reciters.where((r) => r.teacher),
      ...QuranConfig.reciters.where((r) => !r.teacher),
    ];
    return Column(children: [
      AyahDots(count: widget.ayahs.length, current: idx),
      QCard(
        key: ValueKey(idx),
        child: Column(children: [
          AyahBox(a, active: true, big: true),
          Text(teach ? 'اسمع الشيخ والأطفال، وردّد معاهم 🗣️' : 'اسمع الآية، وبعدين ردّدها بصوتك 🗣️',
              textAlign: TextAlign.center, style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 10, children: [
            PlayerButton('🔊 اسمع', main: true, onTap: () => play(a.number, reciter: rKey)),
            PlayerButton('✅ ردّدتها', ok: true, onTap: () {
              ref.read(sfxProvider).good();
              if (idx + 1 >= widget.ayahs.length) {
                complete('repeat', 2, 'ما شاء الله! ردّدت السورة كلها 🌟');
              } else {
                setState(() {
                  idx++;
                  lionTick++;
                  _draw();
                });
              }
            }),
          ]),
        ]),
      ),
      ReciterPicker(
        label: '🎙️ ترديد مع',
        value: repeat,
        options: options,
        onChanged: (id) {
          ref.read(reciterProvider.notifier).setRepeat(id);
          play(a.number, reciter: id);
        },
      ),
    ]);
  }
}

// ---------------------------------------------------------------- ٣) الحفظ

class _Memorize extends ConsumerStatefulWidget {
  const _Memorize({required this.chapter, required this.ayahs});
  final QuranChapter chapter;
  final List<Ayah> ayahs;

  @override
  ConsumerState<_Memorize> createState() => _MemorizeState();
}

class _MemorizeState extends _ModeState<_Memorize> {
  int idx = 0, right = 0, wrongIdx = -1, wrongTick = 0;
  bool missed = false, locked = false;
  late List<String> words;
  late List<int> bank;
  final used = <int>{};
  int picked = 0;

  @override
  QuranChapter get chapter => widget.chapter;

  @override
  void initState() {
    super.initState();
    _draw();
  }

  @override
  void restart() {
    idx = 0;
    right = 0;
    _draw();
  }

  void _draw() {
    // التقسيم على المسافات فقط — الكلمات نفسها كما وردت بالضبط
    words = ayahWords(widget.ayahs[idx].text);
    bank = ref.read(rngProvider).shuffle([for (var i = 0; i < words.length; i++) i]);
    used.clear();
    picked = 0;
    missed = false;
    locked = false;
    bubble = 'آية ${ar(idx + 1)} من ${ar(widget.ayahs.length)}';
    bubbleKind = BubbleKind.plain;
    lion = LionMood.idle;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play(widget.ayahs[idx].number);
    });
  }

  void _tap(int i) {
    if (locked || used.contains(i)) return;
    // الكلمة بتتقارن بنصها، مش بمكانها — لو الكلمة متكررة في الآية أي نسخة منها صح
    if (words[i] == words[picked]) {
      setState(() {
        used.add(i);
        picked++;
      });
      ref.read(sfxProvider).good();
      if (picked == words.length) {
        locked = true;
        if (!missed) right++;
        setState(() {
          lion = LionMood.cheer;
          lionTick++;
        });
        say('أحسنت! ما شاء الله 🌟', BubbleKind.ok);
        Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          if (idx + 1 >= widget.ayahs.length) {
            complete('memorize', 3, 'ختمت حفظ السورة! ${ar(right)} من ${ar(widget.ayahs.length)} ⭐');
          } else {
            setState(() {
              idx++;
              _draw();
            });
          }
        });
      }
    } else {
      missed = true;
      ref.read(sfxProvider).bad();
      setState(() {
        wrongIdx = i;
        wrongTick++;
        lion = LionMood.sad;
        lionTick++;
      });
      say('مش دي الكلمة اللي بعدها — اسمع الآية تاني 🔊', BubbleKind.no);
    }
  }

  @override
  Widget buildMode(BuildContext context) {
    final style = TextStyle(fontFamily: quranFont, fontSize: context.clampVw(20, 5, 26), height: 1.9, color: AppColors.ink);
    return Column(children: [
      AyahDots(count: widget.ayahs.length, current: idx),
      QCard(
        key: ValueKey('m$idx'),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text('رتّب كلمات الآية', style: kidText(context.clampVw(22, 6, 30)))),
            const SizedBox(width: 10),
            PlayerButton('🔊', semantic: 'اسمع الآية', onTap: () => play(widget.ayahs[idx].number)),
          ]),
          const SizedBox(height: 14),
          // خانات الكلمات
          DashedBox(
            color: AppColors.line,
            width: 3,
            radius: 18,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minHeight: 62, minWidth: double.infinity),
            child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (var k = 0; k < words.length; k++)
                k < picked
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: quranMint, borderRadius: BorderRadius.circular(12)),
                        child: Text(words[k], style: style.copyWith(color: Colors.white)),
                      ).animate().scaleXY(begin: 1.18, end: 1, duration: 300.ms)
                    : const DashedBox(
                        color: AppColors.line,
                        width: 2,
                        radius: 12,
                        dash: 5,
                        gap: 4,
                        child: SizedBox(width: 56, height: 38),
                      ),
            ]),
          ),
          const SizedBox(height: 14),
          // بنك الكلمات
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
            for (final i in bank) _word(i, style),
          ]),
        ]),
      ),
    ]);
  }

  Widget _word(int i, TextStyle style) {
    final isUsed = used.contains(i);
    final wrong = wrongIdx == i;
    final w = GestureDetector(
      onTap: () => _tap(i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 3),
        ),
        child: Text(words[i], style: style),
      ),
    );
    if (isUsed) return Opacity(opacity: .25, child: IgnorePointer(child: w));
    if (wrong) return w.animate(key: ValueKey('w$wrongTick')).shakeX(hz: 5, amount: 9, duration: 400.ms);
    return w;
  }
}

// ---------------------------------------------------------------- ٤) المراجعة

class _Review extends ConsumerStatefulWidget {
  const _Review({required this.chapter, required this.ayahs});
  final QuranChapter chapter;
  final List<Ayah> ayahs;

  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends _ModeState<_Review> {
  int q = 0, right = 0, i = 0;
  bool missed = false, locked = false;
  late List<Ayah> opts;
  int? rightNo, wrongNo;
  int wrongTick = 0;

  @override
  QuranChapter get chapter => widget.chapter;

  int get total => (widget.ayahs.length - 1).clamp(0, 5);

  @override
  void initState() {
    super.initState();
    if (widget.ayahs.length >= 3) _draw();
  }

  @override
  void restart() {
    q = 0;
    right = 0;
    _draw();
  }

  void _draw() {
    final rng = ref.read(rngProvider);
    final a = widget.ayahs;
    i = rng.rnd(0, a.length - 2);
    final correct = a[i + 1];
    // الاختيارات كلها آيات حقيقية من نفس السورة — مفيش أي نص مُولَّد
    final others = a.where((x) => x.number != correct.number && x.number != a[i].number).toList();
    opts = rng.shuffle([correct, ...rng.shuffle(others).take(2)]);
    missed = false;
    locked = false;
    rightNo = null;
    wrongNo = null;
    bubble = 'سؤال ${ar(q + 1)} من ${ar(total)}';
    bubbleKind = BubbleKind.plain;
  }

  void _pick(Ayah o) {
    if (locked) return;
    final correct = widget.ayahs[i + 1];
    if (o.number == correct.number) {
      locked = true;
      // بتتحسب صح لو من أول محاولة بس — في الويب كانت أي إجابة صح بتتحسب فالمراجعة ماكانتش بتفشل أبدًا
      if (!missed) right++;
      ref.read(sfxProvider).good();
      setState(() {
        rightNo = o.number;
        lion = LionMood.cheer;
        lionTick++;
      });
      say(missed ? 'أحسنت! ❤️' : 'صح! ⭐', BubbleKind.ok);
      play(correct.number);
      Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        q++;
        if (q >= total) {
          final pass = right >= (total * .8).ceil();
          complete('review', pass ? 2 : 0,
              '${ar(right)} من ${ar(total)} — ${pass ? 'ما شاء الله! 🌟' : 'كمّل مراجعة ❤️'}');
        } else {
          setState(_draw);
        }
      });
    } else {
      missed = true;
      ref.read(sfxProvider).bad();
      setState(() {
        wrongNo = o.number;
        wrongTick++;
        lion = LionMood.sad;
        lionTick++;
      });
      say('مش دي — اسمع الآية تاني ❤️', BubbleKind.no);
    }
  }

  @override
  Widget buildMode(BuildContext context) {
    if (widget.ayahs.length < 3) {
      return QCard(
        child: Column(children: [
          const Text('🙂', style: TextStyle(fontSize: 64)),
          Text('السورة دي قصيرة قوي على المراجعة', textAlign: TextAlign.center, style: kidText(20)),
          const SizedBox(height: 12),
          KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back()),
        ]),
      );
    }
    final style = TextStyle(fontFamily: quranFont, fontSize: context.clampVw(19, 4.8, 24), height: 2, color: AppColors.ink);
    return Column(children: [
      AyahDots(count: total, current: q),
      QCard(
        key: ValueKey('r$q'),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text('إيه الآية اللي بعدها؟', style: kidText(context.clampVw(22, 6, 30)))),
            const SizedBox(width: 10),
            PlayerButton('🔊', semantic: 'اسمع الآية', onTap: () => play(widget.ayahs[i].number)),
          ]),
          const SizedBox(height: 14),
          AyahBox(widget.ayahs[i], active: true),
          const SizedBox(height: 4),
          for (final o in opts) ...[
            _choice(o, style),
            const SizedBox(height: 10),
          ],
        ]),
      ),
    ]);
  }

  Widget _choice(Ayah o, TextStyle style) {
    final isRight = rightNo == o.number, isWrong = wrongNo == o.number;
    final box = GestureDetector(
      onTap: () => _pick(o),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isRight ? AppColors.okBg : (isWrong ? AppColors.noBg : AppColors.paper2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRight ? const Color(0xFF2ECC71) : (isWrong ? AppColors.coral : AppColors.line),
            width: 3,
          ),
        ),
        child: Text(o.text, textAlign: TextAlign.center, style: style),
      ),
    );
    return isWrong ? box.animate(key: ValueKey('rw$wrongTick')).shakeX(hz: 5, amount: 9, duration: 400.ms) : box;
  }
}
