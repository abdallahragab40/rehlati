/// جلب النص القرآني وتخزينه — منقول من QuranSource في js/quran.js.
///
/// مبدأ أساسي: النص لا يُكتب ولا يُولَّد هنا. بيتجاب من المصدر ويتعرض كما هو؛
/// التعديل الوحيد هو شيل البسملة من أول آية لو المصدر حاططها جوه الآية
/// (بنقص الكلمات من أول النص الأصلي — الباقي بيفضل حرف بحرف).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../content/quran_config.dart';

class QuranException implements Exception {
  QuranException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// هيكل الكلمة: الحروف بس من غير تشكيل ولا علامات وقف ولا تطويل — للمقارنة، مش للعرض.
String skeleton(String word) => word.replaceAll(
      RegExp('[ؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۨ-ۭ࣓-ࣿـ﻿]'),
      '',
    );

/// يشيل البسملة من أول الآية لو أول كلماتها نفس هيكل كلمات البسملة.
/// الويب كان بيعرض البسملة جوه الآية الأولى لو المصدر التاني اشتغل.
String stripBasmala(String ayah, String basmala) {
  final b = RegExp(r'\S+').allMatches(basmala).map((m) => skeleton(m[0]!)).toList();
  final words = RegExp(r'\S+').allMatches(ayah).toList();
  if (b.isEmpty || words.length <= b.length) return ayah;
  for (var i = 0; i < b.length; i++) {
    if (skeleton(words[i][0]!) != b[i]) return ayah;
  }
  return ayah.substring(words[b.length - 1].end).trim();
}

class QuranRepository {
  QuranRepository({required this.client, required this.cacheFile, List<TextSource>? sources})
      : sources = sources ?? QuranConfig.sources;

  final http.Client client;
  final Future<File> Function() cacheFile;
  final List<TextSource> sources;

  Map<String, dynamic>? _cache;
  final _basmala = <String, String>{};

  static const _headers = {'User-Agent': 'Rehlati/1.0 (kids learning app)'};

  // ---------------------------------------------------------------- الكاش

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await cacheFile();
      if (f.existsSync()) {
        final j = (jsonDecode(await f.readAsString()) as Map).cast<String, dynamic>();
        if (j['v'] == QuranConfig.cacheVersion) return _cache = j;
      }
    } catch (_) {
      // كاش تالف — نبدأ من جديد
    }
    return _cache = {'v': QuranConfig.cacheVersion, 'chapters': null, 'surahs': <String, dynamic>{}, 'sources': <String, dynamic>{}};
  }

  Future<void> _save() async {
    try {
      await (await cacheFile()).writeAsString(jsonEncode(_cache));
    } catch (_) {}
  }

  bool cached(int surah) => ((_cache?['surahs'] as Map?) ?? const {}).containsKey('$surah');

  /// اسم المصدر اللي جه منه نص السورة دي (أو المصدر الأساسي).
  String sourceLabel([int? surah]) {
    final id = surah == null ? null : (_cache?['sources'] as Map?)?['$surah'];
    return sources.firstWhere((s) => s.id == id, orElse: () => sources.first).label;
  }

  // ---------------------------------------------------------------- الشبكة

  Future<Map<String, dynamic>> _grab(String url) async {
    final r = await client.get(Uri.parse(url), headers: _headers).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw QuranException('HTTP ${r.statusCode}');
    return (jsonDecode(utf8.decode(r.bodyBytes)) as Map).cast<String, dynamic>();
  }

  /// يجرّب المصادر بالترتيب — الأساسي الأول، والتاني لو الأول وقع.
  Future<T> _firstWorking<T>(Future<T> Function(TextSource s) f) async {
    Object? last;
    for (final s in sources) {
      try {
        return await f(s);
      } catch (e) {
        last = e;
      }
    }
    throw QuranException(last is QuranException ? last.message : 'مش قادر أوصل للمصدر: $last');
  }

  /// قائمة السور في النطاق المحدد.
  Future<List<QuranChapter>> chapters() async {
    final c = await _load();
    if (c['chapters'] is List) {
      return [for (final j in c['chapters'] as List) QuranChapter.fromJson((j as Map).cast<String, dynamic>())];
    }
    final list = await _firstWorking((s) async {
      final all = s.parseChapters(await _grab(s.chaptersUrl));
      final inRange = all.where((x) => x.number >= QuranConfig.from && x.number <= QuranConfig.to).toList()
        ..sort((a, b) => a.number - b.number);
      if (inRange.isEmpty) throw QuranException('المصدر رجّع قائمة فاضية');
      return inRange;
    });
    c['chapters'] = [for (final x in list) x.toJson()];
    await _save();
    return list;
  }

  /// آيات سورة واحدة — من الكاش أو من المصدر.
  Future<List<Ayah>> surah(int n) async {
    final c = await _load();
    final surahs = c['surahs'] as Map;
    if (surahs['$n'] is List) {
      return [for (final j in surahs['$n'] as List) Ayah.fromJson((j as Map).cast<String, dynamic>())];
    }
    final expected = (await chapters()).where((x) => x.number == n).firstOrNull?.ayahs;
    final (ayahs, sourceId) = await _firstWorking((s) async {
      var list = s.parseVerses(await _grab(s.versesUrl(n)));
      if (list.isEmpty) throw QuranException('المصدر رجّع آيات فاضية');
      if (expected != null && list.length != expected) {
        throw QuranException('عدد الآيات مش مطابق ($expected / ${list.length})');
      }
      if (s.basmalaInFirstAyah && n != 1 && n != 9) {
        final b = await _basmalaOf(s);
        list = [Ayah(list.first.number, stripBasmala(list.first.text, b)), ...list.skip(1)];
      }
      return (list, s.id);
    });
    surahs['$n'] = [for (final a in ayahs) a.toJson()];
    (c['sources'] as Map)['$n'] = sourceId;
    await _save();
    return ayahs;
  }

  /// البسملة نفسها بتتجاب من نفس المصدر (أول آية في الفاتحة) — مش مكتوبة في الكود.
  Future<String> _basmalaOf(TextSource s) async =>
      _basmala[s.id] ??= s.parseVerses(await _grab(s.versesUrl(1))).first.text;

  /// للتحقق: نص السورة من كل المصادر من غير كاش.
  Future<Map<String, List<Ayah>>> fetchAll(int n) async {
    final out = <String, List<Ayah>>{};
    for (final s in sources) {
      var list = s.parseVerses(await _grab(s.versesUrl(n)));
      if (s.basmalaInFirstAyah && n != 1 && n != 9 && list.isNotEmpty) {
        list = [Ayah(list.first.number, stripBasmala(list.first.text, await _basmalaOf(s))), ...list.skip(1)];
      }
      out[s.label] = list;
    }
    return out;
  }
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return QuranRepository(
    client: client,
    cacheFile: () async => File('${(await getApplicationSupportDirectory()).path}/quran_text_v${QuranConfig.cacheVersion}.json'),
  );
});

final quranChaptersProvider = FutureProvider<List<QuranChapter>>((ref) => ref.watch(quranRepositoryProvider).chapters());

final surahProvider = FutureProvider.family<List<Ayah>, int>((ref, n) => ref.watch(quranRepositoryProvider).surah(n));
