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

/// مشكلة في تخزين التقدّم — بتظهر لولي الأمر في لوحته.
enum StorageIssue {
  /// الكتابة على الجهاز فشلت (غالبًا المساحة مليانة).
  saveFailed,

  /// الملف ماتقريش فرجعنا لآخر نسخة سليمة.
  restoredBackup,

  /// الملف ماتقريش ومفيش نسخة سليمة — بدأنا من جديد والنسخة البايظة محفوظة.
  unreadable,

  /// الملف من نسخة أحدث من التطبيق — اتقرا على قد ما نقدر والأصل محفوظ.
  newerVersion,
}

class LoadResult {
  const LoadResult(this.data, [this.issue]);
  final ProgressData data;
  final StorageIssue? issue;
}

/// ملف تقدّم لكل طفل (إخوات على نفس التابلت). الطفل الأول بيفضل على المفتاح القديم
/// عشان التقدّم اللي قبل الملفات يفضل زي ما هو.
///
/// لكل طفل كمان:
/// - نسخة سليمة ([backupKeyFor]) بتتاخد كل ما ملفه يتفتح — بنرجعلها لو الملف باظ.
/// - نسخة الإنقاذ ([recoveryKeyFor]): أول ملف ماعرفناش نقراه بيتحفظ زي ما هو بدل ما الحفظ الجاي يمسحه.
class ProgressRepository {
  ProgressRepository(this._prefs);
  final SharedPreferences _prefs;

  static const key = 'rehlati.progress.v1';
  static const profilesKey = 'rehlati.profiles.v1';
  static const mainId = 'main';

  static String keyFor(String id) => id == mainId ? key : '$key.$id';
  static String backupKeyFor(String id) => 'rehlati.backup.v1.$id';
  static String recoveryKeyFor(String id) => 'rehlati.recovery.v1.$id';

  // ---------------------------------------------------------------- الإخوات

  static final _childKey = RegExp('^${RegExp.escape(key)}\\.([A-Za-z0-9_]+)\$');

  /// قائمة الإخوات بعد التحقق: ids نصوص مش فاضية ومن غير تكرار، والنشط واحد منهم.
  /// لو الملف باظ بنلاقي الإخوات من مفاتيح ملفاتهم بدل ما يختفوا.
  ({String active, List<String> ids}) get _profiles {
    try {
      final raw = _prefs.getString(profilesKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map;
        final ids = <String>{
          for (final i in j['ids'] as List)
            if (i is String && i.isNotEmpty) i,
        }.toList();
        if (ids.isNotEmpty) {
          final active = j['active'];
          return (active: active is String && ids.contains(active) ? active : ids.first, ids: ids);
        }
      }
    } catch (_) {}
    final found = [
      for (final k in _prefs.getKeys())
        if (_childKey.firstMatch(k) case final m?) m[1]!,
    ]..sort();
    return (active: mainId, ids: [mainId, ...found]);
  }

  List<String> get ids => _profiles.ids;
  String get activeId => _profiles.active;

  Future<void> _saveProfiles(String active, List<String> ids) async {
    if (!await _prefs.setString(profilesKey, jsonEncode({'active': active, 'ids': ids}))) {
      throw StateError('profiles not saved');
    }
  }

  // ---------------------------------------------------------------- القراءة

  /// خطوات الترقية: النسخة ← دالة بتطلّع الملف للنسخة اللي بعدها.
  static final migrations = <int, Map<String, dynamic> Function(Map<String, dynamic>)>{
    // قبل رقم النسخة (والويب): الحقول الناقصة بتاخد قيمها الافتراضية في fromJson
    0: (j) => j,
  };

  /// يفك الملف ويرقّيه. بيرمي لو الشكل غلط، و newer = true لو من نسخة أحدث من التطبيق.
  static ({ProgressData data, bool newer}) decode(String raw) {
    var j = (jsonDecode(raw) as Map).cast<String, dynamic>();
    var v = (j['schemaVersion'] as num?)?.toInt() ?? 0;
    final newer = v > ProgressData.schemaVersion;
    for (; v < ProgressData.schemaVersion; v++) {
      j = migrations[v]!(j);
    }
    return (data: ProgressData.fromJson(j)..pruneDays(), newer: newer);
  }

  ProgressData load([String? id]) => read(id ?? activeId).data;

  /// [snapshot]: لو الملف سليم ناخد منه النسخة السليمة (بنعملها لما الطفل يتفتح، مش لكل قراءة).
  LoadResult read(String id, {bool snapshot = false}) {
    final raw = _prefs.getString(keyFor(id));
    if (raw == null) return LoadResult(ProgressData());
    try {
      final (:data, :newer) = decode(raw);
      if (newer) {
        _keep(id, raw);
        return LoadResult(data, StorageIssue.newerVersion);
      }
      if (snapshot && _prefs.getString(backupKeyFor(id)) != raw) unawaited(_prefs.setString(backupKeyFor(id), raw));
      return LoadResult(data);
    } catch (_) {
      // ملف تالف — مانمسحوش ونرجع لآخر نسخة سليمة لو موجودة
      _keep(id, raw);
      final backup = _prefs.getString(backupKeyFor(id));
      if (backup != null) {
        try {
          return LoadResult(decode(backup).data, StorageIssue.restoredBackup);
        } catch (_) {}
      }
      return LoadResult(ProgressData(), StorageIssue.unreadable);
    }
  }

