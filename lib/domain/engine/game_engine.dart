/// إدارة الجولة والأسئلة والنجوم — منقول من js/gameEngine.js.
///
/// المحرك بيحتفظ بحالة الجولة (GameSession) ويبعت أحداث مؤثرات (GameFx) للواجهة.
/// كل المؤقتات بتتلغي لما الطفل يخرج من الشاشة (autoDispose) — في الويب كانت بتفضل شغالة.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/math_data.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/sfx_service.dart';
import '../../core/audio/speech_service.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../../core/ui_state.dart';
import '../progress/progress_controller.dart';
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
  });
  final Stage stage;
  final int correct;
  final int total;
  final List<String> mistakes;
  final Stage? unlocked;
  final bool practice;

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
  const FxWrong(this.anchor);
  final String? anchor;
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
    hintTarget = null;
    wrongAnchor = null;
    rightAnchor = null;
    lion = LionMood.idle;
  }
}

class GameEngine extends Notifier<GameSession?> {
  final _timers = <Timer>[];
  final _fx = StreamController<GameFx>.broadcast();
  int _t0 = 0;

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
  GameSession get _s => state!;

  void _emit() => state = state;
  int _now() => DateTime.now().millisecondsSinceEpoch;

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
  }

  // ------------------------------------------------------------------ الجولة

  void start(String stageId, {bool practice = false, List<String>? types}) {
    _cancelTimers();
    _speech.stop();
    final stage = packs[stageId]!;
    final p = _progress.data;
    final childLv = p.level(stage.world);
    final level = math.min(math.max(stage.base, math.min(childLv, stage.base + 1)), 4);
    final count = practice ? practiceCount : questionsPerRound;
    final list = <Question>[];
    if (practice && types != null && types.isNotEmpty) {
      for (var i = 0; i < count; i++) {
        list.add(packs[_rng.sample(types)]!.gen!(level, _rng));
      }
    } else {
      final focus = p.focus(stage.id);
      for (var i = 0; i < count; i++) {
        // تدرّج لطيف داخل الجولة: آخر سؤالين أصعب قليلًا
        final lv = i >= count - 2 ? math.min(level + 1, 4) : level;
        // تعلّم متكيّف: لو فيه مهارة الطفل بيغلط فيها، نرجّعها له
        final f = (focus != null && _rng.chance(.45)) ? focus : null;
        list.add(stage.gen!(lv, _rng, focus: f));
      }
    }
    state = GameSession(stage, level, practice, list);
    _t0 = _now();
    _render();
  }

  void replay() => start(_s.stage.id);

  void trainMistakes() => start(_s.stage.id, practice: true, types: [..._s.mistakes]);

  void _render() {
    final s = _s..resetQuestion();
    s.bubble = '${s.stage.icon} سؤال ${ar(s.idx + 1)} من ${ar(s.total)}';
    s.bubbleKind = BubbleKind.plain;
    _emit();
    final q = s.q;
    if (q.isEnglish) {
      _speech.speakEn(q.speak);
    } else {
      _speech.speak(s.idx == 0 ? ['${s.stage.name}. يلا بينا!', q.speak] : q.speak, clips: q.clips);
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
  void _award() => _progress.update((p) => p
    ..addStar(1, _s.stage.world)
    ..addAnswer(ok: true));

  /// أول غلطة في السؤال بس — عشان السؤال الواحد ما يتحسبش غلط أكتر من مرة.
  void _penalize() => _progress.update((p) => p.addAnswer(ok: false));

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
      ..bubble = first ? _rng.sample(praise) : 'أحسنت! وصلت للإجابة 👏'
      ..bubbleKind = BubbleKind.ok
      ..lion = LionMood.cheer
      ..lionTick += 1;
    _emit();
    _fx.add(FxCorrect(anchor, firstTry: first, streak: s.streak));
    if (playSfx) (first && s.streak >= 3) ? _sfx.combo() : _sfx.good();
    _later(delay, _next);
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
    _fx.add(FxWrong(anchor));
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
    final said = value is int ? arNum(value) : (signWord[value] ?? '$value');
    final valueClip = value is int ? nk(value) : signClip[value];
    if (value == q.answer) {
      final pr = _rng.sample(praiseSay);
      _solved(anchor: 'c$i', skill: q.skill);
      _say(q, [said, pr.$1], clips: [valueClip, pr.$2], en: ['$value', 'Very good!']);
    } else {
      s.tries++;
      s.streak = 0;
      if (s.tries == 1) {
        _markMistake(q);
        _miss(q.skill);
        _penalize();
      }
      _wrongUi(q, 'c$i');
      _say(q, [said, 'حاول مرة تانية', q.speakHint ?? q.hint],
          clips: [valueClip, 'retry', ...?q.clipsHint], en: ['$value', 'Try again', q.speakHint ?? '']);
    }
  }

  /// ترتيب وجداول: تحقّق فوري عند كل ضغطة.
  void pick(int i) {
    final s = _s, q = s.q;
    if (s.locked || s.used.contains(i)) return;
    final value = q.items[i];
    final expected = q.answerList[s.picked.length];
    // الويب كان بينطق "NaN" للحروف لأنه بيحوّل أي قيمة لرقم
    final said = value is int ? arNum(value) : '$value';
    if (value == expected) {
      s.picked.add(value);
      s.used.add(i);
      s.hintTarget = null;
      _fx.add(FxFill('i$i'));
      _sfx.good();
      if (s.picked.length == q.answerList.length) {
        final pr = _rng.sample(praiseSay);
        _solved(skill: q.skill, playSfx: false);
        _say(q, [said, pr.$1], clips: [nk(value), pr.$2], en: [said, 'Very good!']);
      } else {
        _emit();
        _say(q, [said], clips: [nk(value)]);
      }
    } else {
      s.tries++;
      if (s.tries == 1) {
        _markMistake(q);
        _miss(q.skill);
        _penalize();
      }
      _wrongUi(q, 'i$i');
      _say(q, [said, 'حاول مرة تانية', q.speakHint ?? q.hint],
          clips: [nk(value), 'retry'], en: [said, 'Try again', q.speakHint ?? '']);
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
      _say(q, ['حاول مرة تانية'], clips: ['retry'], en: ['Try again']);
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
      _say(q, ['مش ده'], en: ['Not this one']);
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

  // ------------------------------------------------------------------ التالي والنهاية

  void _next() {
    // الوقت بيتحسب سؤال بسؤال — لو الطفل ساب الجولة، اللي ذاكره يتسجّل
    final now = _now();
    _progress.update((p) => p.addTime(now - _t0));
    _t0 = now;
    _s.idx++;
    if (_s.idx >= _s.total) {
      _finish();
    } else {
      _render();
    }
  }

  void _finish() {
    final s = _s;
    Stage? unlocked;
    if (!s.practice) {
      _progress.update((p) {
        p.addResult(s.stage.id, s.correct, s.total);
        if (s.correct / s.total >= .8) unlocked = p.unlockNext(s.stage.id);
      });
    }
    _progress.checkRewards();
    s.result = GameResult(
      stage: s.stage, correct: s.correct, total: s.total,
      mistakes: [...s.mistakes], unlocked: unlocked, practice: s.practice,
    );
    s.result!.good ? _sfx.win() : _sfx.aww();
    _emit();
  }
}

final gameProvider = NotifierProvider.autoDispose<GameEngine, GameSession?>(GameEngine.new);
