import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rehlati/domain/progress/backup.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/features/parent/avatar.dart';
import 'package:rehlati/features/parent/backup_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Repo = ProgressRepository;

/// ريبو بيفشل في الكتابة رقم [failAt] — عشان نتأكد إن الاسترجاع كله أو ولا حاجة.
class FailingRepo extends ProgressRepository {
  FailingRepo(super.prefs, this.failAt);
  final int failAt;
  int writes = 0;

  @override
  Future<void> write(String id, String json) async {
    if (++writes == failAt) throw StateError('disk');
    return super.write(id, json);
  }
}

ProgressData sara() => ProgressData(name: 'سارة', grade: 'kg2', stars: 40, unlocked: ['counting', 'chooseNumber'], best: {'counting': 3})
  ..recordMastery('counting', 9, 10)
  ..addTime(60000);

void main() {
  final at = DateTime(2026, 10, 10, 9);

  group('file format', () {
    test('a round trip keeps progress and optional photos', () {
      final raw = Backup.encode([BackupChild(sara(), photo: [1, 2, 3]), BackupChild(ProgressData(name: 'عمر'))], at: at);
      final back = Backup.decode(raw);
      expect(back.map((c) => c.progress.name), ['سارة', 'عمر']);
      final s = back.first.progress;
      expect([s.stars, s.age, s.unlocked, s.best['counting'], s.mastery['counting']!.rounds, s.timeMs],
          [40, 5, ['counting', 'chooseNumber'], 3, 1, 60000]);
      expect(back.first.photo, [1, 2, 3]);
      expect(back.last.photo, isNull);
    });

    test('malformed, foreign or newer files are rejected with a clear message', () {
      final good = jsonDecode(Backup.encode([BackupChild(sara())], at: at)) as Map<String, dynamic>;
      Map<String, dynamic> withChild(Map<String, dynamic> c) => {...good, 'children': [c]};
      final cases = <String, String>{
        'not json': 'نسخة احتياطية',
        jsonEncode({'format': 'other'}): 'نسخة احتياطية',
        jsonEncode({...good, 'version': Backup.version + 1}): 'أحدث',
        jsonEncode({...good, 'children': []}): 'مفيهوش أطفال',
        jsonEncode(withChild({'progress': 'x'})): 'ناقصة',
        jsonEncode(withChild({'progress': {'stars': 'lots'}})): 'مش سليمة',
        jsonEncode(withChild({'progress': {'schemaVersion': ProgressData.schemaVersion + 1}})): 'أحدث',
        jsonEncode(withChild({'progress': sara().toJson(), 'photo': '%%%'})): 'صورة',
        ' ' * (Backup.maxBytes + 1): 'كبير',
      };
      for (final e in cases.entries) {
        expect(() => Backup.decode(e.key), throwsA(isA<BackupException>().having((x) => x.message, 'message', contains(e.value))),
            reason: e.key.length > 60 ? e.key.substring(0, 60) : e.key);
      }
    });

    test('a child saved before schema 2 is migrated on import', () {
      final raw = jsonEncode({
        'format': Backup.format,
        'version': 1,
        'children': [
          {'progress': {'schemaVersion': 1, 'stars': 7, 'best': {'counting': 2}}},
        ],
      });
      final c = Backup.decode(raw).single.progress;
      expect([c.stars, c.mastery.keys.toList()], [7, ['counting']]);
    });

    test('the export file is written where asked and reads back', () async {
      final dir = Directory.systemTemp.createTempSync('backup');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = await writeBackupFile(dir, [BackupChild(sara())], at);
      expect(f.path, endsWith('rehlati-backup-2026-10-10.json'));
      expect(Backup.decode(f.readAsStringSync()).single.progress.name, 'سارة');
    });
  });

  group('restoring', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({Repo.key: jsonEncode(ProgressData(name: 'يوسف', stars: 9).toJson())});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer container([ProgressRepository? repo]) {
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        if (repo != null) progressRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('restoring as new children never touches existing ones', () async {
      final c = container();
      final ids = await c.read(progressProvider.notifier).importAsNew([sara(), ProgressData(name: 'عمر')]);
      final repo = c.read(progressRepositoryProvider);
      expect(repo.ids, [Repo.mainId, ...ids]);
      expect(ids.toSet(), hasLength(2));
      expect(c.read(activeChildProvider), Repo.mainId, reason: 'the active child stays');
      expect(c.read(progressProvider).name, 'يوسف');
      expect(repo.load(ids.first).stars, 40);
    });

    test('a failed restore leaves no half-written children', () async {
      final repo = FailingRepo(prefs, 2);
      final c = container(repo);
      c.read(progressProvider); // فتح الطفل بياخد نسخته السليمة — ده مش جزء من الاسترجاع
      await Future<void>.delayed(Duration.zero);
      final before = {...prefs.getKeys()};
      await expectLater(c.read(progressProvider.notifier).importAsNew([sara(), ProgressData(name: 'عمر')]), throwsStateError);
      expect(repo.ids, [Repo.mainId]);
      expect(prefs.getKeys(), before);
    });

    test('replacing keeps the old progress aside and rolls back if the write fails', () async {
      final c = container();
      await c.read(progressProvider.notifier).replaceActive(sara());
      expect(c.read(progressProvider).name, 'سارة');
      expect(jsonDecode(prefs.getString(Repo.beforeImportKeyFor(Repo.mainId))!)['name'], 'يوسف');

      SharedPreferences.setMockInitialValues({Repo.key: jsonEncode(ProgressData(name: 'يوسف', stars: 9).toJson())});
      prefs = await SharedPreferences.getInstance();
      final failing = container(FailingRepo(prefs, 1));
      await expectLater(failing.read(progressProvider.notifier).replaceActive(sara()), throwsStateError);
      expect(Repo(prefs).load(Repo.mainId).name, 'يوسف');
    });
  });

  test('a restored photo must be a real image, and comes back as a 256 px square JPEG', () {
    expect(normalizePhoto(Uint8List.fromList(utf8.encode('not an image'))), isNull);
    final png = img.encodePng(img.Image(width: 400, height: 300));
    final out = img.decodeJpg(normalizePhoto(png)!)!;
    expect([out.width, out.height], [256, 256]);
  });
}
