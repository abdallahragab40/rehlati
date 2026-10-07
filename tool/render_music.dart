// موسيقى الخلفية — نسخة offline من js/music.js (تهويدة علبة موسيقى).
//
// الويب بيولّد الموسيقى لحظيًا بـ Web Audio. هنا بنطلع نفس القواعد في ملفات بتتكرر —
// ملف لكل "مزاج" (دورة كوردات + نبرة الجرس)، والتطبيق بيختار المزاج وسرعته وصوته
// لكل عالم ولعبة (MusicService.themes):
//   • اللحن بيمشي بخطوات صغيرة جوه الكورد
//   • نغمة علبة موسيقى = أساسي + توافقيتين بذيل طويل، وصدى خفيف، وباص ناعم
// آخر ثواني بتتدمج في أولها (crossfade) عشان التكرار مايبانش.
//
//   dart run tool/render_music.dart && for f in warm airy curious bright; do
//     afconvert -f m4af -d aac -b 64000 assets/audio/music/$f.wav assets/audio/music/$f.m4a
//     rm assets/audio/music/$f.wav; done
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sr = 44100;
const bar = 4; // نغمات قبل ما الكورد يتغيّر
const cycles = 4; // ٤ دورات كوردات = ٦٤ نغمة
const fadeSec = 4.0; // طول الدمج بين الآخر والأول

typedef Chord = ({int bass, List<int> tones});

/// المزاجات (PROG + نبرة الجرس في js/music.js) — كلها في نفس السلّم فمفيش نشاز.
/// step = ثواني بين النغمات؛ bright أسرع لأنه للسباق.
const themes = <String, ({List<Chord> chords, double step, List<double> tone, double bass})>{
  // دافية ومطمّنة — دو / لا صغير / فا / صول (الصفحة الرئيسية والحساب)
  'warm': (chords: [
    (bass: -12, tones: [0, 4, 7, 12]), (bass: -3, tones: [9, 12, 16, 21]),
    (bass: -7, tones: [5, 9, 12, 17]), (bass: -5, tones: [7, 11, 14, 19]),
  ], step: 1.45, tone: [1, .22, .08], bass: .07),
  // واسعة وحالمة — فا / دو / صول / لا صغير (العربي والألعاب)
  'airy': (chords: [
    (bass: -7, tones: [5, 9, 12, 17]), (bass: -12, tones: [0, 4, 7, 16]),
    (bass: -5, tones: [7, 11, 14, 19]), (bass: -3, tones: [9, 12, 16, 21]),
  ], step: 1.3, tone: [1, .3, .12], bass: .05),
  // فضولية خفيفة — لا صغير / فا / دو / صول (English والذاكرة والأنماط)
  'curious': (chords: [
    (bass: -3, tones: [9, 12, 16, 21]), (bass: -7, tones: [5, 9, 12, 17]),
    (bass: -12, tones: [0, 4, 7, 12]), (bass: -5, tones: [7, 11, 14, 19]),
  ], step: 1.4, tone: [1, .25, .09], bass: .05),
  // نشيطة للسباق — دو / فا / صول / دو
  'bright': (chords: [
    (bass: -12, tones: [0, 4, 7, 12]), (bass: -7, tones: [5, 9, 12, 17]),
    (bass: -5, tones: [7, 11, 14, 19]), (bass: -12, tones: [4, 7, 12, 16]),
  ], step: .9, tone: [1, .4, .18], bass: .08),
};

double freq(num n) => 261.63 * math.pow(2, n / 12);

