import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/quran/recitation.dart';

// عينات بنفس شكل ردود المصادر (سورة الإخلاص) — للاختبار بس.
const basmala = '﻿بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const a1 = 'قُلْ هُوَ ٱللَّهُ أَحَدٌ';
const a2 = 'ٱللَّهُ ٱلصَّمَدُ';

String quranComChapters() => jsonEncode({
      'chapters': [
        {'id': 1, 'name_arabic': 'الفاتحة', 'verses_count': 7},
        {'id': 112, 'name_arabic': 'الإخلاص', 'verses_count': 2},
      ],
    });

String cloudChapters() => jsonEncode({
      'data': [
        {'number': 112, 'name': 'سُورَةُ الإِخۡلَاصِ', 'numberOfAyahs': 2},
      ],
    });

String cloudSurah(List<String> ayahs) => jsonEncode({
      'data': {
        'ayahs': [for (var i = 0; i < ayahs.length; i++) {'numberInSurah': i + 1, 'text': ayahs[i]}],
      },
    });

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('quran'));
  tearDown(() => tmp.deleteSync(recursive: true));

  QuranRepository repo(MockClient c) => QuranRepository(client: c, cacheFile: () async => File('${tmp.path}/q.json'));

  /// المصدرين بالترتيب — لاختبار الرجوع للمصدر التاني (التطبيق نفسه بيخزّن من AlQuran Cloud بس).
  QuranRepository both(MockClient c) =>
      QuranRepository(client: c, cacheFile: () async => File('${tmp.path}/q.json'), sources: QuranConfig.checkSources);

  /// AlQuran Cloud بشكل ردوده: قايمة السور، والفاتحة للبسملة، والإخلاص.
  http.Response cloudReply(http.Request r) {
    if (r.url.path == '/v1/surah') return ok(cloudChapters());
    if (r.url.path.contains('/surah/1/')) return ok(cloudSurah([basmala]));
    return ok(cloudSurah(['${basmala.substring(1)} $a1', a2]));
  }

  MockClient cloud() => MockClient((r) async => cloudReply(r));

  test('stripBasmala removes the basmala words and keeps the rest byte-exact', () {
    expect(stripBasmala('${basmala.substring(1)} $a1', basmala), a1);
    // alquran.cloud بيكتب "بِّسْمِ" بشدّة في بعض السور — الهيكل واحد
    expect(stripBasmala('بِّسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ $a1', basmala), a1);
    expect(stripBasmala(a1, basmala), a1, reason: 'no basmala → untouched');
  });

  test('the app stores text from AlQuran Cloud only — Quran.com terms forbid keeping it', () async {
    final hosts = <String>{};
    final c = MockClient((r) async {
      hosts.add(r.url.host);
      return cloudReply(r);
    });
    final r = repo(c);
    expect((await r.surah(112)).map((a) => a.text), [a1, a2]);
    expect(hosts, {'api.alquran.cloud'});
    expect(r.sourceLabel(112), contains('AlQuran Cloud'));
    expect((await repo(MockClient((_) async => throw const SocketException('offline'))).surah(112)).first.text, a1);
  });

  test('the check screen compares both sources without caching', () async {
    final c = MockClient((r) async {
      if (r.url.host == 'api.quran.com') {
        return ok(jsonEncode({
          'verses': [
            {'verse_key': '112:1', 'text_uthmani': a1},
            {'verse_key': '112:2', 'text_uthmani': a2},
          ],
        }));
      }
      return cloudReply(r);
    });
    final all = await repo(c).fetchAll(112);
    expect(all.length, 2);
    for (final ayahs in all.values) {
      expect(ayahs.map((a) => a.text), [a1, a2]);
    }
    expect(File('${tmp.path}/q.json').existsSync(), isFalse);
  });

  test('tries sources in order, trims the leading space, and caches to disk', () async {
    var calls = 0;
    final c = MockClient((r) async {
      calls++;
      if (r.url.path.endsWith('/chapters')) return ok(quranComChapters());
      return ok(jsonEncode({
        'verses': [
          {'verse_key': '112:1', 'text_uthmani': ' $a1'},
          {'verse_key': '112:2', 'text_uthmani': a2},
        ],
      }));
    });
    final ayahs = await both(c).surah(112);
    expect(ayahs.map((a) => a.text), [a1, a2]);
    expect(calls, 2);

    // نسخة جديدة من الريبو بتقرا من الملف من غير شبكة
    final offline = repo(MockClient((_) async => throw const SocketException('offline')));
    expect((await offline.surah(112)).first.text, a1);
    expect(offline.cached(112), isTrue);
  });

  test('falls back to alquran.cloud and strips the basmala from ayah 1', () async {
    final c = MockClient((r) async {
      if (r.url.host == 'api.quran.com') return http.Response('down', 503);
      if (r.url.path.endsWith('/surah')) return ok(cloudChapters());
      if (r.url.path.contains('/surah/1/')) return ok(cloudSurah([basmala]));
      return ok(cloudSurah(['${basmala.substring(1)} $a1', a2]));
    });
    final r = both(c);
    final ayahs = await r.surah(112);
    expect(ayahs.first.text, a1);
    expect(r.sourceLabel(112), contains('AlQuran Cloud'));
  });

  test('rejects a source whose ayah count does not match the chapter list', () async {
    final c = MockClient((r) async {
      if (r.url.path.endsWith('/chapters')) return ok(quranComChapters());
      if (r.url.host == 'api.quran.com') {
        return ok(jsonEncode({'verses': [{'verse_key': '112:1', 'text_uthmani': a1}]}));
      }
      return http.Response('down', 503);
    });
    expect(both(c).surah(112), throwsA(isA<QuranException>()));
  });

  group('offline and damaged cache', () {
    MockClient online() => cloud();
    MockClient offline() => MockClient((_) async => throw const SocketException('offline'));

    test('a corrupt cache file is replaced by a fresh fetch', () async {
      File('${tmp.path}/q.json').writeAsStringSync('{"v": 2, "surahs": [broken');
      expect((await repo(online()).surah(112)).map((a) => a.text), [a1, a2]);
      // الملف اتكتب من جديد سليم ويشتغل من غير نت
      expect((await repo(offline()).surah(112)).first.text, a1);
    });

    test('a cache from another cache version is ignored, not trusted', () async {
      File('${tmp.path}/q.json').writeAsStringSync(jsonEncode({
        'v': -1,
        'chapters': null,
        'surahs': {'112': [{'number': 1, 'text': 'نص قديم'}, {'number': 2, 'text': 'نص قديم'}]},
        'sources': {},
      }));
      expect(repo(offline()).surah(112), throwsA(isA<QuranException>()));
    });

    test('offline with nothing cached fails clearly after trying every source', () async {
      final hosts = <String>{};
      final c = MockClient((r) async {
        hosts.add(r.url.host);
        throw const SocketException('offline');
      });
      await expectLater(both(c).surah(112), throwsA(isA<QuranException>()));
      expect(hosts, {'api.quran.com', 'api.alquran.cloud'});
    });

    test('a chapter list saved for an older range is refreshed, or kept when offline', () async {
      Map<String, dynamic> older() => {
            'v': QuranConfig.cacheVersion,
            'chapters': [const QuranChapter(67, 'الملك', 30).toJson()],
            'surahs': {'112': [{'number': 1, 'text': a1}, {'number': 2, 'text': a2}]},
            'sources': {},
          };
      File('${tmp.path}/q.json').writeAsStringSync(jsonEncode(older()));
      expect((await repo(offline()).chapters()).map((c) => c.number), [67], reason: 'offline keeps the old list');

      final fresh = repo(online());
      expect((await fresh.chapters()).map((c) => c.number), [112]);
      expect((await fresh.surah(112)).first.text, a1, reason: 'saved text is kept');
      expect((await repo(offline()).chapters()).map((c) => c.number), [112], reason: 'the new list is saved');
    });

    test('an unwritable cache still returns the text for this session', () async {
      final blocked = Directory('${tmp.path}/q.json')..createSync(); // مكان الملف فولدر — الكتابة هتفشل
      final r = QuranRepository(client: online(), cacheFile: () async => File(blocked.path));
      expect((await r.surah(112)).first.text, a1);
      expect(r.cached(112), isTrue);
    });
  });

  group('single ayah download', () {
    late File file;
    final url = Uri.parse('https://example.test/112001.mp3');
    setUp(() => file = File('${tmp.path}/rec/112001.mp3'));

    Future<bool> fetch(http.Response Function() respond) =>
        RecitationPlayer.download(url, file, client: MockClient((_) async => respond()));

    test('an error page served with 200 is not saved as audio', () async {
      expect(await fetch(() => http.Response('<html>blocked</html>', 200, headers: {'content-type': 'text/html'})), isFalse);
      expect(file.existsSync(), isFalse);
    });

    test('a missing file or empty body is a failure', () async {
      expect(await fetch(() => http.Response('', 404)), isFalse);
      expect(await fetch(() => http.Response.bytes([], 200, headers: {'content-type': 'audio/mpeg'})), isFalse);
      expect(file.existsSync(), isFalse);
    });

    test('a dropped connection leaves nothing behind and a retry succeeds', () async {
      final failing = MockClient((_) async => throw const SocketException('reset'));
      expect(await RecitationPlayer.download(url, file, client: failing), isFalse);
      expect(file.existsSync(), isFalse);
      expect(await fetch(() => http.Response.bytes(mp3, 200, headers: {'content-type': 'audio/mpeg'})), isTrue);
      expect(file.readAsBytesSync(), mp3);
    });
  });
}

/// http.Response(String) بيستخدم latin1 — النص العربي لازم يتبعت UTF-8.
/// أصغر ملف شكله MP3: وسم ID3 وبعده بيانات.
final mp3 = [0x49, 0x44, 0x33, ...List.filled(300, 0)];

http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);
