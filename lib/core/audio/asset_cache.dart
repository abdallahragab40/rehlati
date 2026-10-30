/// just_audio بيطلّع كل ملف صوت من الـ assets لملف في الـ temp باسمه، ومابيحدّثهوش تاني لو موجود —
/// فبعد تحديث التطبيق المقاطع اللي اتسجّلت من جديد (نفس الاسم) كانت بتتسمع بالنسخة القديمة.
/// بنمسح الكاش ده لما بصمة المقاطع ([clipsVersion]) تتغيّر، قبل أي صوت يشتغل.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'clip_manifest.g.dart';

Future<void> refreshAudioAssetCache() async {
  if (kIsWeb) return;
  try {
    await refreshAssetCacheIn((await getTemporaryDirectory()).path, clipsVersion, AudioPlayer.clearAssetCache);
  } catch (_) {
    // الكاش القديم أحسن من إن التطبيق مايفتحش
  }
}

/// [tmp] فولدر الـ temp، و[clear] بيمسح كاش just_audio — منفصلين عشان الاختبار.
@visibleForTesting
Future<void> refreshAssetCacheIn(String tmp, String version, Future<void> Function() clear) async {
  final marker = File('$tmp/rehlati_clips_version');
  if (marker.existsSync() && marker.readAsStringSync() == version) return;
  if (Directory('$tmp/just_audio_cache').existsSync()) await clear();
  marker.writeAsStringSync(version);
}
