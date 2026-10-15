/// النطق: مقاطع مسجّلة لو كلها موجودة، وإلا نطق الجهاز (TTS) — نفس منطق js/audio.js.
///
/// العربي ليه تلات أنواع من المقاطع (tool/render_voice.py):
/// - مقاطع مفاتيح (`n3`، `plus`…) بتتركّب لأسئلة الحساب اللي تركيباتها كتير.
/// - مقطع لكل جملة كاملة، اسمه [SpeechService.phraseKey] للجملة بعد التنظيف.
/// - مقاطع تعليم بالفصحى للحروف والمقاطع والكلمات ([teachKey]) — ليها الأولوية على الجملة.
library;

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../features.dart';
import 'clip_manifest.g.dart';
import 'teaching.dart';
import 'voice_lines.dart';

/// الواجهة اللي المحرك والشاشات بيستخدموها — بتتبدّل بـ fake في الاختبارات.
abstract class Speech {
  /// [text] نص أو قائمة جُمل تتقال بالترتيب. [clips] مفاتيح المقاطع المسجّلة المقابلة.
  void speak(Object text, {List<String?>? clips});
  void speakEn(Object text);
  void stop();

  /// true وقت النطق — الموسيقى بتوطّي صوتها عشان الطفل يسمع السؤال.
  ValueListenable<bool> get speaking;
}

class SpeechService implements Speech {
  SpeechService({required this.enabled, double Function()? speed}) : speed = speed ?? (() => 1.0);

  /// بيقرا إعداد "نطق الأسئلة" لحظة النطق.
  final bool Function() enabled;

  /// سرعة النطق من الإعدادات (١ = عادي).
  final double Function() speed;

  final _tts = FlutterTts();
  final _clips = AudioPlayer();
  int _token = 0;
  String? _currentLang;
  double? _currentSpeed;
  final _speaking = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get speaking => _speaking;
  Map<String, String>? _arVoice, _enVoice;

  // للتشخيص في الإعدادات
  String lastEvent = 'لسه مجربناش';
  int voiceCount = 0;
  List<String> arVoices = const [];
  String? get arVoiceName => _arVoice == null ? null : '${_arVoice!['name']} (${_arVoice!['locale']})';
  int get clipCount => clipKeys.length + phraseKeys.length;

