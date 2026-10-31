import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/quran/quran_download.dart';
import 'package:rehlati/features/quran/quran_library.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/quran/recitation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_download_test.dart' show FakeStore, mp3, quranSource;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quran_lib'));
  tearDown(() => tmp.deleteSync(recursive: true));

  final juzAmma = juzList.first, tabarak = juzList[1];
  final husary = QuranConfig.reciter('husary'), minshawy = QuranConfig.reciter('minshawy');

  File ayahFile(Reciter r, int s, int a) =>
      File('${tmp.path}/${r.folder}/${'$s'.padLeft(3, '0')}${'$a'.padLeft(3, '0')}.mp3');
  void put(Reciter r, int s, int a, [List<int>? bytes]) => (ayahFile(r, s, a)..parent.createSync(recursive: true))
      .writeAsBytesSync(bytes ?? mp3);

  group('audio files', () {
    test('only files that look like MP3 count', () async {
      expect(RecitationPlayer.looksLikeAudio([0x49, 0x44, 0x33]), isTrue);
      expect(RecitationPlayer.looksLikeAudio([0xFF, 0xFB, 0x90]), isTrue);
      expect(RecitationPlayer.looksLikeAudio(utf8.encode('<html>')), isFalse);
      put(husary, 112, 1);
      put(husary, 112, 2, utf8.encode('<html>${'x' * 400}</html>'));
      put(husary, 112, 3, [0x49, 0x44, 0x33]); // مقطوع
      expect(await RecitationPlayer.isValid(ayahFile(husary, 112, 1)), isTrue);
      expect(await RecitationPlayer.isValid(ayahFile(husary, 112, 2)), isFalse);
      expect(await RecitationPlayer.isValid(ayahFile(husary, 112, 3)), isFalse);
    });

    test('an error page labelled as audio is rejected and a damaged file is replaced', () async {
      final f = ayahFile(husary, 112, 1);
      final html = MockClient((_) async => http.Response('<html>blocked</html>', 200, headers: {'content-type': 'audio/mpeg'}));
      expect(await RecitationPlayer.fetch(Uri.parse('https://x.test/a'), f, client: html), AyahFetch.failed);

      put(husary, 112, 1, utf8.encode('broken' * 100));
      final good = MockClient((_) async => http.Response.bytes(mp3, 200, headers: {'content-type': 'audio/mpeg'}));
      expect(await RecitationPlayer.fetch(Uri.parse('https://x.test/a'), f, client: good), AyahFetch.saved);
      expect(f.readAsBytesSync(), mp3);
    });

    test('a full disk is told apart from other write errors', () {
      expect(RecitationPlayer.classifyWriteError(const FileSystemException('write', 'p', OSError('No space left', 28))),
          AyahFetch.storageFull);
      expect(RecitationPlayer.classifyWriteError(const FileSystemException('write', 'p', OSError('Denied', 13))),
          AyahFetch.failed);
    });
  });

  group('download jobs', () {
    late SharedPreferences prefs;
    late FakeStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = FakeStore();
    });

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        ayahAudioStoreProvider.overrideWithValue(store),
        quranRepositoryProvider.overrideWithValue(QuranRepository(
          client: quranSource(chapters: [for (var n = 78; n <= 114; n++) n]),
          cacheFile: () async => File('${tmp.path}/q.json'),
        )),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('Minshawy with children repeating is the default, and its fallback is the same sheikh without repeating', () async {
      final r = container().read(reciterProvider);
      expect([r.reciter, r.repeat], ['minshawy_teacher', 'minshawy_teacher']);
      expect(QuranConfig.reciter(r.reciter).folder, 'Minshawy_Teacher_128kbps');
      expect(QuranConfig.reciter('removed-reciter').id, 'minshawy_teacher');
      final fallback = QuranConfig.reciter(QuranConfig.fallbackReciter);
      expect([fallback.id, fallback.teacher], ['minshawy', false], reason: 'a teacher fallback would retry itself forever');
      // اختيار قديم محفوظ بيفضل زي ما هو
      await prefs.setString('rehlati.reciter', 'husary');
      expect(container().read(reciterProvider).reciter, 'husary');
    });

    test('the recitation speed is kept, and an unknown saved speed falls back to normal', () async {
      expect(container().read(reciterProvider).speed, 1.0);
      container().read(reciterProvider.notifier).setSpeed(.75);
      final again = container().read(reciterProvider);
      expect([again.speed, again.reciter], [.75, QuranConfig.defaultReciter]);
      await prefs.setDouble('rehlati.recitationSpeed', .5);
      expect(container().read(reciterProvider).speed, 1.0);
    });

    test('a full disk stops the download early with a recoverable message', () async {
      store
        ..auto = ((_, _) => true)
        ..fullAfter = 3;
      final c = container();
      await c.read(quranDownloadProvider.notifier).start(juzAmma);
      final s = c.read(quranDownloadProvider)!;
      expect([s.phase, s.storageFull, s.done], [DownloadPhase.failed, true, 3]);
      expect(store.fetched.length, lessThan(20), reason: 'no point fetching the rest');
      expect(downloadLabel(s), contains('مساحة'));
      expect(c.read(quranDownloadProvider.notifier).pendingJob?.juz, juzAmma, reason: 'can be resumed');
    });

    test('an unfinished job survives a relaunch and resumes with its own reciter', () async {
      final first = container();
      final dl = first.read(quranDownloadProvider.notifier);
      first.read(reciterProvider.notifier).setReciter('minshawy');
      final run = dl.start(juzAmma);
      // نص ٣٧ سورة بيتجاب الأول، وبعدين التلاوة
      for (var i = 0; i < 200 && store.pending.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      store.answer(true);
      await Future<void>.delayed(Duration.zero);
      dl.cancel();
      store.answer(true, count: store.pending.length);
      await run;

      // "إعادة فتح": container جديد بنفس التخزين، والقارئ المختار اتغيّر
      final again = container();
      again.read(reciterProvider.notifier).setReciter('husary');
      final job = again.read(quranDownloadProvider.notifier).pendingJob!;
      expect([job.juz, job.reciter], [juzAmma, 'minshawy']);
      final before = store.stored.length;
      store
        ..fetched.clear()
        ..auto = ((_, _) => true);
      await again.read(quranDownloadProvider.notifier).start(job.juz, reciterId: job.reciter);
      expect(again.read(quranDownloadProvider)!.phase, DownloadPhase.complete);
      expect(store.fetched.every((k) => k.startsWith('${minshawy.folder}/')), isTrue);
      expect(store.fetched, hasLength(184 - before), reason: 'only the missing ayahs');
      expect(again.read(quranDownloadProvider.notifier).pendingJob, isNull);
    });
  });

  group('library', () {
    final chapters = [for (var n = 58; n <= 114; n++) QuranChapter(n, 'سورة $n', 2)];

    Future<List<ReciterStatus>> scan() =>
        scanLibrary(root: tmp, chapters: chapters, textCached: (n) async => n == 112);

    test('each reciter is counted from its own valid files only', () async {
      for (var n = 78; n <= 114; n++) {
        put(husary, n, 1);
        put(husary, n, 2);
      }
      put(husary, 67, 1, utf8.encode('broken' * 100));
      File('${tmp.path}/${husary.folder}/067002.mp3.part').writeAsBytesSync(mp3);
      put(minshawy, 112, 1);

      final lib = await scan();
      final h = lib.firstWhere((x) => x.reciter.id == 'husary');
      final m = lib.firstWhere((x) => x.reciter.id == 'minshawy');
      expect([h.juz.first.complete, h.juz.first.present, h.juz.first.expected], [true, 74, 74]);
      expect([h.juz[1].complete, h.juz[1].present], [false, 0]);
      expect(h.damaged, 1);
      expect(h.juz.first.textCached, 1);
      expect([m.juz.first.complete, m.juz.first.present], [false, 1], reason: "husary's files never count for minshawy");
      expect(h.bytes, 74 * mp3.length);
    });

    test('without the chapter list sizes still show but nothing claims to be complete', () async {
      put(husary, 112, 1);
      final lib = await scanLibrary(root: tmp, chapters: null, textCached: (_) async => false);
      final j = lib.firstWhere((x) => x.reciter.id == 'husary').juz.first;
      expect([j.present, j.expected, j.complete], [1, null, false]);
    });

    test('deleting a juz or a reciter frees space and leaves other audio alone', () async {
      put(husary, 112, 1);
      put(husary, 67, 1);
      put(minshawy, 112, 1);
      await deleteAudio(tmp, husary, juz: juzAmma);
      var lib = await scan();
      expect(lib.firstWhere((x) => x.reciter.id == 'husary').juz.map((j) => j.present), [0, 1, 0]);
      expect(lib.firstWhere((x) => x.reciter.id == 'minshawy').present, 1);

      await deleteAudio(tmp, husary);
      lib = await scan();
      expect(lib.firstWhere((x) => x.reciter.id == 'husary').bytes, 0);
      expect(Directory('${tmp.path}/${husary.folder}').existsSync(), isFalse);
      expect(tabarak.$1, 'جزء تبارك');
    });
  });
}
