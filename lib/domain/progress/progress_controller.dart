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

/// ملف تقدّم لكل طفل (إخوات على نفس التابلت). الطفل الأول بيفضل على المفتاح القديم
/// عشان التقدّم اللي قبل الملفات يفضل زي ما هو.
class ProgressRepository {
  ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const key = 'rehlati.progress.v1';
  static const profilesKey = 'rehlati.profiles.v1';
  static const mainId = 'main';

  static String keyFor(String id) => id == mainId ? key : '$key.$id';

  Map<String, dynamic> get _profiles {
    try {
      final raw = _prefs.getString(profilesKey);
      if (raw != null) return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {}
    return {'active': mainId, 'ids': [mainId]};
  }

  List<String> get ids => [for (final i in _profiles['ids'] as List) '$i'];
  String get activeId => '${_profiles['active']}';

  Future<void> _saveProfiles(String active, List<String> ids) =>
      _prefs.setString(profilesKey, jsonEncode({'active': active, 'ids': ids}));

  ProgressData load([String? id]) {
    try {
      final raw = _prefs.getString(keyFor(id ?? activeId));
      if (raw != null) return ProgressData.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>())..pruneDays();
    } catch (_) {
      // ملف تالف — نبدأ من جديد بدل ما التطبيق يقع
    }
    return ProgressData();
  }

  Future<void> save(ProgressData p) => _prefs.setString(keyFor(activeId), jsonEncode(p.toJson()));

  Future<void> setActive(String id) => _saveProfiles(id, ids);

  /// طفل جديد بإعدادات الطفل الحالي (الصوت والهدف…) — وبيبقى هو النشط.
  Future<String> add(Settings settings) async {
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString(keyFor(id), jsonEncode(ProgressData(settings: Settings.fromJson(settings.toJson())).toJson()));
    await _saveProfiles(id, [...ids, id]);
    return id;
  }

  Future<void> remove(String id) async {
    final rest = ids.where((i) => i != id).toList();
    if (rest.isEmpty) return;
    await _prefs.remove(keyFor(id));
    await _saveProfiles(activeId == id ? rest.first : activeId, rest);
  }
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

  /// يبدّل لطفل تاني (أو طفل جديد بـ [add]).
  Future<void> switchTo(String id) async {
    final repo = ref.read(progressRepositoryProvider);
    await repo.setActive(id);
    state = repo.load(id);
  }

  Future<void> addChild() async {
    final repo = ref.read(progressRepositoryProvider);
    state = repo.load(await repo.add(state.settings));
  }

  Future<void> removeChild(String id) async {
    final repo = ref.read(progressRepositoryProvider);
    await repo.remove(id);
    state = repo.load();
  }

  void reset() {
    final keep = state.settings;
    state = ProgressData(settings: keep);
    _commit();
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressData>(ProgressController.new);

/// id الطفل النشط — بيتغيّر بس لما نبدّل طفل.
final activeChildProvider = Provider<String>((ref) {
  ref.watch(progressProvider);
  return ref.read(progressRepositoryProvider).activeId;
});
