/// مؤثرات اللعبة — ملفات WAV مولّدة بـ tool/render_sfx.dart من نفس نغمات الويب.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// pad0–pad2: طبول لعبة «كرر الإيقاع» (طبلة، تصفيقة، جرس).
enum SfxKind { good, combo, bad, win, aww, pad0, pad1, pad2 }

abstract class Sfx {
  void play(SfxKind kind);
  void good() => play(SfxKind.good);
  void combo() => play(SfxKind.combo);
  void bad() => play(SfxKind.bad);
  void win() => play(SfxKind.win);
  void aww() => play(SfxKind.aww);
  void pad(int k) => play(SfxKind.values[SfxKind.pad0.index + k.clamp(0, 2)]);
}

class SfxService extends Sfx {
  SfxService({required this.enabled, this.calm});

  /// بيقرا إعداد "أصوات اللعبة".
  final bool Function() enabled;

  /// الوضع الهادي: نفس الأصوات بس أوطى.
  final bool Function()? calm;
  final _players = <SfxKind, AudioPlayer>{};

  Future<void> init() async {
    // المؤثرات بتمتزج مع النطق ومابتحترمش زرار الصامت — زي الويب
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: false).build(),
    );
    for (final k in SfxKind.values) {
      // من غير متابعة للمكان: lowLatency على أندرويد مابيبلّغش إن الصوت خلص، فالمتابعة
      // كانت بتفضل تطلب frame ورا frame للأبد بعد أول صوت (رسم مستمر = بطارية)
      final p = AudioPlayer(playerId: 'sfx_${k.name}')..positionUpdater = null;
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource('audio/sfx/${k.name}.wav'));
      _players[k] = p;
    }
  }

  @override
  void play(SfxKind kind) {
    if (!enabled()) return;
    final p = _players[kind];
    if (p == null) return;
    unawaited(() async {
      try {
        await p.stop();
        await p.setVolume((calm?.call() ?? false) ? .4 : 1);
        await p.resume();
      } catch (_) {}
    }());
  }
}
