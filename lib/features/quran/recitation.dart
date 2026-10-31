/// تشغيل التلاوة واختيار القارئ.
///
/// التلاوة بتتخزّن على الجهاز أول ما تتسمع، فالآية اللي اتسمعت مرة بتشتغل من غير
/// نت — الويب كان محتاج نت كل مرة.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../content/quran_config.dart';
import '../../core/audio/audio_providers.dart';
import '../../domain/progress/progress_controller.dart';

/// علامات الوقف والسجدة اللي بتيجي ككلمة لوحدها في النص.
final _marksOnly = RegExp('^[ؐ-ًؚ-ٰٟۖ-ۭـ]+\$');

/// كلمات الآية لتمرين الحفظ — التقسيم على المسافات بس، والعلامة اللي لوحدها
/// (ۚ ۖ ۩ ۞) بتلزق في الكلمة اللي جنبها بنفس المسافة الأصلية عشان الطفل مايلاقيش زرار فيه علامة بس.
List<String> ayahWords(String text) {
  final raw = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final out = <String>[];
  String? carry;
  for (final w in raw) {
    if (_marksOnly.hasMatch(w)) {
      if (out.isEmpty) {
        carry = carry == null ? w : '$carry $w';
      } else {
        out[out.length - 1] = '${out.last} $w';
      }
    } else {
      out.add(carry == null ? w : '$carry $w');
      carry = null;
    }
  }
  if (carry != null) out.add(carry);
  return out;
}

enum RecitationIssue { teacherFallback, network }

/// نتيجة تنزيل آية: اتحفظت، فشلت (نت أو رد غلط)، أو مساحة الجهاز خلصت.
enum AyahFetch { saved, failed, storageFull }

class RecitationPlayer {
  RecitationPlayer(this._stopSpeech);
  final void Function() _stopSpeech;
  final _p = AudioPlayer();
  StreamSubscription<ProcessingState>? _done;
  int _token = 0;

  /// يشغّل آية. [onEnd] بعد ما تخلص؛ [onIssue] لو حصلت مشكلة.
  Future<void> play({
    required int surah,
    required int ayah,
    required String reciterId,
    double speed = 1.0,
    void Function()? onEnd,
    void Function(RecitationIssue issue)? onIssue,
  }) async {
    final my = ++_token;
    _stopSpeech();
    await _done?.cancel();
    final r = QuranConfig.reciter(reciterId);
    try {
      await _p.stop();
      final url = QuranConfig.ayahAudioUrl(r.folder, surah, ayah);
      final file = await cacheFile(r.folder, surah, ayah);
      if (await isValid(file)) {
        await _p.setAudioSource(AudioSource.file(file.path));
      } else {
        await _p.setAudioSource(AudioSource.uri(url));
        // بنشغّل من النت على طول، وبنحفظ نسخة في الخلفية للمرة الجاية
        unawaited(download(url, file));
      }
      await _p.setSpeed(speed);
      if (my != _token) return;
      _done = _p.processingStateStream.where((s) => s == ProcessingState.completed).listen((_) {
        if (my == _token) onEnd?.call();
      });
      unawaited(_p.play());
    } catch (_) {
      if (my != _token) return;
      // لو تلاوة المعلّم مش متاحة، نرجع لقارئ السورة العادي بدل ما نسكت
      if (r.teacher) {
        onIssue?.call(RecitationIssue.teacherFallback);
        await play(
            surah: surah, ayah: ayah, reciterId: QuranConfig.fallbackReciter, speed: speed, onEnd: onEnd, onIssue: onIssue);
      } else {
        onIssue?.call(RecitationIssue.network);
      }
    }
  }

  /// فولدر التلاوات على الجهاز — الاختبارات بتبدّله بفولدر مؤقت.
  static Future<Directory> Function() root =
      () async => Directory('${(await getApplicationSupportDirectory()).path}/recitations');

  static Future<File> cacheFile(String folder, int surah, int ayah) async =>
      File('${(await root()).path}/$folder/${'$surah'.padLeft(3, '0')}${'$ayah'.padLeft(3, '0')}.mp3');

  /// أول بايتات ملف MP3: وسم ID3 أو بداية frame. صفحة خطأ أو ملف مقطوع مابيعدّوش.
  static bool looksLikeAudio(List<int> head) =>
      head.length >= 3 &&
      ((head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) || (head[0] == 0xFF && (head[1] & 0xE0) == 0xE0));

