import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/audio/audio_providers.dart';
import 'core/audio/music_service.dart';
import 'core/audio/sfx_service.dart';
import 'core/audio/speech_service.dart';
import 'domain/progress/progress_controller.dart';
import 'features/parent/avatar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // الموبايل بالطول بس؛ التابلت يلف براحته
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortest < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

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
  );
  final sfx = SfxService(enabled: () => container.read(progressProvider).settings.sfx);
  final music = MusicService(enabled: () => container.read(progressProvider).settings.music, speaking: speech.speaking);
  container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    speechProvider.overrideWithValue(speech),
    sfxProvider.overrideWithValue(sfx),
    musicProvider.overrideWithValue(music),
  ]);
  await Future.wait([speech.init(), sfx.init()]);
  unawaited(music.init());

  runApp(UncontrolledProviderScope(container: container, child: const RehlatiApp()));
}