  /// أول نسخة مش مفهومة بتفضل — مانكتبش فوقها بنسخة بايظة تانية.
  void _keep(String id, String raw) {
    if (_prefs.getString(recoveryKeyFor(id)) == null) unawaited(_prefs.setString(recoveryKeyFor(id), raw));
  }

  // ---------------------------------------------------------------- الكتابة

  /// بيكتب ملف طفل محدد — الـ id بيتمسك وقت التعديل مش وقت الكتابة.
  Future<void> write(String id, String json) async {
    if (!await _prefs.setString(keyFor(id), json)) throw StateError('progress not saved');
  }

  Future<void> setActive(String id) => _saveProfiles(id, ids);

  /// طفل جديد بإعدادات الطفل الحالي (الصوت والهدف…) — وبيبقى هو النشط.
  Future<String> add(Settings settings) async {
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    await write(id, jsonEncode(ProgressData(settings: Settings.fromJson(settings.toJson())).toJson()));
    await _saveProfiles(id, [...ids, id]);
    return id;
  }

  /// بيمسح ملف الطفل ونسخه (السليمة والإنقاذ). الصورة بتتمسح من AvatarController.delete.
  Future<void> remove(String id) async {
    final rest = ids.where((i) => i != id).toList();
    if (rest.isEmpty) return;
    await _saveProfiles(activeId == id ? rest.first : activeId, rest);
    await forget(id);
  }

  /// يمسح الملف ونسخه — للمسح وإعادة الضبط (مفيش رجوع زي ما الرسالة بتقول).
  Future<void> forget(String id, {bool keepProgress = false}) async {
    if (!keepProgress) await _prefs.remove(keyFor(id));
    await _prefs.remove(backupKeyFor(id));
    await _prefs.remove(recoveryKeyFor(id));
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

/// آخر مشكلة تخزين — لوحة ولي الأمر بتعرضها لحد ما يقفلها.
class StorageIssueController extends Notifier<StorageIssue?> {
  @override
  StorageIssue? build() => null;

  void report(StorageIssue? issue) {
    if (issue != null) state = issue;
  }

  void dismiss() => state = null;
}

final storageIssueProvider = NotifierProvider<StorageIssueController, StorageIssue?>(StorageIssueController.new);

/// الملف نفسه بيتعدّل في مكانه (زي الويب)، وكل تعديل بيعمل notify للمستمعين.
///
/// الحفظ بيمشي بالدور: كل تعديل بياخد نسخة JSON ومعاها id الطفل وقتها، فالتبديل
/// لطفل تاني مايكتبش تقدّم طفل فوق التاني. التبديل والمسح بيستنوا الحفظ اللي فاضل.
class ProgressController extends Notifier<ProgressData> {
  late String _id;
  Future<void> _saving = Future.value();

  ProgressRepository get _repo => ref.read(progressRepositoryProvider);

  @override
  ProgressData build() => _open(_repo.activeId);

  ProgressData _open(String id) {
    _id = id;
    final r = _repo.read(id, snapshot: true);
    // بعد ما الـ build يخلص — مايصحش نعدّل provider تاني جواه
    if (r.issue != null) {
      Future.microtask(() {
        if (ref.mounted) ref.read(storageIssueProvider.notifier).report(r.issue);
      });
    }
    return r.data;
  }

  @override
  bool updateShouldNotify(ProgressData previous, ProgressData next) => true;

  ProgressData get data => state;

  /// طبّق تعديل، احفظ، وبلّغ الواجهة.
  void update(void Function(ProgressData p) change) {
    change(state);
    _commit();
  }

  void _commit() {
    final repo = _repo, id = _id, json = jsonEncode(state.toJson());
    _saving = _saving.then((_) => repo.write(id, json)).catchError((Object _) {
      if (ref.mounted) ref.read(storageIssueProvider.notifier).report(StorageIssue.saveFailed);
    });
    state = state;
  }

  /// يستنى كل الحفظ اللي لسه ماخلصش — ومعاه أي حفظ اتضاف وإحنا مستنيين.
  Future<void> flush() async {
    Future<void> last;
    do {
      last = _saving;
      await last;
    } while (!identical(last, _saving));
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
    await flush();
    await _repo.setActive(id);
    state = _open(id);
  }

  Future<void> addChild() async {
    await flush();
    state = _open(await _repo.add(state.settings));
  }

  Future<void> removeChild(String id) async {
    await flush();
    await _repo.remove(id);
    if (id == _id) {
      state = _open(_repo.activeId);
    } else {
      // الطفل النشط مالوش دعوة — نبلّغ الواجهة بس عشان قايمة الإخوات تتحدّث
      state = state;
    }
  }

  /// إعادة الضبط: الإعدادات بتفضل، والباقي (الاسم والعمر والنجوم والفتح والسجل) بيتمسح
  /// ومعاه النسخ الاحتياطية. الصورة بتفضل.
  void reset() {
    final keep = state.settings;
    state = ProgressData(settings: keep);
    final repo = _repo, id = _id;
    // لو مسح النسخ فشل، حفظ الملف الجديد لازم يكمّل
    _saving = _saving.then((_) => repo.forget(id, keepProgress: true)).catchError((Object _) {});
    _commit();
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressData>(ProgressController.new);

/// id الطفل النشط — بيتغيّر بس لما نبدّل طفل.
final activeChildProvider = Provider<String>((ref) {
  ref.watch(progressProvider);
  return ref.read(progressRepositoryProvider).activeId;
});
