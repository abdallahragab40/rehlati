import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'content/quran_config.dart';
import 'core/audio/asset_cache.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/music_service.dart';
import 'core/audio/sfx_service.dart';
import 'core/audio/speech_service.dart';
import 'domain/progress/progress_controller.dart';
import 'features/parent/avatar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // رخصة OFL بتطلب إن نص الرخصة يتوزّع مع الخطوط — بيظهر في صفحة التراخيص في لوحة ولي الأمر
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [('Baloo Bhaijaan 2', 'OFL-BalooBhaijaan2.txt'), ('Amiri Quran', 'OFL-AmiriQuran.txt')]) {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString('assets/fonts/$file'));
    }
    // نص القرآن من Tanzil (CC BY 3.0) — الرخصة بتطلب إشعار حقوقه
    yield const LicenseEntryWithLineBreaks(['Tanzil Quran Text'], tanzilNotice);
  });

  // الموبايل بالطول بس؛ التابلت يلف براحته
  _PhonePortrait.apply();

  // جلسة صوت واحدة: الصوت يشتغل حتى لو الجهاز على الصامت، ويمتزج مع أي صوت تاني
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    androidAudioAttributes: AndroidAudioAttributes(
      contentType: AndroidAudioContentType.speech,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
  ));

  final prefs = await SharedPreferences.getInstance();
  await AvatarController.init();

  late final ProviderContainer container;
  final speech = SpeechService(
    enabled: () => container.read(progressProvider).settings.speech,
    speed: () => container.read(progressProvider).settings.speechRate,
    enSpeed: () => container.read(progressProvider).settings.enSpeechRate,
  );
  final sfx = SfxService(
    enabled: () => container.read(progressProvider).settings.sfx,
    calm: () => container.read(progressProvider).settings.calm,
  );
  final music = MusicService(enabled: () => container.read(progressProvider).settings.music, speaking: speech.speaking);
  container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    speechProvider.overrideWithValue(speech),
    sfxProvider.overrideWithValue(sfx),
    musicProvider.overrideWithValue(music),
  ]);
  // قبل أي صوت: مقاطع اتسجّلت تاني ماتتسمعش بنسختها القديمة من الكاش
  await refreshAudioAssetCache();
  await Future.wait([speech.init(), sfx.init()]);
  unawaited(music.init());

  runApp(UncontrolledProviderScope(container: container, child: const RehlatiApp()));
}

/// بيقفل الموبايل على الطول. مقاس الشاشة ممكن يبقى صفر قبل أول فريم (أندرويد) —
/// ساعتها نستنى لحد ما يتعرف بدل ما التابلت يتقفل بالغلط.
class _PhonePortrait with WidgetsBindingObserver {
  static void apply() {
    final o = _PhonePortrait();
    if (!o._lock()) WidgetsBinding.instance.addObserver(o);
  }

  /// false = المقاس لسه مش معروف.
  bool _lock() {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view == null || view.physicalSize.isEmpty) return false;
    if (view.physicalSize.shortestSide / view.devicePixelRatio < 600) {
      unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]));
    }
    return true;
  }

  @override
  void didChangeMetrics() {
    if (_lock()) WidgetsBinding.instance.removeObserver(this);
  }
}
