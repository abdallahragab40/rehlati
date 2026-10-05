/// مؤثرات اللعبة — ملفات WAV مولّدة بـ tool/render_sfx.dart من نفس نغمات الويب.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum SfxKind { good, combo, bad, win, aww }

abstract class Sfx {
  void play(SfxKind kind);
  void good() => play(SfxKind.good);
  void combo() => play(SfxKind.combo);
  void bad() => play(SfxKind.bad);
  void win() => play(SfxKind.win);
  void aww() => play(SfxKind.aww);
}

class SfxService extends Sfx {
  SfxService({required this.enabled});

  /// بيقرا إعداد "أصوات اللعبة".
  final bool Function() enabled;
  final _players = <SfxKind, AudioPlayer>{};

  Future<void> init() async {
    // المؤثرات بتمتزج مع النطق ومابتحترمش زرار الصامت — زي الويب
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: false).build(),
    );
    for (final k in SfxKind.values) {
      final p = AudioPlayer(playerId: 'sfx_${k.name}');
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
        await p.resume();
      } catch (_) {}
    }());
  }
}