  /// الملف موجود وشكله تلاوة فعلًا — "موجود" لوحده مش كفاية.
  static Future<bool> isValid(File f) async {
    try {
      if (!f.existsSync() || f.lengthSync() < 256) return false;
      final raf = await f.open();
      try {
        return looksLikeAudio(await raf.read(3));
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// خطأ كتابة ← المساحة خلصت؟ (ENOSPC = ٢٨ على أندرويد و iOS)
  static AyahFetch classifyWriteError(Object e) =>
      e is FileSystemException && e.osError?.errorCode == 28 ? AyahFetch.storageFull : AyahFetch.failed;

  static final _downloading = <String, Future<AyahFetch>>{};

  /// بيحفظ آية على الجهاز. طلبين لنفس الملف في نفس الوقت (تشغيل + تنزيل الجزء)
  /// بيستنوا نفس التنزيل. ملف موجود بس تالف بيتمسح ويتنزّل تاني.
  static Future<AyahFetch> fetch(Uri url, File file, {http.Client? client}) async {
    if (await isValid(file)) return AyahFetch.saved;
    // block body: لو رجّعنا قيمة remove (نفس الـ Future) الـ whenComplete هيستنى نفسه للأبد
    return _downloading[file.path] ??= _save(url, file, client).whenComplete(() {
      _downloading.remove(file.path);
    });
  }

  /// true لو الآية اتحفظت (أو كانت محفوظة وسليمة).
  static Future<bool> download(Uri url, File file, {http.Client? client}) async =>
      await fetch(url, file, client: client) == AyahFetch.saved;

  static Future<AyahFetch> _save(Uri url, File file, http.Client? client) async {
    final http.Response res;
    try {
      res = await (client == null ? http.get(url) : client.get(url)).timeout(const Duration(seconds: 30));
    } catch (_) {
      // مش مشكلة — هنحاول تاني المرة الجاية
      return AyahFetch.failed;
    }
    final type = res.headers['content-type'] ?? '';
    if (res.statusCode != 200 || !type.startsWith('audio') || !looksLikeAudio(res.bodyBytes)) return AyahFetch.failed;
    final tmp = File('${file.path}.part');
    try {
      if (file.existsSync()) await file.delete(); // تالف — هيتبدّل
      await file.parent.create(recursive: true);
      // نكتب في ملف مؤقت ونغيّر اسمه — عشان ملف ناقص مايتشغلش أبدًا
      await tmp.writeAsBytes(res.bodyBytes, flush: true);
      await tmp.rename(file.path);
      return AyahFetch.saved;
    } catch (e) {
      try {
        if (tmp.existsSync()) await tmp.delete();
      } catch (_) {}
      return classifyWriteError(e);
    }
  }

  void stop() {
    _token++;
    unawaited(_done?.cancel());
    unawaited(_p.stop());
  }

  Future<void> dispose() async {
    stop();
    await _p.dispose();
  }
}

final recitationProvider = Provider<RecitationPlayer>((ref) {
  final speech = ref.read(speechProvider);
  final p = RecitationPlayer(speech.stop);
  ref.onDispose(p.dispose);
  return p;
});

/// القارئ العادي وقارئ الترديد وسرعة التلاوة — محفوظين في shared_preferences.
class ReciterPrefs {
  const ReciterPrefs(this.reciter, this.repeat, [this.speed = 1.0]);
  final String reciter;
  final String repeat;
  final double speed;
}

class ReciterController extends Notifier<ReciterPrefs> {
  static const _k = 'rehlati.reciter', _kRepeat = 'rehlati.repeatReciter', _kSpeed = 'rehlati.recitationSpeed';

  @override
  ReciterPrefs build() {
    final prefs = ref.read(sharedPrefsProvider);
    String valid(String? id, String fallback) =>
        QuranConfig.reciters.any((r) => r.id == id) ? id! : fallback;
    final speed = prefs.getDouble(_kSpeed);
    return ReciterPrefs(
      valid(prefs.getString(_k), QuranConfig.defaultReciter),
      valid(prefs.getString(_kRepeat), QuranConfig.defaultRepeatReciter),
      QuranConfig.recitationSpeeds.any((s) => s.$2 == speed) ? speed! : 1.0,
    );
  }

  void setReciter(String id) {
    unawaited(ref.read(sharedPrefsProvider).setString(_k, id));
    state = ReciterPrefs(id, state.repeat, state.speed);
  }

  void setRepeat(String id) {
    unawaited(ref.read(sharedPrefsProvider).setString(_kRepeat, id));
    state = ReciterPrefs(state.reciter, id, state.speed);
  }

  void setSpeed(double speed) {
    unawaited(ref.read(sharedPrefsProvider).setDouble(_kSpeed, speed));
    state = ReciterPrefs(state.reciter, state.repeat, speed);
  }
}

final reciterProvider = NotifierProvider<ReciterController, ReciterPrefs>(ReciterController.new);
