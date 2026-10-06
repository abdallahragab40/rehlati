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
      if (file.existsSync()) {
        await _p.setAudioSource(AudioSource.file(file.path));
      } else {
        await _p.setAudioSource(AudioSource.uri(url));
        // بنشغّل من النت على طول، وبنحفظ نسخة في الخلفية للمرة الجاية
        unawaited(download(url, file));
      }
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
        await play(surah: surah, ayah: ayah, reciterId: QuranConfig.defaultReciter, onEnd: onEnd, onIssue: onIssue);
      } else {
        onIssue?.call(RecitationIssue.network);
      }
    }
  }

  static Future<File> cacheFile(String folder, int surah, int ayah) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/recitations/$folder/${'$surah'.padLeft(3, '0')}${'$ayah'.padLeft(3, '0')}.mp3');
  }

  static final _downloading = <String>{};

  /// بيحفظ آية على الجهاز — true لو اتحفظت (أو كانت محفوظة).
  static Future<bool> download(Uri url, File file) async {
    if (file.existsSync()) return true;
    if (!_downloading.add(file.path)) return false;
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 30));
      final type = res.headers['content-type'] ?? '';
      if (res.statusCode == 200 && type.startsWith('audio') && res.bodyBytes.isNotEmpty) {
        await file.parent.create(recursive: true);
        // نكتب في ملف مؤقت ونغيّر اسمه — عشان ملف ناقص مايتشغلش أبدًا
        final tmp = File('${file.path}.part');
        await tmp.writeAsBytes(res.bodyBytes, flush: true);
        await tmp.rename(file.path);
        return true;
      }
      return false;
    } catch (_) {
      // مش مشكلة — هنحاول تاني المرة الجاية
      return false;
    } finally {
      _downloading.remove(file.path);
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

/// القارئ العادي وقارئ الترديد — محفوظين في shared_preferences.
class ReciterPrefs {
  const ReciterPrefs(this.reciter, this.repeat);
  final String reciter;
  final String repeat;
}

class ReciterController extends Notifier<ReciterPrefs> {
  static const _k = 'rehlati.reciter', _kRepeat = 'rehlati.repeatReciter';

  @override
  ReciterPrefs build() {
    final prefs = ref.read(sharedPrefsProvider);
    String valid(String? id, String fallback) =>
        QuranConfig.reciters.any((r) => r.id == id) ? id! : fallback;
    return ReciterPrefs(
      valid(prefs.getString(_k), QuranConfig.defaultReciter),
      valid(prefs.getString(_kRepeat), QuranConfig.defaultRepeatReciter),
    );
  }

  void setReciter(String id) {
    unawaited(ref.read(sharedPrefsProvider).setString(_k, id));
    state = ReciterPrefs(id, state.repeat);
  }

  void setRepeat(String id) {
    unawaited(ref.read(sharedPrefsProvider).setString(_kRepeat, id));
    state = ReciterPrefs(state.reciter, id);
  }
}

final reciterProvider = NotifierProvider<ReciterController, ReciterPrefs>(ReciterController.new);
