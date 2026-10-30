/// إدارة الجولة والأسئلة والنجوم — منقول من js/gameEngine.js.
///
/// المحرك بيحتفظ بحالة الجولة (GameSession) ويبعت أحداث مؤثرات (GameFx) للواجهة.
/// كل المؤقتات بتتلغي لما الطفل يخرج من الشاشة (autoDispose) — في الويب كانت بتفضل شغالة.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/math_data.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/sfx_service.dart';
import '../../core/audio/speech_service.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/ui_state.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../progress/learning_time.dart';
import '../progress/progress_controller.dart';
import '../paths.dart';
import '../placement.dart';
import '../progress/progress_data.dart';
import '../question.dart';
import '../stages.dart';

enum DotState { pending, done, miss }

class GameResult {
  const GameResult({
    required this.stage,
    required this.correct,
    required this.total,
    required this.mistakes,
    required this.unlocked,
    required this.practice,
    this.placed,
  });
  final Stage stage;
  final int correct;
  final int total;
  final List<String> mistakes;
  final Stage? unlocked;
  final bool practice;

  /// اختبار تحديد المستوى: الدرجة اللي وصلها الطفل ("تانية ابتدائي").
  final String? placed;

  int get pct => (correct / total * 100).round();
  bool get good => pct >= 80;
}

/// أحداث المؤثرات — `anchor` بيحدد العنصر اللي المؤثر يطلع منه ('c2' = الاختيار التالت…).
sealed class GameFx {
  const GameFx();
}

class FxCorrect extends GameFx {
  const FxCorrect(this.anchor, {required this.firstTry, required this.streak});
  final String? anchor;
  final bool firstTry;
  final int streak;
}

class FxWrong extends GameFx {
  const FxWrong(this.anchor, {this.gentle = false});
  final String? anchor;

  /// المدود: تشجيع لطيف (💪) من غير ومضة حمرا.
  final bool gentle;
}

class FxFill extends GameFx {
  const FxFill(this.anchor);
  final String anchor;
}

class GameSession {
  GameSession(this.stage, this.level, this.practice, this.list) : dots = List.filled(list.length, DotState.pending);

  final Stage stage;
  final int level;
  final bool practice;
  final List<Question> list;
  final List<DotState> dots;

  int idx = 0, correct = 0, tries = 0, streak = 0;

  /// وقت النهاردة خلص بين سؤالين — الشاشة بتروح لـ "وقت الراحة".
  bool timeUp = false;

  /// الأسئلة اللي اتحلّت في الجولة (حتى بعد غلطة) — البازل بيكشف قطعة مع كل واحد.
  int solved = 0;
  final mistakes = <String>[];

  // حالة السؤال الحالي
  final picked = <Object>[];
  final used = <int>{};
  int? sel;
  final matchedLeft = <int>{}, matchedRight = <int>{};
  final circled = <int>{};
  final flipped = <int>{}, memMatched = <int>{};
  int? memFirst;
  bool memLock = false;
  bool locked = false;

  /// المرئيات اتبدّلت بـ revealVisuals بعد الإجابة الصح.
  bool revealed = false;

  /// وضع sort: البطاقة ← الصندوق اللي اتحطت فيه.
  final placed = <int, String>{};

  /// لوّن بالأرقام: اللون المختار والخانات اللي اتلوّنت.
  int? paintSel;
  final painted = <int>{};

  /// كرر الإيقاع: ممنوع الضغط وهو بيشتغل، والطبلة اللي بتنور دلوقتي (+ عدّاد عشان الوميض يتعاد).
  bool rhythmLock = false;
  int? padLit;
  int padTick = 0;

  /// فين القطة؟: خانة كل كوباية، الأكواب المرفوعة، والطفل يقدر يختار ولا لسه بتتبدّل.
  final cupSlots = <int>[];
  final cupLifted = <int>{};
  bool cupReady = false;

  /// المتاهة: خانة الأرنب، والخانات اللي عدّى عليها، وعدّاد الخبطة في الحيطة.
  int mazeAt = 0;
  final mazeTrail = <int>[];
  int mazeBump = 0;

  /// ارسم بصباعك: بيزيد لما الرسمة تتمسح عشان اللوحة تبدأ من الأول.
  int traceTick = 0;

  /// سودوكو: الخانة المختارة واللي الطفل ملاه.
  int? sudokuSel;
  final sudokuVals = <int, int>{};

  /// برج هانوي: الحلقات على كل عمود (من تحت لفوق)، والعمود اللي اتشال منه، وعدد الحركات.
  final pegs = <List<int>>[];
  int? hanoiHeld;
  int moves = 0;

  /// البازل المنزلق: الترتيب الحالي (٠ = الفاضية)، وعدّاد الضغطة اللي مالهاش معنى.
  final slideTiles = <int>[];
  int puzzleBump = 0;
  Object? hintTarget;
  String? wrongAnchor, rightAnchor;
  int wrongTick = 0, shakeTick = 0;

  String bubble = '';
  BubbleKind bubbleKind = BubbleKind.plain;
  LionMood lion = LionMood.idle;
  int lionTick = 0;

  GameResult? result;

  Question get q => list[idx];
  int get total => list.length;

