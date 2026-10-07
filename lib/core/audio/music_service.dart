/// موسيقى خلفية هادية — نسخة الموبايل من js/music.js.
///
/// الويب بيولّد التهويدة لحظيًا؛ هنا ملفات متولّدة بنفس القواعد (tool/render_music.dart) وبتتكرر —
/// ملف لكل مزاج، ولكل عالم ولعبة مزاجها وسرعتها وصوتها ([MusicService.themes]).
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

  /// مزاج الشاشة: id مرحلة أو عالم أو 'home'.
  void theme(String id);
}

class MusicService implements Music {
  MusicService({required this.enabled, required this.speaking});

  /// إعداد "موسيقى هادية في الخلفية".
  final bool Function() enabled;
  final ValueListenable<bool> speaking;

  /// نفس مستوى الويب (master .11 على الإشارة الأصلية — الملف متطبّع).
  static const volume = .033;

  /// المزاج: (الملف، السرعة، الصوت) — منقولة من THEMES في js/music.js. السرعة = بطء الويب
  /// بالنسبة لسرعة الملف، ومحصورة بين ٠.٧٥ و ١.٢٥ عشان الجرس مايبانش متمطّط.
  static const themes = <String, (String, double, double)>{
    'home': ('warm', 1, 1),
    'math': ('warm', .97, .82),
    'arabic': ('airy', .76, .82),
    'english': ('curious', 1, .82),
    'games': ('airy', 1, .91),
    'balloons': ('airy', 1.13, .91),
    'memoryNum': ('curious', .75, .73),
    'listenNum': ('warm', .75, .36),
    'race': ('bright', 1.12, 1),
    'puzzle': ('airy', .81, .82),
    'colorNum': ('warm', .75, .73),
    'pattern': ('curious', .88, .82),
    'letterHunt': ('airy', 1.13, .91),
    'rhythm': ('warm', .75, .27), // هادية جدًا عشان الطفل يسمع الطبول
    'shapes': ('curious', .93, .82),
    'sizeOrder': ('warm', .8, .73),
    'clock': ('airy', .75, .73),
  };

  final _p = AudioPlayer();
  bool _quiet = false, _bg = false, _ready = false, _switching = false;
  Timer? _fade;
  var _theme = themes['home']!;
  int _token = 0;

  Future<void> init() async {
    try {
      await _p.setAsset('assets/audio/music/${_theme.$1}.m4a');
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
    if (!enabled() || _quiet || _bg || _switching) return 0;
    final v = volume * _theme.$3;
    return speaking.value ? v * .25 : v;
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

  /// تغيير المزاج من غير قطع: نخفت، نبدّل الملف والسرعة، ونرجّع بالتدريج.
  @override
  void theme(String id) {
    final t = themes[id] ?? themes['home']!;
    if (t == _theme) return;
    final file = t.$1 != _theme.$1;
    _theme = t;
    if (!_ready) return;
    if (!file) {
      unawaited(_p.setSpeed(t.$2));
      _apply(1.2);
      return;
    }
    final my = ++_token;
    _switching = true;
    _apply(.5);
    Timer(const Duration(milliseconds: 600), () async {
      if (my != _token) return;
      try {
        await _p.setAsset('assets/audio/music/${t.$1}.m4a');
        await _p.setLoopMode(LoopMode.one);
        await _p.setSpeed(t.$2);
      } catch (_) {}
      if (my != _token) return;
      _switching = false;
      _apply(1.6);
    });
  }
}
