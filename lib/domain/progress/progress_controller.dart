/// التقدّم كـ Riverpod Notifier + التخزين في shared_preferences.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'badges.dart';
import 'progress_data.dart';
import 'ranks.dart';

/// بيتعمل له override في main() بعد ما الـ prefs تتحمّل.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override in main'));

class ProgressRepository {
  ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const key = 'rehlati.progress.v1';

  ProgressData load() {
    try {
      final raw = _prefs.getString(key);
      if (raw != null) return ProgressData.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>())..pruneDays();
    } catch (_) {
      // ملف تالف — نبدأ من جديد بدل ما التطبيق يقع
    }
    return ProgressData();
  }

  Future<void> save(ProgressData p) => _prefs.setString(key, jsonEncode(p.toJson()));
}

final progressRepositoryProvider = Provider((ref) => ProgressRepository(ref.watch(sharedPrefsProvider)));

/// الإنجازات الجديدة — الواجهة بتسمع وتعرض toast.
final badgeEventsProvider = Provider<StreamController<Achievement>>((ref) {
  final c = StreamController<Achievement>.broadcast();
  ref.onDispose(c.close);
  return c;
});

/// كأس جديد — الواجهة بتحتفل بيه.
final rankEventsProvider = Provider<StreamController<Rank>>((ref) {
  final c = StreamController<Rank>.broadcast();
  ref.onDispose(c.close);
  return c;
});

/// الملف نفسه بيتعدّل في مكانه (زي الويب)، وكل تعديل بيعمل notify للمستمعين.
class ProgressController extends Notifier<ProgressData> {
  @override
  ProgressData build() => ref.read(progressRepositoryProvider).load();

  @override
  bool updateShouldNotify(ProgressData previous, ProgressData next) => true;

  ProgressData get data => state;

  /// طبّق تعديل، احفظ، وبلّغ الواجهة.
  void update(void Function(ProgressData p) change) {
    change(state);
    _commit();
  }

  void _commit() {
    unawaited(ref.read(progressRepositoryProvider).save(state));
    state = state;
  }

  /// يشيّك الإنجازات ويبعت الجديد منها للـ toasts.
  List<Achievement> checkRewards() {
    // الكأس الأول (زي Rewards.check في الويب)
    final seen = state.rankSeen;
    final up = rankCheck(state);
    if (up != null) ref.read(rankEventsProvider).add(up);
    if (state.rankSeen != seen) _commit();
    final fresh = checkBadges(state);
    if (fresh.isNotEmpty) {
      _commit();
      final events = ref.read(badgeEventsProvider);
      for (final b in fresh) {
        events.add(b);
      }
    }
    return fresh;
  }

  void reset() {
    final keep = state.settings;
    state = ProgressData(settings: keep);
    _commit();
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressData>(ProgressController.new);
