import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/asset_cache.dart';

/// just_audio بيحتفظ بنسخة من كل مقطع في الـ temp: لازم تتمسح لما المقاطع تتسجّل تاني.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('audio_cache'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('the cache is cleared once when the clips change, and kept otherwise', () async {
    var cleared = 0;
    Future<void> clear() async => cleared++;
    Directory('${tmp.path}/just_audio_cache/assets').createSync(recursive: true);

    await refreshAssetCacheIn(tmp.path, 'v1', clear);
    expect(cleared, 1, reason: 'an install from before the fingerprint may hold old clips');
    await refreshAssetCacheIn(tmp.path, 'v1', clear);
    expect(cleared, 1);
    await refreshAssetCacheIn(tmp.path, 'v2', clear);
    expect(cleared, 2, reason: 're-rendered clips');
  });

  test('a fresh install has nothing to clear', () async {
    var cleared = 0;
    await refreshAssetCacheIn(tmp.path, 'v1', () async => cleared++);
    expect(cleared, 0);
    expect(File('${tmp.path}/rehlati_clips_version').readAsStringSync(), 'v1');
  });
}