class Lowpass {
  Lowpass(double f, double q) {
    final w = 2 * math.pi * f / sr, alpha = math.sin(w) / (2 * q), c = math.cos(w), a0 = 1 + alpha;
    b0 = (1 - c) / 2 / a0;
    b1 = (1 - c) / a0;
    b2 = b0;
    a1 = -2 * c / a0;
    a2 = (1 - alpha) / a0;
  }
  late final double b0, b1, b2, a1, a2;
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

double expRamp(double v0, double v1, double t0, double t1, double t) =>
    v0 * math.pow(v1 / v0, ((t - t0) / (t1 - t0)).clamp(0.0, 1.0));

void main() {
  for (final MapEntry(key: name, value: t) in themes.entries) {
    render(name, t.chords, t.step, t.tone, t.bass);
  }
}

void render(String name, List<Chord> chords, double step, List<double> tone, double bassVol) {
  final rnd = math.Random(2026);
  final beats = chords.length * bar * cycles;
  final loopLen = (beats * step * sr).round();
  final total = loopLen + (fadeSec * sr).round();

  // ---- النغمات (الجرس) على مسار bus
  final bells = Float64List(total);
  void bell(double n, double at, double vol) {
    final start = (at * sr).round();
    for (var i = 0; i < (3.6 * sr).round() && start + i < total; i++) {
      final t = i / sr;
      final g = t < .035 ? expRamp(.0001, vol, 0, .035, t) : expRamp(vol, .0001, .035, 3.4, t);
      var s = 0.0;
      for (final (k, amp) in tone.indexed) {
        s += amp * math.sin(2 * math.pi * freq(n) * (k + 1) * t);
      }
      bells[start + i] += s * g;
    }
  }

  var last = 12;
  int nextNote(List<int> tones) {
    // أقرب تلات نغمات لآخر نغمة — فاللحن يمشي مش ينطّ
    final pool = [...tones, ...tones.map((t) => t + 12)]..sort((a, b) => (a - last).abs() - (b - last).abs());
    last = pool.take(3).toList()[rnd.nextInt(3)];
    return last;
  }

  for (var beat = 0; beat < beats; beat++) {
    final ch = chords[(beat ~/ bar) % chords.length];
    final pos = beat % bar;
    final at = beat * step;
    bell(nextNote(ch.tones).toDouble(), at, pos == 0 ? .17 : .12);
    // نغمة مرافقة أخف بعد نص المسافة — إحساس التهويدة
    if (pos == 1 || pos == 3) bell(ch.tones[0] + 12.0, at + step * .5, .05);
  }

  // ---- bus (lowpass 2600) + صدى (تأخير .55، رجوع .28 من خلال lowpass 1400، wet .5)
  final out = Float64List(total);
  final busLp = Lowpass(2600, .3), damp = Lowpass(1400, .707);
  final delay = (0.55 * sr).round();
  final line = Float64List(delay);
  var w = 0;
  for (var i = 0; i < total; i++) {
    final dry = busLp.run(bells[i]);
    final delayed = line[w];
    final damped = damp.run(delayed);
    line[w] = bells[i] + damped * .28;
    w = (w + 1) % delay;
    out[i] = dry + damped * .5;
  }

  // ---- باص مستمر بينزلق للكورد الجديد (setTargetAtTime بثابت .4)
  final bassLp = Lowpass(320, .707);
  var bf = freq(chords[0].bass), phase = 0.0;
  final k = 1 - math.exp(-1 / (.4 * sr));
  for (var i = 0; i < total; i++) {
    final beat = (i / sr / step).floor();
    final target = freq(chords[(beat ~/ bar) % chords.length].bass);
    bf += (target - bf) * k;
    phase += bf / sr;
    out[i] += bassLp.run(math.sin(2 * math.pi * phase) * bassVol);
  }

  // ---- crossfade: الذيل اللي بعد نهاية الدورة يندمج في أولها
  final f = total - loopLen;
  final loop = Float64List(loopLen);
  for (var i = 0; i < loopLen; i++) {
    loop[i] = out[i];
  }
  for (var i = 0; i < f; i++) {
    final a = i / f;
    loop[i] = out[i] * a + out[loopLen + i] * (1 - a);
  }

  // ---- تطبيع: الملف بأعلى جودة، ومستوى الصوت الفعلي بيتظبط في التطبيق
  final peak = loop.fold<double>(0, (m, v) => math.max(m, v.abs()));
  final gain = .9 / peak;
  final pcm = Int16List(loopLen);
  for (var i = 0; i < loopLen; i++) {
    pcm[i] = (loop[i] * gain * 32767).round().clamp(-32768, 32767);
  }
  final data = pcm.buffer.asUint8List();
  final h = ByteData(44)
    ..setUint32(0, 0x52494646)
    ..setUint32(4, 36 + data.length, Endian.little)
    ..setUint32(8, 0x57415645)
    ..setUint32(12, 0x666d7420)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sr, Endian.little)
    ..setUint32(28, sr * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461)
    ..setUint32(40, data.length, Endian.little);
  Directory('assets/audio/music').createSync(recursive: true);
  File('assets/audio/music/$name.wav').writeAsBytesSync([...h.buffer.asUint8List(), ...data]);
  // الويب: master = .11 على الإشارة الأصلية ← في التطبيق volume = .11 / gain
  print('$name: loop ${(loopLen / sr).toStringAsFixed(1)}s, normalize gain ${gain.toStringAsFixed(3)}, '
      'app volume ${(0.11 / gain).toStringAsFixed(3)}');
}
