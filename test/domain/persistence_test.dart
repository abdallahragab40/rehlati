import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Repo = ProgressRepository;

/// ريبو بيكتب ببطء أو بيفشل — عشان نختبر ترتيب الحفظ وفشله.
class FlakyRepo extends ProgressRepository {
  FlakyRepo(super.prefs);
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<void> write(String id, String json) async {
    await gate?.future;
    if (fail) throw StateError('disk full');
    return super.write(id, json);
  }
}

Map<String, dynamic> stored(SharedPreferences p, String id) =>
    (jsonDecode(p.getString(Repo.keyFor(id))!) as Map).cast<String, dynamic>();

Future<void> flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late SharedPreferences prefs;

  Future<void> start(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
  }

  ProviderContainer container([ProgressRepository? repo]) {
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      if (repo != null) progressRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('profile list', () {
    test('missing, malformed or empty metadata falls back to the main child', () async {
      for (final raw in ['not json', '[]', '{"ids": "main"}', '{"ids": []}', '{"ids": [1, ""]}']) {
        await start({Repo.profilesKey: raw});
        final r = Repo(prefs);
        expect([r.ids, r.activeId], [
          [Repo.mainId],
          Repo.mainId,
        ], reason: raw);
      }
    });

    test('an active id that is not a child picks the first child; duplicates are dropped', () async {
      await start({Repo.profilesKey: jsonEncode({'active': 'gone', 'ids': ['main', 'c1', 'c1', 7]})});
      final r = Repo(prefs);
      expect(r.ids, ['main', 'c1']);
      expect(r.activeId, 'main');
    });

    test('unreadable metadata keeps siblings whose progress is still on the device', () async {
      await start({
        Repo.profilesKey: '{broken',
        Repo.key: '{}',
        Repo.keyFor('c2'): '{}',
        Repo.keyFor('c1'): '{}',
        Repo.backupKeyFor('c1'): '{}',
      });
      expect(Repo(prefs).ids, ['main', 'c1', 'c2']);
    });
  });

  group('reading progress', () {
    test('progress saved before schema versions migrates and keeps its data', () async {
      await start({Repo.key: jsonEncode({'stars': 7, 'unlocked': ['counting']})});
      final r = Repo(prefs).read(Repo.mainId);
      expect([r.data.stars, r.data.unlocked, r.issue], [
        7,
        ['counting'],
        null,
      ]);
      expect(ProgressData.fromJson(r.data.toJson()).stars, 7);
      expect(r.data.toJson()['schemaVersion'], ProgressData.schemaVersion);
    });

    test('a bad payload restores the last good snapshot and keeps the bad copy', () async {
      final good = jsonEncode(ProgressData(stars: 5).toJson());
      await start({Repo.key: good});
      final c = container();
      expect(c.read(progressProvider).stars, 5);
      await flush();
      expect(prefs.getString(Repo.backupKeyFor(Repo.mainId)), good, reason: 'snapshot taken when opened');

      await prefs.setString(Repo.key, '{"stars": "lots"}');
      final r = Repo(prefs).read(Repo.mainId);
      await flush();
      expect([r.data.stars, r.issue], [5, StorageIssue.restoredBackup]);
      expect(prefs.getString(Repo.recoveryKeyFor(Repo.mainId)), '{"stars": "lots"}');
    });

    test('a bad payload with no snapshot starts fresh but is never overwritten silently', () async {
      await start({Repo.key: '[1, 2]'});
      final c = container();
      expect(c.read(progressProvider).stars, 0);
      await flush();
      expect(c.read(storageIssueProvider), StorageIssue.unreadable);

      c.read(progressProvider.notifier).update((p) => p.stars = 1);
      await c.read(progressProvider.notifier).flush();
      expect(prefs.getString(Repo.recoveryKeyFor(Repo.mainId)), '[1, 2]');
      expect(stored(prefs, Repo.mainId)['stars'], 1);

      // ملف بايظ تاني مايكتبش فوق أول نسخة إنقاذ
      await prefs.setString(Repo.key, 'garbage');
      Repo(prefs).read(Repo.mainId);
      await flush();
      expect(prefs.getString(Repo.recoveryKeyFor(Repo.mainId)), '[1, 2]');
    });

    test('progress from a newer app version is read as far as possible and preserved', () async {
      final raw = jsonEncode({'schemaVersion': ProgressData.schemaVersion + 1, 'stars': 4, 'newField': true});
      await start({Repo.key: raw});
      final c = container();
      expect(c.read(progressProvider).stars, 4);
      await flush();
      expect(c.read(storageIssueProvider), StorageIssue.newerVersion);
      expect(prefs.getString(Repo.recoveryKeyFor(Repo.mainId)), raw);
    });
  });

  group('saving', () {
    test('a failed write is reported to the parent', () async {
      await start({});
      final repo = FlakyRepo(prefs)..fail = true;
      final c = container(repo);
      c.read(progressProvider.notifier).update((p) => p.stars = 3);
      await c.read(progressProvider.notifier).flush();
      expect(c.read(storageIssueProvider), StorageIssue.saveFailed);

      c.read(storageIssueProvider.notifier).dismiss();
      repo.fail = false;
      c.read(progressProvider.notifier).update((p) => p.stars = 4);
      await c.read(progressProvider.notifier).flush();
      expect(c.read(storageIssueProvider), isNull);
      expect(stored(prefs, Repo.mainId)['stars'], 4, reason: 'the next save writes everything');
    });

    test('slow saves land in order and switching waits for them', () async {
      await start({});
      final repo = FlakyRepo(prefs);
      final sibling = await repo.add(Settings());
      await repo.setActive(Repo.mainId);
      repo.gate = Completer();
      final c = container(repo);
      final n = c.read(progressProvider.notifier);
      for (var i = 1; i <= 5; i++) {
        n.update((p) => p.stars = i);
      }

      final switching = n.switchTo(sibling);
      // تعديل بعد ما التبديل بدأ وقبل ما يخلص — لازم يروح للطفل الأولاني
      n.update((p) => p.stars = 6);
      repo.gate!.complete();
      await switching;
      await n.flush();

      expect(stored(prefs, Repo.mainId)['stars'], 6);
      expect(stored(prefs, sibling)['stars'], 0);
      expect(c.read(progressProvider).stars, 0);
      expect(c.read(activeChildProvider), sibling);
    });

    test('removing one child never resets a sibling and deletes its copies', () async {
      await start({});
      final c = container();
      final n = c.read(progressProvider.notifier);
      n.update((p) => p..name = 'يوسف'..stars = 9);
      await n.addChild();
      final second = c.read(activeChildProvider);
      n.update((p) => p..name = 'مريم'..stars = 2);
      await n.switchTo(Repo.mainId);
      await n.switchTo(second);
      await flush();
      expect(prefs.getString(Repo.backupKeyFor(second)), isNotNull);

      // مسح طفل مش نشط: النشط يفضل زي ما هو
      await n.removeChild(Repo.mainId);
      expect(c.read(progressProvider).name, 'مريم');
      expect(c.read(progressProvider).stars, 2);
      expect(prefs.getString(Repo.key), isNull);
      expect(prefs.getString(Repo.backupKeyFor(Repo.mainId)), isNull);
      expect(Repo(prefs).ids, [second]);
    });

    test('reset keeps settings, clears progress and its snapshots', () async {
      await start({Repo.key: jsonEncode(ProgressData(name: 'يوسف', stars: 9, settings: Settings(goal: 30)).toJson())});
      final c = container();
      final n = c.read(progressProvider.notifier);
      await flush();
      expect(prefs.getString(Repo.backupKeyFor(Repo.mainId)), isNotNull);

      n.reset();
      await n.flush();
      final saved = stored(prefs, Repo.mainId);
      expect([saved['name'], saved['stars'], (saved['settings'] as Map)['goal']], ['', 0, 30]);
      expect(prefs.getString(Repo.backupKeyFor(Repo.mainId)), isNull);
    });
  });
}
