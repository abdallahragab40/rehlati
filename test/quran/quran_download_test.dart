import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/quran/quran_download.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/quran/recitation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// جزء صغير للاختبار: الإخلاص (٤) والفلق (٥) = ٩ آيات.
const juz = ('جزء الاختبار', 112, 113);
const total = 9;

/// ملفات التلاوة في الذاكرة. كل fetch بيستنى لحد ما الاختبار يرد عليه، إلا لو [auto] موجودة.
class FakeStore implements AyahAudioStore {
  final stored = <String>{};
  final fetched = <String>[];
  final pending = <(String, Completer<bool>)>[];
  bool Function(int surah, int ayah)? auto;

  @override
  Future<bool> has(String folder, int surah, int ayah) async => stored.contains('$folder/$surah:$ayah');

  @override
  Future<bool> fetch(String folder, int surah, int ayah) async {
    final key = '$folder/$surah:$ayah';
    fetched.add(key);
    final ok = auto != null ? auto!(surah, ayah) : await _wait(key);
    if (ok) stored.add(key);
    return ok;
  }

  Future<bool> _wait(String key) {
    final c = Completer<bool>();
    pending.add((key, c));
    return c.future;
  }

  void answer(bool ok, {int count = 1}) {
    for (var i = 0; i < count; i++) {
      pending.removeAt(0).$2.complete(ok);
    }
  }
}

