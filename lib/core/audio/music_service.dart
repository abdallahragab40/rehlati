/// موسيقى خلفية هادية — نسخة الموبايل من js/music.js.
///
/// الويب بيولّد التهويدة لحظيًا؛ هنا ملف متولّد بنفس القواعد (tool/render_music.dart) وبيتكرر.
/// القواعد:
///   • بتسكت تمامًا في عالم القرآن
///   • بتهدى لربع صوتها وقت نطق الأسئلة عشان الطفل يسمع كويس
///   • بتقف لما التطبيق يروح في الخلفية
///   • ليها مفتاح في الإعدادات ومحفوظة مع باقي الإعدادات
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

abstract class Music {
  /// سكوت مؤقّت (القرآن) من غير ما نقفل الموسيقى من الإعدادات.
  void quiet(bool yes);

  /// التطبيق راح الخلفية / رجع.
  void background(bool yes);

  /// بعد ما الإعداد يتغيّر.
  void refresh();
}

class MusicService implements Music {
  MusicService({required this.enabled, required this.speaking});

  /// إعداد "موسيقى هادية في الخلفية".
  final bool Function() enabled;
  final ValueListenable<bool> speaking;

  /// نفس مستوى الويب (master .11 على الإشارة الأصلية — الملف متطبّع).
  static const volume = .033;

  final _p = AudioPlayer();
  bool _quiet = false, _bg = false, _ready = false;
  Timer? _fade;

  Future<void> init() async {
    try {
      await _p.setAsset('assets/audio/music/lullaby.m4a');
      await _p.setLoopMode(LoopMode.one);
      await _p.setVolume(0);
      _ready = true;
      speaking.addListener(() => _apply(speaking.value ? .4 : 1.5));
      _apply(4); // دخول تدريجي بطيء — ما يفاجئش الطفل
    } catch (_) {
      // من غير موسيقى لو الملف مش موجود — مش مشكلة
    }
  }

  double get _target {
    if (!enabled() || _quiet || _bg) return 0;
    return speaking.value ? volume * .25 : volume;
  }

  /// يوصل للصوت المطلوب بالتدريج، ويوقف المشغّل لو الهدف صفر.
  void _apply(double seconds) {
    if (!_ready) return;
    final target = _target;
    if (target > 0 && !_p.playing) unawaited(_p.play());
    _fade?.cancel();
    final from = _p.volume, steps = math.max(1, (seconds * 20).round());
    var i = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 50), (t) {
      i++;
      final v = from + (target - from) * (i / steps);
      unawaited(_p.setVolume(v));
      if (i >= steps) {
        t.cancel();
        if (target == 0) unawaited(_p.pause());
      }
    });
  }

  @override
  void quiet(bool yes) {
    if (_quiet == yes) return;
    _quiet = yes;
    _apply(yes ? .3 : 1.5);
  }

  @override
  void background(bool yes) {
    if (_bg == yes) return;
    _bg = yes;
    _apply(yes ? .3 : 1.5);
  }

  @override
  void refresh() => _apply(1.5);
}
