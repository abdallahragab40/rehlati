/// النطق: مقاطع مسجّلة لو كلها موجودة، وإلا نطق الجهاز (TTS) — نفس منطق js/audio.js.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'clip_manifest.g.dart';

/// الواجهة اللي المحرك والشاشات بيستخدموها — بتتبدّل بـ fake في الاختبارات.
abstract class Speech {
  /// [text] نص أو قائمة جُمل تتقال بالترتيب. [clips] مفاتيح المقاطع المسجّلة المقابلة.
  void speak(Object text, {List<String?>? clips});
  void speakEn(Object text);
  void stop();
}

class SpeechService implements Speech {
  SpeechService({required this.enabled});

  /// بيقرا إعداد "نطق الأسئلة" لحظة النطق.
  final bool Function() enabled;

  final _tts = FlutterTts();
  final _clips = AudioPlayer();
  int _token = 0;
  String? _currentLang;
  Map<String, String>? _arVoice, _enVoice;

  // للتشخيص في الإعدادات
  String lastEvent = 'لسه مجربناش';
  int voiceCount = 0;
  List<String> arVoices = const [];
  String? get arVoiceName => _arVoice == null ? null : '${_arVoice!['name']} (${_arVoice!['locale']})';
  int get clipCount => clipKeys.length;

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

  /// اختيار أفضل صوت عربي متاح (مصري ← خليجي/شامي/مغربي ← أي عربي) وصوت إنجليزي (US ← GB).
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
    _arVoice = ar.where((v) => loc(v, r'eg')).firstOrNull ??
        ar.where((v) => loc(v, r'sa|ae|jo|ma')).firstOrNull ??
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

  static List<String> _parts(Object text) =>
      (text is List ? text.map((e) => '$e') : ['$text']).map(clean).where((p) => p.isNotEmpty).toList();

  @override
  void speak(Object text, {List<String?>? clips}) => unawaited(_speak(text, clips, 'ar'));

  @override
  void speakEn(Object text) => unawaited(_speak(text, null, 'en'));

  Future<void> _speak(Object text, List<String?>? clips, String lang) async {
    if (!enabled()) {
      lastEvent = 'النطق مقفول من الإعدادات';
      return;
    }
    final my = ++_token;
    await _halt();
    if (my != _token) return;

    // الأولوية للمقاطع المسجّلة لو كلها متوفرة — الإنجليزي مالوش مقاطع
    if (lang == 'ar' && clips != null && clips.isNotEmpty && clips.every((k) => k != null && clipKeys.contains(k))) {
      try {
        await _clips.setAudioSources([for (final k in clips) AudioSource.asset('assets/audio/clips/$k.m4a')]);
        if (my != _token) return;
        lastEvent = 'مقاطع مسجّلة ✅';
        unawaited(_clips.play());
        return;
      } catch (e) {
        lastEvent = 'المقاطع فشلت، بنرجع للنطق: $e';
      }
    }
    await _say(_parts(text), lang, my);
  }

  Future<void> _say(List<String> parts, String lang, int my) async {
    try {
      if (_currentLang != lang) {
        final v = lang == 'en' ? _enVoice : _arVoice;
        if (v != null) {
          await _tts.setVoice(v);
        } else {
          await _tts.setLanguage(lang == 'en' ? 'en-US' : 'ar-EG');
        }
        // iOS: ٠.٥ هي السرعة العادية؛ أندرويد: ١.٠ — والويب كان ٠.٨٢ عربي و ٠.٧٨ إنجليزي
        final base = lang == 'en' ? .78 : .82;
        await _tts.setSpeechRate(!kIsWeb && Platform.isIOS ? base * .5 : base);
        _currentLang = lang;
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
    unawaited(_halt());
  }
}