  Future<void> init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        // playback: الصوت يشتغل حتى لو الموبايل على الصامت — الأهل غالبًا ناسيينه صامت
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _tts.setPitch(1.1);
      await _pickVoices();
    } catch (e) {
      lastEvent = 'خطأ في تشغيل النطق: $e';
    }
  }

  /// صوت الجهاز الاحتياطي: الأقرب للمقاطع المسجّلة (سعودي ← خليجي/شامي/مصري ← أي عربي) وإنجليزي (US ← GB).
  Future<void> _pickVoices() async {
    final raw = await _tts.getVoices;
    final voices = <Map<String, String>>[
      if (raw is List)
        for (final v in raw)
          if (v is Map) {'name': '${v['name']}', 'locale': '${v['locale']}'},
    ];
    voiceCount = voices.length;
    bool loc(Map<String, String> v, String re) => RegExp(re, caseSensitive: false).hasMatch(v['locale']!);
    final ar = voices.where((v) => loc(v, r'^ar')).toList();
    arVoices = [for (final v in ar) '${v['name']} (${v['locale']})'];
    _arVoice = ar.where((v) => loc(v, r'sa')).firstOrNull ??
        ar.where((v) => loc(v, r'ae|jo|eg|ma')).firstOrNull ??
        ar.firstOrNull;
    final en = voices.where((v) => loc(v, r'^en')).toList();
    _enVoice = en.where((v) => loc(v, r'us')).firstOrNull ?? en.where((v) => loc(v, r'gb')).firstOrNull ?? en.firstOrNull;
  }

  static final _emoji = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2190}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{2600}-\u{26FF}]',
    unicode: true,
  );

  /// إزالة الإيموجي والرموز قبل النطق.
  static String clean(String t) => t.replaceAll(_emoji, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// مفتاح مقطع الجملة: p_ + FNV-1a (٣٢ بت) لنصها بعد [clean].
  static String phraseKey(String cleaned) {
    var h = 0x811c9dc5;
    for (final b in utf8.encode(cleaned)) {
      h = ((h ^ b) * 0x01000193) & 0xffffffff;
    }
    return 'p_${h.toRadixString(16).padLeft(8, '0')}';
  }

  /// المقاطع اللي هتتشغّل بالترتيب، أو null لو أي جزء ناقص (ساعتها الجملة كلها بالـ TTS
  /// عشان مايتخلطش صوتين في نفس الجملة).
  static List<String>? clipsFor(Object text, List<String?>? clips) {
    if (clips != null && clips.isNotEmpty && clips.every((k) => k != null)) {
      final keys = [
        for (final k in clips.cast<String>())
          if (!k.startsWith(sayPrefix))
            k
          // جزء مالوش صوت (إيموجي اختاره الطفل) بيتشال بدل ما الجملة كلها تروح للـ TTS
          else if (clean(k.substring(sayPrefix.length)) case final t when t.isNotEmpty)
            _keyFor(t),
      ];
      if (keys.every((k) => clipKeys.contains(k) || phraseKeys.contains(k))) return keys;
    }
    final parts = _parts(text);
    final keys = [for (final p in parts) _keyFor(p)];
    if (parts.isEmpty || !keys.every((k) => clipKeys.contains(k) || phraseKeys.contains(k))) {
      if (kDebugMode) debugPrint('[voice] no recording, using TTS: $parts');
      return null;
    }
    return keys;
  }

  /// مقطع التعليم لو موجود، وإلا مقطع الجملة.
  static String _keyFor(String part) {
    final t = teachKey(part);
    return t != null && clipKeys.contains(t) ? t : phraseKey(part);
  }

  static List<String> _parts(Object text) =>
      (text is List ? text.map((e) => '$e') : ['$text']).map(clean).where((p) => p.isNotEmpty).toList();

  @override
  void speak(Object text, {List<String?>? clips}) => unawaited(_speak(text, clips, 'ar'));

  @override
  void speakEn(Object text) => unawaited(_speak(text, null, 'en'));

  Future<void> _speak(Object text, List<String?>? clips, String lang) async {
    if (!voiceEnabled || !enabled()) {
      lastEvent = 'النطق مقفول من الإعدادات';
      return;
    }
    final my = ++_token;
    await _halt();
    if (my != _token) return;

    // الأولوية للمقاطع المسجّلة لو كلها متوفرة — الإنجليزي مالوش مقاطع
    final keys = lang == 'ar' ? clipsFor(text, clips) : null;
    if (keys != null) {
      try {
        await _clips.setAudioSources([for (final k in keys) AudioSource.asset('assets/audio/clips/$k.m4a')]);
        await _clips.setSpeed(speed());
        if (my != _token) return;
        lastEvent = 'مقاطع مسجّلة ✅';
        _speaking.value = true;
        // play() بيخلص لما المقطع يخلص أو يتوقف
        unawaited(_clips.play().then((_) {
          if (my == _token) _speaking.value = false;
        }));
        return;
      } catch (e) {
        lastEvent = 'المقاطع فشلت، بنرجع للنطق: $e';
      }
    }
    _speaking.value = true;
    await _say(_parts(text), lang, my);
    if (my == _token) _speaking.value = false;
  }

  Future<void> _say(List<String> parts, String lang, int my) async {
    try {
      final sp = speed();
      if (_currentLang != lang || _currentSpeed != sp) {
        final v = lang == 'en' ? _enVoice : _arVoice;
        if (v != null) {
          await _tts.setVoice(v);
        } else {
          await _tts.setLanguage(lang == 'en' ? 'en-US' : 'ar-EG');
        }
        // iOS: ٠.٥ هي السرعة العادية؛ أندرويد: ١.٠ — والويب كان ٠.٨٢ عربي و ٠.٧٨ إنجليزي
        final base = lang == 'en' ? .78 : .82;
        await _tts.setSpeechRate((!kIsWeb && Platform.isIOS ? base * .5 : base) * sp);
        _currentLang = lang;
        _currentSpeed = sp;
      }
      for (final p in parts) {
        if (my != _token) return;
        lastEvent = 'اشتغل ✅';
        await _tts.speak(p);
      }
    } catch (e) {
      lastEvent = 'خطأ: $e';
    }
  }

  Future<void> _halt() async {
    try {
      await _clips.stop();
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void stop() {
    _token++;
    _speaking.value = false;
    unawaited(_halt());
  }
}