  void resetQuestion() {
    tries = 0;
    picked.clear();
    used.clear();
    sel = null;
    matchedLeft.clear();
    matchedRight.clear();
    circled.clear();
    flipped.clear();
    memMatched.clear();
    memFirst = null;
    memLock = false;
    locked = false;
    revealed = false;
    placed.clear();
    paintSel = null;
    painted.clear();
    rhythmLock = false;
    padLit = null;
    cupSlots.clear();
    cupLifted.clear();
    cupReady = false;
    mazeAt = q.mazeStart;
    mazeTrail
      ..clear()
      ..add(q.mazeStart);
    sudokuSel = null;
    sudokuVals.clear();
    pegs
      ..clear()
      ..addAll([
        [for (var d = q.discs; d >= 1; d--) d],
        <int>[],
        <int>[],
      ]);
    hanoiHeld = null;
    moves = 0;
    slideTiles
      ..clear()
      ..addAll(q.slideStart);
    hintTarget = null;
    wrongAnchor = null;
    rightAnchor = null;
    lion = LionMood.idle;
  }
}

class GameEngine extends Notifier<GameSession?> {
  final _timers = <Timer>[];
  (ValueListenable<bool>, VoidCallback)? _speechWait;
  final _fx = StreamController<GameFx>.broadcast();

  Stream<GameFx> get fx => _fx.stream;

  @override
  GameSession? build() {
    final speech = ref.read(speechProvider);
    ref.onDispose(() {
      _cancelTimers();
      speech.stop();
      _fx.close();
    });
    return null;
  }

  @override
  bool updateShouldNotify(GameSession? previous, GameSession? next) => true;

  Speech get _speech => ref.read(speechProvider);
  Sfx get _sfx => ref.read(sfxProvider);
  Rng get _rng => ref.read(rngProvider);
  ProgressController get _progress => ref.read(progressProvider.notifier);
  LearningTimer get _time => ref.read(learningTimeProvider);
  GameSession get _s => state!;

  void _emit() => state = state;

