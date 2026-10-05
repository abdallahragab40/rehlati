// يولّد مؤثرات اللعبة كملفات WAV — نسخة offline من note() و applause() في js/audio.js.
//
// الويب كان بيركّب الأصوات وقت التشغيل بـ WebAudio؛ هنا بنطلعها مرة واحدة
// بنفس الترددات والأظرف عشان الصوت يفضل زي ما هو.
//
//   dart run tool/render_sfx.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sr = 44100;

class Track {
  Track(double seconds) : buf = Float64List((seconds * sr).ceil() + sr ~/ 10);
  final Float64List buf;

  /// نفس exponentialRampToValueAtTime في WebAudio.
  static double expRamp(double v0, double v1, double t0, double t1, double t) =>
      v0 * math.pow(v1 / v0, ((t - t0) / (t1 - t0)).clamp(0.0, 1.0));

  /// نغمة واحدة بظرف ناعم — الأساس اللي كل المؤثرات مبنية عليه.
  void note(double f, double at, double dur, {String type = 'triangle', double vol = .22, double? to}) {
    var phase = 0.0;
    final start = (at * sr).round(), end = ((at + dur + .03) * sr).round();
    for (var i = start; i < end && i < buf.length; i++) {
      final t = (i - start) / sr;
      final freq = to == null ? f : expRamp(f, to, 0, dur, t);
      phase += freq / sr;
      final p = phase - phase.floorToDouble();
      final osc = type == 'sine' ? math.sin(2 * math.pi * p) : 1 - 4 * (p - .5).abs();
      final g = t < .02 ? expRamp(.0001, vol, 0, .02, t) : expRamp(vol, .0001, .02, dur, t);
      buf[i] += osc * (t > dur ? 0 : g);
    }
  }

  /// تصفيق الجمهور: سحابة ضجيج مفلترة + تصفيقات فردية فوقها.
  void applause(double dur, double vol, math.Random rnd) {
    final hp = Biquad.highpass(600, .707), bp = Biquad.bandpass(1700, .5);
    final n = (dur * sr).round();
    for (var i = 0; i < n && i < buf.length; i++) {
      final t = i / sr;
      final double g;
      if (t < .22) {
        g = Track.expRamp(.0001, .2 * vol, 0, .22, t);
      } else if (t < dur * .45) {
        g = .2 * vol;
      } else if (t < dur * .78) {
        g = Track.expRamp(.2 * vol, .08 * vol, dur * .45, dur * .78, t);
      } else {
        g = Track.expRamp(.08 * vol, .0001, dur * .78, dur, t);
      }
      buf[i] += hp.run(bp.run(rnd.nextDouble() * 2 - 1)) * g;
    }
    final claps = (dur * 26).round();
    for (var c = 0; c < claps; c++) {
      final at = rnd.nextDouble() * dur * .9;
      final f = Biquad.bandpass(1000 + rnd.nextDouble() * 2400, 1.2);
      final peak = (.04 + rnd.nextDouble() * .06) * vol;
      final decay = .05 + rnd.nextDouble() * .06;
      final start = (at * sr).round();
      for (var i = 0; i < (.15 * sr).round(); i++) {
        final t = i / sr;
        final g = t < .004 ? Track.expRamp(.0001, peak, 0, .004, t) : Track.expRamp(peak, .0001, .004, decay, t);
        if (start + i < buf.length) buf[start + i] += f.run(rnd.nextDouble() * 2 - 1) * g;
      }
    }
  }

  void writeWav(String path) {
    final samples = Int16List(buf.length);
    for (var i = 0; i < buf.length; i++) {
      samples[i] = (buf[i].clamp(-1.0, 1.0) * 32767).round();
    }
    final data = samples.buffer.asUint8List();
    final h = ByteData(44)
      ..setUint32(0, 0x52494646) // RIFF
      ..setUint32(4, 36 + data.length, Endian.little)
      ..setUint32(8, 0x57415645) // WAVE
      ..setUint32(12, 0x666d7420) // fmt
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, sr, Endian.little)
      ..setUint32(28, sr * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461) // data
      ..setUint32(40, data.length, Endian.little);
    File(path).writeAsBytesSync([...h.buffer.asUint8List(), ...data]);
    print('wrote $path (${(buf.length / sr).toStringAsFixed(2)}s)');
  }
}

/// فلتر Biquad من RBJ Audio EQ Cookbook — نفس BiquadFilterNode تقريبًا.
class Biquad {
  Biquad._(this.b0, this.b1, this.b2, this.a1, this.a2);

  factory Biquad.bandpass(double f, double q) {
    final w = 2 * math.pi * f / sr, alpha = math.sin(w) / (2 * q), a0 = 1 + alpha;
    return Biquad._(alpha / a0, 0, -alpha / a0, -2 * math.cos(w) / a0, (1 - alpha) / a0);
  }

  factory Biquad.highpass(double f, double q) {
    final w = 2 * math.pi * f / sr, alpha = math.sin(w) / (2 * q), c = math.cos(w), a0 = 1 + alpha;
    return Biquad._((1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0, -2 * c / a0, (1 - alpha) / a0);
  }

  final double b0, b1, b2, a1, a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  double run(double x) {
    final y = b0 * x + b1 * _x1 + b2 * _x2 - a1 * _y1 - a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

void main() {
  final rnd = math.Random(93);
  const out = 'assets/audio/sfx';
  Directory(out).createSync(recursive: true);

  // ✅ إجابة صح: نغمة صاعدة مبهجة + رشة عالية
  final good = Track(.6);
  for (final (i, f) in [523.0, 659.0, 784.0].indexed) {
    good.note(f, i * .09, .16, vol: .2);
  }
  good.note(1568, .27, .22, type: 'sine', vol: .12);
  good.writeWav('$out/good.wav');

  // 🔥 سلسلة إجابات صح: احتفال أكبر + تصفيقة خفيفة
  final combo = Track(1.2);
  for (final (i, f) in [523.0, 659.0, 784.0, 1047.0, 1319.0].indexed) {
    combo.note(f, i * .075, .2, vol: .2);
  }
  combo
    ..note(1047, .42, .5, type: 'sine', vol: .16)
    ..note(1568, .46, .5, type: 'sine', vol: .1)
    ..applause(1.1, .6, rnd);
  combo.writeWav('$out/combo.wav');

  // ❌ إجابة غلط: نغمة هابطة لطيفة — زعلانة مش مخيفة
  Track(.6)
    ..note(392, 0, .22, vol: .17, to: 294)
    ..note(294, .2, .34, vol: .15, to: 196)
    ..writeWav('$out/bad.wav');

  // 🎉 نهاية الجولة: فانفير قصير والجمهور بيصفّق وراه
  final win = Track(2.7);
  for (final (i, f) in [523.0, 659.0, 784.0, 1047.0].indexed) {
    win.note(f, i * .09, .2, vol: .19);
  }
  win
    ..note(1319, .38, .34, type: 'sine', vol: .13)
    ..applause(2.6, 1, rnd);
  win.writeWav('$out/win.wav');

  // 😔 نتيجة ضعيفة — تشجيع مش إحباط
  Track(.75)
    ..note(440, 0, .3, vol: .16, to: 349)
    ..note(349, .28, .42, vol: .14, to: 262)
    ..writeWav('$out/aww.wav');
}
