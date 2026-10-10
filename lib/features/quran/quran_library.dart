/// مكتبة القرآن على الجهاز: إيه اللي متنزّل لكل قارئ ولكل جزء، وحجمه، ومسحه.
///
/// التلاوة بتتحسب "على الجهاز" بس لو الملف سليم (شكله MP3) — مجرد وجود الملف مش كفاية.
/// قارئ تاني مابيتحسبش أبدًا: كل قارئ ليه فولدره.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/quran_config.dart';
import 'quran_download.dart';
import 'quran_repository.dart';
import 'recitation.dart';

class JuzStatus {
  JuzStatus(this.juz, {required this.expected, this.present = 0, this.bytes = 0, this.textCached = 0});
  final Juz juz;

  /// عدد آيات الجزء (null = قائمة السور مش متاحة من غير نت).
  final int? expected;

  /// آيات ملفها سليم، وحجمها، وعدد السور اللي نصها محفوظ.
  int present, bytes, textCached;

  int get surahs => juz.$3 - juz.$2 + 1;
  bool get complete => expected != null && expected! > 0 && present >= expected!;
}

class ReciterStatus {
  ReciterStatus(this.reciter, this.juz, {this.damaged = 0});
  final Reciter reciter;
  final List<JuzStatus> juz;

  /// ملفات موجودة بس تالفة — بتتنزّل تاني مع التنزيل الجاي.
  int damaged;

  int get bytes => juz.fold(0, (s, j) => s + j.bytes);
  int get present => juz.fold(0, (s, j) => s + j.present);

  /// متوسط حجم الآية عند القارئ ده — للتقدير قبل التنزيل (≈٩٠ ك.ب لو مفيش ملفات).
  int get bytesPerAyah => present == 0 ? 90 * 1024 : bytes ~/ present;
}

final _name = RegExp(r'^(\d{3})(\d{3})\.mp3$');

/// يمسح فولدر التلاوات من غير نت. [chapters] لعدد آيات كل سورة.
Future<List<ReciterStatus>> scanLibrary({
  required Directory root,
  required List<QuranChapter>? chapters,
  required Future<bool> Function(int surah) textCached,
}) async {
  final ayahs = {for (final c in chapters ?? const <QuranChapter>[]) c.number: c.ayahs};
  final text = <int, bool>{
    for (final (_, from, to) in juzList)
      for (var n = from; n <= to; n++) n: await textCached(n),
  };
  final out = <ReciterStatus>[];
  for (final r in QuranConfig.reciters) {
    final juz = [
      for (final j in juzList)
        JuzStatus(
          j,
          expected: chapters == null ? null : [for (var n = j.$2; n <= j.$3; n++) ayahs[n] ?? 0].fold<int>(0, (a, b) => a + b),
          textCached: [for (var n = j.$2; n <= j.$3; n++) if (text[n] ?? false) n].length,
        ),
    ];
    final status = ReciterStatus(r, juz);
    final dir = Directory('${root.path}/${r.folder}');
    if (dir.existsSync()) {
      for (final f in dir.listSync().whereType<File>()) {
        final m = _name.firstMatch(f.uri.pathSegments.last);
        if (m == null) continue; // .part وغيره
        final surah = int.parse(m[1]!);
        final j = juz.where((x) => surah >= x.juz.$2 && surah <= x.juz.$3).firstOrNull;
        if (j == null) continue;
        if (await RecitationPlayer.isValid(f)) {
          j
            ..present += 1
            ..bytes += f.lengthSync();
        } else {
          status.damaged++;
        }
      }
    }
    out.add(status);
  }
  return out;
}

/// يمسح تلاوة قارئ — كلها أو جزء واحد. التقدّم والحفظ مالهمش دعوة (محفوظين في مكان تاني).
Future<void> deleteAudio(Directory root, Reciter r, {Juz? juz}) async {
  final dir = Directory('${root.path}/${r.folder}');
  if (!dir.existsSync()) return;
  if (juz == null) {
    await dir.delete(recursive: true);
    return;
  }
  for (final f in dir.listSync().whereType<File>()) {
    final m = RegExp(r'^(\d{3})\d{3}\.mp3(\.part)?$').firstMatch(f.uri.pathSegments.last);
    final surah = m == null ? null : int.parse(m[1]!);
    if (surah != null && surah >= juz.$2 && surah <= juz.$3) await f.delete();
  }
}

final quranLibraryProvider = FutureProvider<List<ReciterStatus>>((ref) async {
  final repo = ref.read(quranRepositoryProvider);
  List<QuranChapter>? chapters;
  try {
    chapters = await repo.chapters();
  } catch (_) {
    // من غير نت وأول مرة: الأحجام بتظهر بس من غير "كامل/ناقص"
  }
  return scanLibrary(root: await RecitationPlayer.root(), chapters: chapters, textCached: repo.isCached);
});

/// حجم مقروء: "٤٨ ميجا" أو "٨٠٠ ك.ب".
String fmtBytes(int b, String Function(Object) ar) =>
    b >= 1024 * 1024 ? '${ar((b / (1024 * 1024)).round())} ميجا' : '${ar((b / 1024).round())} ك.ب';