http.Response ok(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

Map<String, Object> verses(int n, int count) => {
      'verses': [for (var a = 1; a <= count; a++) {'verse_key': '$n:$a', 'text_uthmani': 'آية $a'}],
    };

/// المصدر الأساسي بيرد بقائمة السور ونصها؛ [textGate] بيأخّر نص السور.
MockClient quranCom({List<int> chapters = const [112, 113], Completer<void>? textGate}) => MockClient((r) async {
      if (r.url.path.endsWith('/chapters')) {
        return ok({
          'chapters': [
            for (final n in chapters) {'id': n, 'name_arabic': 'سورة $n', 'verses_count': n == 112 ? 4 : 5},
          ],
        });
      }
      if (r.url.host != 'api.quran.com') return http.Response('down', 503);
      await textGate?.future;
      final n = int.parse(r.url.queryParameters['chapter_number']!);
      return ok(verses(n, n == 112 ? 4 : 5));
    });

Future<void> flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late Directory tmp;
  late FakeStore store;
  late SharedPreferences prefs;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('quran_dl');
    store = FakeStore();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  ProviderContainer container(MockClient client) {
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      ayahAudioStoreProvider.overrideWithValue(store),
      quranRepositoryProvider.overrideWithValue(
        QuranRepository(client: client, cacheFile: () async => File('${tmp.path}/q.json')),
      ),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('every ayah on the device → complete, labelled with the reciter', () async {
    store.auto = (_, _) => true;
    final c = container(quranCom());
    await c.read(quranDownloadProvider.notifier).start(juz);
    final s = c.read(quranDownloadProvider)!;
    expect([s.phase, s.done, s.total, s.failed], [DownloadPhase.complete, total, total, 0]);
    expect(downloadLabel(s), allOf(contains('✅'), contains('الحصري')));
  });

  test('cancel after the first ayah is cancelled, not offline-ready, and retry fetches only the rest', () async {
    final c = container(quranCom());
    final dl = c.read(quranDownloadProvider.notifier);
    unawaited(dl.start(juz));
    await flush();
    expect(store.pending, hasLength(4), reason: 'four workers in flight');

    store.answer(true);
    await flush();
    expect(c.read(quranDownloadProvider)!.done, 1);

    dl.cancel();
    final cancelled = c.read(quranDownloadProvider)!;
    expect([cancelled.phase, cancelled.done, cancelled.total], [DownloadPhase.cancelled, 1, total]);
    expect(downloadLabel(cancelled), isNot(contains('✅')));

    // الطلبات اللي كانت شغالة تخلص بعد الإلغاء — الحالة ماتتغيرش
    store.answer(true, count: store.pending.length);
    await flush();
    expect(c.read(quranDownloadProvider)!.phase, DownloadPhase.cancelled);
    expect(c.read(quranDownloadProvider)!.done, 1);
    expect(store.pending, isEmpty, reason: 'no new work after cancel');

    final before = store.stored.length;
    store.fetched.clear();
    store.auto = (_, _) => true;
    await dl.start(juz);
    expect(c.read(quranDownloadProvider)!.phase, DownloadPhase.complete);
    expect(store.fetched, hasLength(total - before), reason: 'files already saved are not fetched again');
  });

  test('cancel while the text is still loading never reports progress or success', () async {
    final gate = Completer<void>();
    final c = container(quranCom(textGate: gate));
    final dl = c.read(quranDownloadProvider.notifier);
    final run = dl.start(juz);
    await flush();
    dl.cancel();
    gate.complete();
    await run;
    final s = c.read(quranDownloadProvider)!;
    expect([s.phase, s.done], [DownloadPhase.cancelled, 0]);
    expect(store.fetched, isEmpty);
    expect(downloadLabel(s), isNot(contains('✅')));
  });

  test('no network for the text → failed with nothing fetched', () async {
    final c = container(MockClient((_) async => throw const SocketException('offline')));
    await c.read(quranDownloadProvider.notifier).start(juz);
    final s = c.read(quranDownloadProvider)!;
    expect([s.phase, s.total], [DownloadPhase.failed, 0]);
    expect(downloadLabel(s), contains('النت'));
  });

  test('audio failures give partial or failed, never complete', () async {
    store.auto = (n, a) => !(n == 113 && a == 5);
    final c = container(quranCom());
    final dl = c.read(quranDownloadProvider.notifier);
    await dl.start(juz);
    var s = c.read(quranDownloadProvider)!;
    expect([s.phase, s.done, s.failed], [DownloadPhase.partial, total - 1, 1]);

    store
      ..stored.clear()
      ..auto = (_, _) => false;
    await dl.start(juz);
    s = c.read(quranDownloadProvider)!;
    expect([s.phase, s.done, s.failed], [DownloadPhase.failed, 0, total]);
    expect(downloadLabel(s), isNot(contains('✅')));
  });

  test('a chapter list missing a surah of the juz is not complete', () async {
    store.auto = (_, _) => true;
    final c = container(quranCom(chapters: [112]));
    await c.read(quranDownloadProvider.notifier).start(juz);
    expect(c.read(quranDownloadProvider)!.phase, DownloadPhase.failed);
    expect(store.fetched, isEmpty);
  });

  test('a replaced run cannot change the newer run', () async {
    final c = container(quranCom());
    final dl = c.read(quranDownloadProvider.notifier);
    unawaited(dl.start(juz));
    await flush();
    final stale = List.of(store.pending);
    store.pending.clear();

    store.auto = (_, _) => true;
    final second = dl.start(('جزء تاني', 112, 113));
    for (final (_, c) in stale) {
      c.complete(false);
    }
    await second;
    final s = c.read(quranDownloadProvider)!;
    expect([s.juz, s.phase, s.failed], ['جزء تاني', DownloadPhase.complete, 0]);
  });

  test('cancel with nothing running is a no-op', () {
    final c = container(quranCom());
    c.read(quranDownloadProvider.notifier).cancel();
    expect(c.read(quranDownloadProvider), isNull);
  });

  test('two requests for the same ayah share one download and both succeed', () async {
    var calls = 0;
    final gate = Completer<void>();
    final client = MockClient((_) async {
      calls++;
      await gate.future;
      return http.Response.bytes([1, 2, 3], 200, headers: {'content-type': 'audio/mpeg'});
    });
    final file = File('${tmp.path}/a/112001.mp3');
    final url = Uri.parse('https://example.test/112001.mp3');
    final a = RecitationPlayer.download(url, file, client: client);
    final b = RecitationPlayer.download(url, file, client: client);
    gate.complete();
    expect(await Future.wait([a, b]), [true, true]);
    expect(calls, 1);
    expect(file.readAsBytesSync(), [1, 2, 3]);
  });
}
