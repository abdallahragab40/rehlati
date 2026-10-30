/// صوت ماما وبابا: ولي الأمر بيسجّل أسماء الحروف والأرقام بصوته، وتسجيله بيتشغّل بدل المقطع الجاهز
/// في أي مكان المقطع ده بيتقال (لوحة الحروف، الأسئلة، العد).
///
/// التسجيلات ملفات في فولدر التطبيق على الجهاز ده بس: مابتتبعتش لأي مكان، ومش جوه النسخة الاحتياطية.
library;

import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../content/language_data.dart';
import '../utils/arabic.dart';
import 'clip_manifest.g.dart';
import 'teaching.dart';

/// جلسة الصوت بتاعة التطبيق: الصوت يشتغل حتى لو الجهاز على الصامت، ويمتزج مع أي صوت تاني.
/// بترجع بعد التسجيل (التسجيل بيغيّرها لـ playAndRecord).
const appAudioSession = AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playback,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
  avAudioSessionMode: AVAudioSessionMode.defaultMode,
  androidAudioAttributes: AndroidAudioAttributes(
    contentType: AndroidAudioContentType.speech,
    usage: AndroidAudioUsage.media,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
);

class VoiceItem {
  const VoiceItem(this.key, this.label, this.prompt);

  /// مفتاح المقطع اللي التسجيل بيحل محله.
  final String key;

  /// اللي بيظهر في القايمة ("ب").
  final String label;

  /// ولي الأمر يقول إيه ("باء").
  final String prompt;
}

/// اللي ولي الأمر يقدر يسجّله: أسماء الحروف، وبعدين الأرقام من ٠ لـ ١٠.
final List<VoiceItem> parentVoiceItems = [
  for (final l in arLetters)
    if (teachKey(l.letter) case final k? when clipKeys.contains(k)) VoiceItem(k, l.letter, l.name ?? l.letter),
  for (var n = 0; n <= 10; n++)
    if (clipKeys.contains('n$n')) VoiceItem('n$n', ar(n), arNum(n)),
];

abstract final class ParentVoice {
  static String? _dir;
  static final _keys = <String>{};

  /// الأقصى للتسجيل الواحد — اسم حرف أو رقم.
  static const maxLength = Duration(seconds: 4);

  static Future<void> init() async {
    try {
      final d = Directory('${(await getApplicationDocumentsDirectory()).path}/parent_voice');
      _dir = d.path;
      if (!d.existsSync()) return;
      for (final f in d.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.m4a')) _keys.add(name.substring(0, name.length - 4));
      }
    } catch (e) {
      debugPrint('[parent voice] $e');
    }
  }

  static Set<String> get keys => {..._keys};

  /// ملف تسجيل ولي الأمر للمقطع ده، أو null.
  static String? pathFor(String key) => _dir != null && _keys.contains(key) ? '$_dir/$key.m4a' : null;

  /// ملف مؤقت للتسجيل قبل ما يتحفظ.
  static Future<String> tempPath() async => '${(await getTemporaryDirectory()).path}/parent_voice_take.m4a';

  static Future<void> save(String key, String recorded) async {
    final dir = _dir;
    if (dir == null) return;
    await Directory(dir).create(recursive: true);
    await File(recorded).copy('$dir/$key.m4a');
    _keys.add(key);
  }

  static Future<void> remove(String key) async {
    final path = pathFor(key);
    _keys.remove(key);
    if (path != null && File(path).existsSync()) await File(path).delete();
  }

  @visibleForTesting
  static void debugSet(String dir, Set<String> keys) {
    _dir = dir;
    _keys
      ..clear()
      ..addAll(keys);
  }
}

/// المفاتيح المتسجّلة — الشاشة بتتحدّث لما تسجيل يتحفظ أو يتمسح.
class ParentVoiceController extends Notifier<Set<String>> {
  @override
  Set<String> build() => ParentVoice.keys;

  Future<void> save(String key, String recorded) async {
    await ParentVoice.save(key, recorded);
    state = ParentVoice.keys;
  }

  Future<void> remove(String key) async {
    await ParentVoice.remove(key);
    state = ParentVoice.keys;
  }
}

final parentVoiceProvider = NotifierProvider<ParentVoiceController, Set<String>>(ParentVoiceController.new);