  void _later(int ms, void Function() f) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      f();
    });
    _timers.add(t);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    if (_speechWait case (final speaking, final listener)) speaking.removeListener(listener);
    _speechWait = null;
  }

  /// أقصى وقت بنستنى فيه الكلام يخلص قبل السؤال الجاي، والسكتة بعده.
  static const speechWaitMaxMs = 7000, speechGapMs = 300;

  /// [f] بعد [ms] على الأقل، وبعد ما الكلام اللي شغّال (المدح أو الشرح) يخلص —
  /// عشان السؤال الجاي مايقطعهوش في النص.
  void _afterSpeech(int ms, void Function() f) {
    _later(ms, () {
      final speaking = _speech.speaking;
      if (!speaking.value) return f();
      var fired = false;
      void go() {
        if (fired) return;
        fired = true;
        if (_speechWait case (final sp, final l)) sp.removeListener(l);
        _speechWait = null;
        f();
      }

      void listener() {
        if (!speaking.value) _later(speechGapMs, go);
      }

      speaking.addListener(listener);
      _speechWait = (speaking, listener);
      _later(speechWaitMaxMs, go);
    });
  }

  // ------------------------------------------------------------------ الجولة

  void start(String stageId, {bool practice = false, List<String>? types}) {
    _cancelTimers();
    _speech.stop();
    final stage = packs[stageId]!;
    final p = _progress.data;
    final level = roundLevel(p, stage);
    // مراحل طويلة (زي الجدول الفاضي) ممكن تحدّد عدد أسئلتها بنفسها
    final count = practice ? practiceCount : (stage.count ?? questionsPerRound);
    final list = <Question>[];
    if (!practice && isPlacement(stage.id)) {
      // اختبار المستوى: سؤالين من كل درجة بالترتيب، من غير تعلّم متكيّف
      list.addAll(placementRound(stage.world, _rng));
    } else if (practice && types != null && types.isNotEmpty) {
      for (var i = 0; i < count; i++) {
        list.add(makeQuestion(_rng.sample(types), level, _rng, progress: p));
      }
    } else {
      final focus = p.focus(stage.id);
      for (var i = 0; i < count; i++) {
        // تدرّج لطيف داخل الجولة: آخر سؤالين أصعب قليلًا
        final lv = i >= count - 2 ? math.min(level + 1, 4) : level;
        // تعلّم متكيّف: لو فيه مهارة الطفل بيغلط فيها، نرجّعها له
        final f = (focus != null && _rng.chance(.45)) ? focus : null;
        list.add(makeQuestion(stage.id, lv, _rng, focus: f, progress: p));
      }
    }
    state = GameSession(stage, level, practice, list);
    // "تاني" أو "درّب على أخطائك" بعد ما الوقت خلص
    if (_time.checkpoint()) {
      _s.timeUp = true;
      _emit();
      return;
    }
    _render();
  }

  void replay() => start(_s.stage.id);

  void trainMistakes() => start(_s.stage.id, practice: true, types: [..._s.mistakes]);

  void _render() {
    final s = _s..resetQuestion();
    s.bubble = '${s.stage.icon} سؤال ${ar(s.idx + 1)} من ${ar(s.total)}';
    s.bubbleKind = BubbleKind.plain;
    // الإيقاع: الطبول مقفولة لحد ما الطفل يسمع السلسلة الأول
    s.rhythmLock = s.q.mode == QMode.rhythm;
    _emit();
    final q = s.q;
    if (q.mode == QMode.rhythm) _later(1200, rhythmPlay);
    if (q.mode == QMode.cups) _cupsShow();
    if (q.isEnglish) {
      _speech.speakEn(q.speak);
    } else {
      // المقدمة جزء من المقاطع كمان، وإلا كانت بتضيع لما السؤال ليه مقاطع
      final intro = s.idx == 0 ? sayStageIntro(s.stage.name) : null;
      _speech.speak(intro != null ? [intro, q.speak] : q.speak,
          clips: intro != null && q.clips != null ? [say(intro), ...q.clips!] : q.clips);
    }
  }

  /// زرار 🔊 يعيد نطق السؤال.
  void repeat() {
    final q = _s.q;
    q.isEnglish ? _speech.speakEn(q.speak) : _speech.speak(q.speak, clips: q.clips);
  }

  void _say(Question q, List<String> ar, {List<String?>? clips, List<String>? en}) =>
      q.isEnglish ? _speech.speakEn(en ?? ar) : _speech.speak(ar, clips: clips);

  // ------------------------------------------------------------------ النجوم والإحصاء

  /// إجابة صح من أول محاولة: نجمة محسوبة على عالم المرحلة + إحصائية فورية.
  void _award() => _progress.update((p) {
        p
          ..addStar(1, _s.stage.world)
          ..addAnswer(ok: true);
        _maddRecord(p, ok: true);
      });

  /// أول غلطة في السؤال بس — عشان السؤال الواحد ما يتحسبش غلط أكتر من مرة.
  void _penalize() => _progress.update((p) {
        p.addAnswer(ok: false);
        _maddRecord(p, ok: false);
      });

  /// المدود ليها إحصائيات خاصة: نتيجة أول محاولة لكل نوع وكل كلمة.
  void _maddRecord(ProgressData p, {required bool ok}) {
    if (!_s.stage.isMadd) return;
    p.madd.record(type: _s.q.mtype, word: _s.q.mword, stageId: _s.stage.id, ok: ok);
  }

  void _hit(String? skill) => _progress.update((p) => p.hit(_s.stage.id, skill));
  void _miss(String? skill) => _progress.update((p) => p.miss(_s.stage.id, skill));

  void _markMistake(Question q) {
    if (!_s.mistakes.contains(q.type)) _s.mistakes.add(q.type);
  }

  /// نجاح السؤال بأي وضع — نفس الحساب في كل مكان.
  void _solved({String? anchor, bool playSfx = true, String? skill, int delay = 1400}) {
    final s = _s;
    final first = s.tries == 0;
    if (first) s.correct++;
    s.solved++;
    s.streak = first ? s.streak + 1 : 0;
    if (first) {
      _hit(skill);
      _award();
    }
    s
      ..locked = true
      ..hintTarget = null
      ..rightAnchor = anchor
      ..dots[s.idx] = first ? DotState.done : DotState.miss
      ..bubble = s.q.okMsg ?? (first ? _rng.sample(praise) : 'أحسنت! وصلت للإجابة 👏')
      ..bubbleKind = BubbleKind.ok
      ..revealed = s.q.revealVisuals != null
      ..lion = LionMood.cheer
      ..lionTick += 1;
    _emit();
    _fx.add(FxCorrect(anchor, firstTry: first, streak: s.streak));
    if (playSfx) (first && s.streak >= 3) ? _sfx.combo() : _sfx.good();
    _afterSpeech(delay, _next);
  }

  void _wrongUi(Question q, String? anchor, {bool allowHint = true}) {
    final s = _s
      ..bubble = '${_rng.sample(retry)} — ${q.hint}'
      ..bubbleKind = BubbleKind.no
      ..lion = LionMood.sad
      ..lionTick += 1
      ..wrongAnchor = anchor
      ..wrongTick += 1
      ..shakeTick += 1;
    // بعد محاولتين: نلمّع الإجابة الصحيحة بدل العقاب
    if (allowHint && s.tries >= 2) {
      s.hintTarget = q.answer is List ? q.answerList[s.picked.length] : q.answer;
    }
    _emit();
    _fx.add(FxWrong(anchor, gentle: q.gentle));
    _sfx.bad();
    final tick = s.wrongTick;
    _later(420, () {
      if (state != null && _s.wrongTick == tick) {
        _s.wrongAnchor = null;
        _emit();
      }
    });
  }

  // ------------------------------------------------------------------ الأوضاع

  /// وضع الاختيار.
  void answer(int i) {
    final s = _s, q = s.q;
    if (s.locked) return;
    final value = q.choices[i];
    final said = q.choiceSay[value] ?? (value is int ? arNum(value) : (signWord[value] ?? '$value'));
    // الحرف أو الكلمة اللي اختارها بتتنطق بمقطع التعليم لو موجود
    final valueClip = q.choiceSay.containsKey(value) ? say(said) : (value is int ? nk(value) : signClip[value] ?? say(said));
    if (value == q.answer) {
      final pr = _rng.sample(praiseSay);
      _solved(anchor: 'c$i', skill: q.skill);
      // الإنجليزي بيتشكر بالإنجليزي، والاختيار اللي ليه اسم (صورة) بيتقال باسمه
      final enSaid = q.choiceSay[value] ?? '$value';
      q.sayRight != null
          ? _say(q, [q.sayRight!, pr.$1], en: [q.sayRight!, 'Very good!'])
          : _say(q, [said, pr.$1], clips: [valueClip, pr.$2], en: [enSaid, 'Very good!']);
    } else {
      s.tries++;
      s.streak = 0;
      if (s.tries == 1) {
        _markMistake(q);
        _miss(q.skill);
        _penalize();
      }
      _wrongUi(q, 'c$i');
      // من غير مقاطع للتلميح بنروح لمقاطع الجُمل الكاملة عشان التلميح مايضيعش
      _say(q, [said, sayRetry, q.speakHint ?? q.hint],
          clips: q.clipsHint == null ? null : [valueClip, 'retry', ...q.clipsHint!],
          en: [q.choiceSay[value] ?? '$value', 'Try again', q.speakHint ?? '']);
    }
  }

  /// ترتيب وجداول: تحقّق فوري عند كل ضغطة.
  void pick(int i) {
    final s = _s, q = s.q;
    if (s.locked || s.used.contains(i)) return;
    final value = q.items[i];
    final expected = q.answerList[s.picked.length];
    // الويب كان بينطق "NaN" للحروف لأنه بيحوّل أي قيمة لرقم
    final said = q.choiceSay[value] ?? (value is int ? arNum(value) : '$value');
    final valueClip = q.choiceSay.containsKey(value) ? say(said) : nk(value) ?? say(said);
    if (value == expected) {
      s.picked.add(value);
      s.used.add(i);
      s.hintTarget = null;
      _fx.add(FxFill('i$i'));
      _sfx.good();
      if (s.picked.length == q.answerList.length) {
        final pr = _rng.sample(praiseSay);
        _solved(skill: q.skill, playSfx: false);
        q.sayRight != null
            ? _say(q, [q.sayRight!, pr.$1])
            : _say(q, [said, pr.$1], clips: [valueClip, pr.$2], en: [said, 'Very good!']);
      } else {
        _emit();
        _say(q, [said], clips: [valueClip]);
      }
    } else {
      s.tries++;
      if (s.tries == 1) {
        _markMistake(q);
        _miss(q.skill);
        _penalize();
      }
      _wrongUi(q, 'i$i');
      _say(q, [said, sayRetry, q.speakHint ?? q.hint],
          clips: q.clipsHint == null ? null : [valueClip, 'retry', ...q.clipsHint!],
          en: [said, 'Try again', q.speakHint ?? '']);
    }
  }

  /// وضع التوصيل: اختار من العمود الأول ثم ما يقابله في التاني.
  void pairPick({required bool left, required int i}) {
    final s = _s, q = s.q;
    if (s.locked) return;
    if (left) {
      if (s.matchedLeft.contains(i)) return;
      s.sel = i;
      _emit();
      _say(q, ['${q.items[i]}']);
      return;
    }
    if (s.matchedRight.contains(i)) return;
    final sel = s.sel;
    if (sel == null) {
      s
        ..bubble = q.isEnglish ? 'Tap a big letter first 👆' : 'اضغط الكلمة الأول 👆'
        ..bubbleKind = BubbleKind.plain;
      _emit();
      _sfx.bad();
      return;
    }
    final leftVal = '${q.items[sel]}', rightVal = q.right[i];
    // المهارة بتتسجّل على العنصر اللي الطفل اشتغل عليه فعلاً، مش على المجموعة كلها
    final sk = q.skillOf?.call(leftVal) ?? q.skill;
    if (q.pairMap[leftVal] == rightVal) {
      s
        ..matchedLeft.add(sel)
        ..matchedRight.add(i)
        ..sel = null;
      _hit(sk);
      if (s.matchedLeft.length == q.items.length) {
        _solved(delay: 1200);
      } else {
        s
          ..bubble = '${ar(s.matchedLeft.length)} / ${ar(q.items.length)} ✅'
          ..bubbleKind = BubbleKind.ok;
        _emit();
        _sfx.good();
      }
      _fx.add(FxFill('r$i'));
      _say(q, [rightVal]);
    } else {
      s
        ..tries += 1
        ..streak = 0
        ..sel = null;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(sk);
      _wrongUi(q, 'r$i', allowHint: false);
      _say(q, [sayRetry], clips: ['retry'], en: ['Try again']);
    }
  }

  /// ضع دائرة: الطفل يلاقي كل تكرارات الحرف.
  void findPick(int i) {
    final s = _s, q = s.q;
    if (s.locked || s.circled.contains(i)) return;
    final cell = q.cells[i];
    if (cell.hit) {
      s.circled.add(i);
      _say(q, [cell.ch]);
      if (s.circled.length == q.hits) {
        _solved(skill: q.skill, delay: 1200);
      } else {
        s
          ..bubble = '${ar(s.circled.length)} / ${ar(q.hits)} ✅'
          ..bubbleKind = BubbleKind.ok;
        _emit();
        _sfx.good();
      }
    } else {
      s.tries++;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(q.skill);
      _wrongUi(q, 'f$i', allowHint: false);
      _say(q, [sayNotThis], en: ['Not this one']);
    }
  }

  /// لعبة الأصحاب: اقلب كارتين ولاقي الحرف وصاحبه.
  void memoryPick(int i) {
    final s = _s, q = s.q;
    if (s.locked || s.memLock || s.memMatched.contains(i) || s.flipped.contains(i)) return;
    s.flipped.add(i);
    _say(q, [q.cards[i].ch]);
    final a = s.memFirst;
    if (a == null) {
      s.memFirst = i;
      _emit();
      return;
    }
    s.memFirst = null;
    final sk = q.skillOf?.call(q.cards[a].key) ?? q.skill;
    if (q.cards[a].key == q.cards[i].key) {
      s
        ..memMatched.addAll([a, i])
        ..flipped.removeAll([a, i]);
      _hit(sk);
      final found = s.memMatched.length ~/ 2;
      if (found == q.pairs) {
        _solved(delay: 1200);
      } else {
        s
          ..bubble = '${ar(found)} / ${ar(q.pairs)} ✅'
          ..bubbleKind = BubbleKind.ok;
        _emit();
        _sfx.good();
      }
    } else {
      s.tries++;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(sk);
      _sfx.bad();
      s
        ..bubble = q.isEnglish ? 'Not friends — try again ❤️' : 'مش أصحاب — جرّب تاني ❤️'
        ..bubbleKind = BubbleKind.no
        ..memLock = true;
      _emit();
      _later(1000, () {
        s
          ..flipped.removeAll([a, i])
          ..memLock = false;
        _emit();
      });
    }
  }

  // ------------------------------------------------------------------ عالم الألعاب

  /// لوّن بالأرقام: اختار علبة لون.
  void colorSelect(int n) {
    final s = _s;
    if (s.locked) return;
    s.paintSel = n;
    _emit();
    final pot = s.q.pots.firstWhere((p) => p.n == n);
    _speech.speak('${pot.name}، رقم ${arNum(n)}');
  }

  /// لوّن خانة باللون المختار — لو رقمها مختلف تبقى غلطة لطيفة.
  void colorPaint(int i) {
    final s = _s, q = s.q;
    if (s.locked || s.painted.contains(i)) return;
    final sel = s.paintSel;
    if (sel == null) {
      s
        ..bubble = 'اختار لون الأول 🎨'
        ..bubbleKind = BubbleKind.plain;
      _emit();
      _sfx.bad();
      return;
    }
    if (q.paintCells[i] == sel) {
      s.painted.add(i);
      if (s.painted.length == q.paintCells.length) {
        _solved(skill: q.skill, delay: 2200);
        _speech.speak('طلعت صورة ${q.picName}');
      } else {
        s
          ..bubble = '${ar(s.painted.length)} / ${ar(q.paintCells.length)} 🎨'
          ..bubbleKind = BubbleKind.ok;
        _emit();
        _sfx.good();
      }
    } else {
      s.tries++;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(q.skill);
      _wrongUi(q, 'p$i', allowHint: false);
      s
        ..bubble = 'الخانة دي رقم ${ar(q.paintCells[i])} — دوّر على رقم ${ar(sel)} ❤️'
        ..bubbleKind = BubbleKind.no;
      _emit();
    }
  }

  /// كرر الإيقاع: يدق السلسلة (طبلة كل ٧٠٠ مللي) وبعدين يدّي الدور للطفل.
  void rhythmPlay() {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.rhythm) return;
    s
      ..rhythmLock = true
      ..picked.clear()
      ..bubble = q.lights ? 'شوف كويس… 👀' : 'اسمع كويس… 👂'
      ..bubbleKind = BubbleKind.plain;
    _emit();
    for (var i = 0; i < q.beats.length; i++) {
      _later(400 + i * 700, () => _hitPad(q.beats[i]));
    }
    _later(400 + (q.beats.length - 1) * 700 + 500, () {
      if (state == null || _s.q != q || _s.locked) return;
      _s
        ..rhythmLock = false
        ..bubble = q.lights ? 'دورك! نوّر الألوان زيها 🎨' : 'دورك! كرّر الإيقاع 🥁'
        ..bubbleKind = BubbleKind.plain;
      _emit();
    });
  }

  void _hitPad(int k) {
    if (state == null) return;
    // كرر الألوان: النور لوحده من غير صوت، وبيطفي قبل اللي بعده عشان نفس اللون مرتين يبان
    if (!_s.q.lights) _sfx.pad(k);
    _s
      ..padLit = k
      ..padTick += 1;
    _emit();
    if (_s.q.lights) {
      final tick = _s.padTick;
      _later(450, () {
        if (state == null || _s.padTick != tick) return;
        _s.padLit = null;
        _emit();
      });
    }
  }

  /// ضغطة الطفل على طبلة.
  void rhythmTap(int k) {
    final s = _s, q = s.q;
    if (s.locked || s.rhythmLock) return; // ممنوع الضغط والإيقاع شغال
    _hitPad(k);
    if (k == q.beats[s.picked.length]) {
      s.picked.add(k);
      if (s.picked.length == q.beats.length) {
        _solved(skill: q.skill, playSfx: false, delay: 1600);
      } else {
        _emit();
      }
    } else {
      s.tries++;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(q.skill);
      _wrongUi(q, 'pad$k', allowHint: false);
      s
        ..picked.clear()
        ..rhythmLock = true
        ..bubble = q.lights ? 'مش مظبوط — هنشوفها تاني ❤️' : 'مش مظبوط — هنسمعه تاني ❤️'
        ..bubbleKind = BubbleKind.no;
      _emit();
      _later(900, rhythmPlay);
    }
  }

  // ------------------------------------------------------------------ فين القطة؟

  /// القطة باينة تحت الكوباية المرفوعة، وبعدين الأكواب بتنزل وتتبدّل.
  void _cupsShow() {
    final s = _s, q = s.q;
    s
      ..cupReady = false
      ..cupLifted.add(q.catCup)
      ..bubble = 'شوف القطة فين 👀'
      ..bubbleKind = BubbleKind.plain;
    if (s.cupSlots.isEmpty) s.cupSlots.addAll([for (var i = 0; i < q.cupCount; i++) i]);
    _emit();
    _later(cupShowMs, () {
      if (state == null || _s.q != q) return;
      _s.cupLifted.clear();
      _emit();
      _cupsShuffle(q, q.cupSwaps);
    });
  }

  /// مدة ظهور القطة قبل ما الأكواب تنزل، ومدة نزولها قبل أول تبديلة.
  static const cupShowMs = 1600, cupDropMs = 600;

  void _cupsShuffle(Question q, int left) {
    _later(left == q.cupSwaps ? cupDropMs : q.cupStepMs, () {
      if (state == null || _s.q != q || _s.locked) return;
      final s = _s;
      if (left == 0) {
        s
          ..cupReady = true
          ..bubble = 'القطة تحت أنهي كوباية؟ 🐱'
          ..bubbleKind = BubbleKind.plain;
        _emit();
        return;
      }
      // كوبايتين بيبدّلوا أماكنهم
      final a = _rng.rnd(0, q.cupCount - 1);
      var b = _rng.rnd(0, q.cupCount - 2);
      if (b >= a) b++;
      final t = s.cupSlots[a];
      s.cupSlots[a] = s.cupSlots[b];
      s.cupSlots[b] = t;
      _emit();
      _cupsShuffle(q, left - 1);
    });
  }

  /// الطفل رفع كوباية: القطة ← نجاح. فاضية ← نوريه القطة فين ونبدّل تاني.
  void cupPick(int cup) {
    final s = _s, q = s.q;
    if (s.locked || !s.cupReady || s.cupLifted.contains(cup)) return;
    s.cupLifted.add(cup);
    if (cup == q.catCup) {
      _solved(anchor: 'cup$cup', skill: q.skill, delay: 1800);
      final pr = _rng.sample(praiseSay);
      _speech.speak(pr.$1, clips: [pr.$2]);
      return;
    }
    s
      ..tries += 1
      ..streak = 0
      ..cupReady = false;
    if (s.tries == 1) {
      _markMistake(q);
      _miss(q.skill);
      _penalize();
    }
    _wrongUi(q, 'cup$cup', allowHint: false);
    s.bubble = 'مش هنا — القطة كانت هنا 🐱 يلا تاني!';
    _emit();
    _speech.speak(sayRetry, clips: ['retry']);
    _later(900, () {
      if (state == null || _s.q != q) return;
      _s.cupLifted.add(q.catCup);
      _emit();
      _later(1400, () {
        if (state == null || _s.q != q) return;
        _s.cupLifted.clear();
        _emit();
        _cupsShuffle(q, q.cupSwaps);
      });
    });
  }

  // ------------------------------------------------------------------ المتاهة

  /// خطوة للأرنب: [dr] و[dc] من -١ لـ ١. الحيطة خبطة لطيفة من غير عقاب — المتاهة تجريب.
  void mazeMove(int dr, int dc) {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.maze) return;
    final n = q.mazeSize, row = s.mazeAt ~/ n, col = s.mazeAt % n;
    final wall = switch ((dr, dc)) {
      (-1, 0) => mazeN,
      (1, 0) => mazeS,
      (0, 1) => mazeE,
      _ => mazeW,
    };
    if (q.mazeWalls[s.mazeAt] & wall != 0) {
      s
        ..mazeBump += 1
        ..bubble = 'فيه حيطة 🧱 جرّب طريق تاني'
        ..bubbleKind = BubbleKind.plain;
      _emit();
      _sfx.bad();
      return;
    }
    final to = (row + dr) * n + col + dc;
    // الرجوع خطوة بيمسح آخر الأثر
    if (s.mazeTrail.length >= 2 && s.mazeTrail[s.mazeTrail.length - 2] == to) {
      s.mazeTrail.removeLast();
    } else {
      s.mazeTrail.add(to);
    }
    s.mazeAt = to;
    if (to == q.mazeGoal) {
      _solved(anchor: 'maze', skill: q.skill, delay: 1600);
      final pr = _rng.sample(praiseSay);
      _speech.speak(pr.$1, clips: [pr.$2]);
      return;
    }
    _emit();
  }

  // ------------------------------------------------------------------ ارسم بصباعك

  /// الرسمة غطّت الشكل.
  void traceDone() {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.trace) return;
    final pr = _rng.sample(praiseSay);
    _solved(anchor: 'trace', skill: q.skill, delay: 1500);
    q.isEnglish ? _speech.speakEn('Very good!') : _speech.speak(pr.$1, clips: [pr.$2]);
  }

  /// الطفل رسم كتير برّه الشكل: تشجيع لطيف ونمسح ونبدأ تاني.
  void traceOff() {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.trace) return;
    s
      ..tries += 1
      ..streak = 0
      ..traceTick += 1;
    if (s.tries == 1) {
      _markMistake(q);
      _miss(q.skill);
      _penalize();
    }
    _wrongUi(q, 'trace', allowHint: false);
    s.bubble = q.isEnglish ? 'Stay on the grey letter — try again ❤️' : 'خلّي صباعك فوق الشكل الرمادي — جرّب تاني ❤️';
    _emit();
    q.isEnglish ? _speech.speakEn(['Try again', q.speakHint ?? '']) : _speech.speak([sayRetry, q.speakHint ?? q.hint]);
  }

  /// امسح الرسمة من غير ما تتحسب غلطة.
  void traceClear() {
    if (_s.locked) return;
    _s.traceTick += 1;
    _emit();
  }

  // ------------------------------------------------------------------ ألغاز للكبار

  /// أول غلطة في السؤال بتتحسب، والباقي بيورّي التلميح بس.
  void _puzzleMiss(Question q, String anchor, String bubble) {
    final s = _s
      ..tries += 1
      ..streak = 0;
    if (s.tries == 1) {
      _markMistake(q);
      _miss(q.skill);
      _penalize();
    }
    _wrongUi(q, anchor, allowHint: false);
    s.bubble = bubble;
    _emit();
    _speech.speak([sayRetry, q.speakHint ?? q.hint]);
  }

  void _puzzleSolved(Question q, {String? bubble}) {
    _solved(anchor: null, skill: q.skill, delay: 1900);
    if (bubble != null) {
      _s.bubble = bubble;
      _emit();
    }
    final pr = _rng.sample(praiseSay);
    _speech.speak(pr.$1, clips: [pr.$2]);
  }

  /// سودوكو: اختيار خانة فاضية.
  void sudokuSelect(int i) {
    final s = _s, q = s.q;
    if (s.locked || q.givens[i] || s.sudokuVals.containsKey(i)) return;
    s.sudokuSel = i;
    _emit();
  }

  /// سودوكو: حط الرقم [v] (١…n) في الخانة المختارة. الغلط بيقول الطفل ليه.
  void sudokuPut(int v) {
    final s = _s, q = s.q;
    if (s.locked) return;
    final i = s.sudokuSel;
    if (i == null) {
      s
        ..bubble = 'اختار خانة فاضية الأول 👆'
        ..bubbleKind = BubbleKind.plain;
      _emit();
      _sfx.bad();
      return;
    }
    if (q.solution[i] == v) {
      s
        ..sudokuVals[i] = v
        ..sudokuSel = null;
      _fx.add(FxFill('sq$i'));
      if (s.sudokuVals.length == q.givens.where((g) => !g).length) {
        _puzzleSolved(q);
      } else {
        _emit();
        _sfx.good();
      }
      return;
    }
    final n = q.gridSize, row = i ~/ n, col = i % n;
    int? shown(int k) => q.givens[k] ? q.solution[k] : s.sudokuVals[k];
    final r0 = row - row % q.boxRows, c0 = col - col % q.boxCols;
    final where = [for (var k = 0; k < n; k++) shown(row * n + k)].contains(v)
        ? 'الصف'
        : [for (var k = 0; k < n; k++) shown(k * n + col)].contains(v)
            ? 'العمود'
            : [
                for (var a = 0; a < q.boxRows; a++)
                  for (var b = 0; b < q.boxCols; b++) shown((r0 + a) * n + c0 + b),
              ].contains(v)
                ? 'المربع'
                : null;
    final sym = q.symbols[v - 1];
    _puzzleMiss(q, 'sq$i', where != null ? '$sym موجود في نفس $where — جرّب حاجة تانية ❤️' : 'مش $sym هنا — فكّر تاني ❤️');
  }

  /// برج هانوي: الضغطة الأولى بتشيل الحلقة اللي فوق، والتانية بتحطها.
  void hanoiTap(int peg) {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.hanoi) return;
    final held = s.hanoiHeld;
    if (held == null) {
      if (s.pegs[peg].isEmpty) return;
      s.hanoiHeld = peg;
      _emit();
      return;
    }
    s.hanoiHeld = null;
    if (held == peg) {
      _emit();
      return;
    }
    final d = s.pegs[held].last;
    if (s.pegs[peg].isNotEmpty && s.pegs[peg].last < d) {
      _puzzleMiss(q, 'peg$peg', 'الحلقة الكبيرة ماتقعدش على الصغيرة ❤️');
      return;
    }
    s.pegs[held].removeLast();
    s.pegs[peg].add(d);
    s.moves++;
    if (s.pegs[2].length == q.discs) {
      final best = (1 << q.discs) - 1;
      _puzzleSolved(q,
          bubble: s.moves == best ? '🏆 ${ar(s.moves)} حركة — أقل عدد ممكن!' : '🗼 خلّصت في ${ar(s.moves)} حركة (ممكن في ${ar(best)})');
      return;
    }
    _emit();
  }

  /// البازل المنزلق: الرقم اللي جنب الفاضية بيتزحلق مكانها.
  void slideTap(int i) {
    final s = _s, q = s.q;
    if (s.locked || q.mode != QMode.slide) return;
    final n = q.slideSize, blank = s.slideTiles.indexOf(0);
    final near = (i ~/ n == blank ~/ n && (i - blank).abs() == 1) || (i % n == blank % n && (i - blank).abs() == n);
    if (!near) {
      s.puzzleBump++;
      _emit();
      return;
    }
    s.slideTiles[blank] = s.slideTiles[i];
    s.slideTiles[i] = 0;
    s.moves++;
    final done = [for (var k = 0; k < n * n - 1; k++) s.slideTiles[k] == k + 1].every((x) => x);
    if (done) {
      _puzzleSolved(q, bubble: '🔲 اترتبت في ${ar(s.moves)} حركة!');
      return;
    }
    _emit();
  }

  /// اقرأ المقطع: مفيش إجابة غلط — الطفل يسمع ويقرأ ويؤكد.
  void readDone() {
    final s = _s;
    if (s.locked) return;
    final pr = _rng.sample(praiseSay);
    _solved(skill: s.q.skill, delay: 1200);
    _speech.speak(pr.$1, clips: [pr.$2]);
  }

  /// صنّف: اختار بطاقة (بالضغط أو بالسحب).
  void sortSelect(int i) {
    final s = _s;
    if (s.locked || s.placed.containsKey(i)) return;
    s.sel = i;
    _emit();
    _speech.speak(s.q.sortCards[i].say);
  }

  /// صنّف: حط البطاقة المختارة في صندوق. الغلطة = تلميح لطيف مش عقاب.
  void sortPlace(String box, {int? card}) {
    final s = _s, q = s.q;
    if (s.locked) return;
    final sel = card ?? s.sel;
    if (sel == null || s.placed.containsKey(sel)) {
      s
        ..bubble = s.stage.isMadd ? 'اختر مقطعًا أولًا 👆' : 'اختار صورة الأول 👆'
        ..bubbleKind = BubbleKind.plain;
      _emit();
      return;
    }
    final c = q.sortCards[sel], sk = q.skillOf?.call(c.type) ?? 'madd:${c.type}';
    if (c.type == box) {
      s
        ..placed[sel] = box
        ..sel = null;
      _hit(sk);
      _fx.add(FxFill('b$box'));
      _speech.speak(c.say);
      if (s.placed.length == q.sortCards.length) {
        _solved(delay: 1200);
      } else {
        s
          ..bubble = '${ar(s.placed.length)} / ${ar(q.sortCards.length)} ✅'
          ..bubbleKind = BubbleKind.ok;
        _emit();
        _sfx.good();
      }
    } else {
      s
        ..tries += 1
        ..streak = 0
        ..sel = null;
      _markMistake(q);
      if (s.tries == 1) _penalize();
      _miss(sk);
      _wrongUi(q, 'b$box', allowHint: false);
    }
  }

  // ------------------------------------------------------------------ التالي والنهاية

  void _next() {
    _s.idx++;
    if (_s.idx >= _s.total) {
      _time.flush();
      _finish();
    } else if (_time.checkpoint()) {
      // الوقت خلص: السؤال اللي فات خلص، فنقف هنا بهدوء قبل اللي بعده
      _s.timeUp = true;
      _emit();
    } else {
      _render();
    }
  }

  void _finish() {
    final s = _s;
    Stage? unlocked;
    String? placed;
    if (!s.practice && isPlacement(s.stage.id)) {
      // مفيش ميداليات ولا إتقان للاختبار نفسه — بيفتح مراحل الدرجات اللي عدّاها وبيحدد المستوى
      final reached = placementReached([for (final d in s.dots) d == DotState.done]);
      _progress.update((p) => unlocked = applyPlacement(p, s.stage.world, reached));
      placed = placementLabel(s.stage.world, reached);
    } else if (!s.practice) {
      _progress.update((p) {
        final before = p.best[s.stage.id] ?? 0;
        p.addResult(s.stage.id, s.correct, s.total);
        p.recordMastery(s.stage.id, s.correct, s.total);
        if (s.correct / s.total >= .8) {
          unlocked = p.unlockNext(s.stage.id);
          markPathStage(p, s.stage.id);
        }
        // المدود: +٢ لكل جولة، و +٥ أول مرة تنجح فيها المرحلة
        if (s.stage.isMadd) {
          p.madd.rounds[s.stage.id] = (p.madd.rounds[s.stage.id] ?? 0) + 1;
          p.addStar(2, s.stage.world);
          if (before < 2 && s.correct / s.total >= .8) p.addStar(5, s.stage.world);
        }
      });
    }
    // خطوة في رحلة النهاردة؟ (تدريب على الأخطاء في نفس المرحلة بيتحسب برضه)
    _progress.update((p) => p.journeyMark('stage:${s.stage.id}'));
    _progress.checkRewards();
    s.result = GameResult(
      stage: s.stage, correct: s.correct, total: s.total,
      mistakes: [...s.mistakes], unlocked: unlocked, practice: s.practice, placed: placed,
    );
    s.result!.good ? _sfx.win() : _sfx.aww();
    _emit();
  }
}

final gameProvider = NotifierProvider.autoDispose<GameEngine, GameSession?>(GameEngine.new);
