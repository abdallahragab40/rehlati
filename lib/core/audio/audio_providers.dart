import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/rng.dart';
import 'music_service.dart';
import 'sfx_service.dart';
import 'speech_service.dart';

/// الخدمات الحقيقية بتتعمل في main() وتتحط هنا بـ overrides؛ الاختبارات بتحط fakes.
final speechProvider = Provider<Speech>((ref) => throw UnimplementedError('override in main'));
final sfxProvider = Provider<Sfx>((ref) => throw UnimplementedError('override in main'));
final musicProvider = Provider<Music>((ref) => _NoMusic());

/// الافتراضي في الاختبارات: مفيش موسيقى.
class _NoMusic implements Music {
  @override
  void quiet(bool yes) {}
  @override
  void background(bool yes) {}
  @override
  void refresh() {}
  @override
  void theme(String id) {}
}

/// مصدر العشوائية للمحرك — الاختبارات بتحط seed ثابت.
final rngProvider = Provider<Rng>((ref) => Rng());
