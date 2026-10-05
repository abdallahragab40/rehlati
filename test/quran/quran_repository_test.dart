import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rehlati/features/quran/quran_repository.dart';

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

  test('stripBasmala removes the basmala words and keeps the rest byte-exact', () {
    expect(stripBasmala('${basmala.substring(1)} $a1', basmala), a1);
    // alquran.cloud بيكتب "بِّسْمِ" بشدّة في بعض السور — الهيكل واحد
    expect(stripBasmala('بِّسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ $a1', basmala), a1);
    expect(stripBasmala(a1, basmala), a1, reason: 'no basmala → untouched');
  });

  test('uses quran.com, trims the leading space, and caches to disk', () async {
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
    final ayahs = await repo(c).surah(112);
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
    final r = repo(c);
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
    expect(repo(c).surah(112), throwsA(isA<QuranException>()));
  });
}

/// http.Response(String) بيستخدم latin1 — النص العربي لازم يتبعت UTF-8.
http.Response ok(String body) => http.Response.bytes(utf8.encode(body), 200);
