import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/rng.dart';
import 'sfx_service.dart';
import 'speech_service.dart';

/// الخدمات الحقيقية بتتعمل في main() وتتحط هنا بـ overrides؛ الاختبارات بتحط fakes.
final speechProvider = Provider<Speech>((ref) => throw UnimplementedError('override in main'));
final sfxProvider = Provider<Sfx>((ref) => throw UnimplementedError('override in main'));

/// مصدر العشوائية للمحرك — الاختبارات بتحط seed ثابت.
final rngProvider = Provider<Rng>((ref) => Rng());
