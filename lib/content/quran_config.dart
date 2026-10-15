/// إعدادات عالم القرآن — منقولة من js/config.js.
///
/// مفيش أي نص قرآني مكتوب داخل الكود: النص بيتجاب من المصدر الموثوق وقت
/// التشغيل ويتخزّن على الجهاز. لتغيير المصدر أو القارئ غيّر القيم هنا بس.
library;

/// إشعار حقوق نص Tanzil — بيظهر في صفحة التراخيص (شرط رخصة CC BY 3.0).
const tanzilNotice = 'Tanzil Quran Text\n'
    'Copyright (C) 2007-2021 Tanzil Project\n'
    'License: Creative Commons Attribution 3.0\n\n'
    'This copy of the Quran text is carefully produced, highly verified and continuously monitored by a group of '
    'specialists in Tanzil Project.\n\n'
    'TERMS OF USE:\n\n'
    '- Permission is granted to copy and distribute verbatim copies of this text, but CHANGING IT IS NOT ALLOWED.\n\n'
    '- This Quran text can be used in any website or application, provided that its source (Tanzil Project) is '
    'clearly indicated, and a link is made to tanzil.net to enable users to keep track of changes.\n\n'
    '- This copyright notice shall be included in all verbatim copies of the text, and shall be reproduced '
    'appropriately in all files derived from or containing substantial portion of this text.\n\n'
    'Please check updates at: http://tanzil.net/updates/\n\n'
    'Delivered to this app through AlQuran Cloud (alquran.cloud).';

class QuranChapter {
  const QuranChapter(this.number, this.name, this.ayahs);
  final int number;
  final String name;
  final int ayahs;

  Map<String, dynamic> toJson() => {'number': number, 'name': name, 'ayahs': ayahs};
  factory QuranChapter.fromJson(Map<String, dynamic> j) =>
      QuranChapter((j['number'] as num).toInt(), j['name'] as String, (j['ayahs'] as num).toInt());
}

class Ayah {
  const Ayah(this.number, this.text);
  final int number;

  /// النص كما ورد من المصدر بالظبط (بعد شيل المسافات من الأطراف بس).
  final String text;

  Map<String, dynamic> toJson() => {'number': number, 'text': text};
  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah((j['number'] as num).toInt(), j['text'] as String);
}

class TextSource {
  const TextSource({
    required this.id,
    required this.label,
    required this.chaptersUrl,
    required this.versesUrl,
    required this.parseChapters,
    required this.parseVerses,
    this.basmalaInFirstAyah = false,
  });
  final String id;
  final String label;
  final String chaptersUrl;
  final String Function(int surah) versesUrl;
  final List<QuranChapter> Function(Map<String, dynamic> json) parseChapters;
  final List<Ayah> Function(Map<String, dynamic> json) parseVerses;

  /// المصدر بيحط البسملة في أول آية من كل سورة (غير الفاتحة والتوبة) — لازم تتشال.
  final bool basmalaInFirstAyah;
}

class Reciter {
  const Reciter(this.id, this.label, this.folder, {this.teacher = false});
  final String id;
  final String label;
  final String folder;

  /// نسخ "المعلّم": الشيخ بيقرأ والأطفال بيرددوا وراه — الأنسب لتعليم الترديد.
  final bool teacher;
}

List<Map<String, dynamic>> _list(Object? o) => [for (final e in (o as List? ?? const [])) (e as Map).cast<String, dynamic>()];

/// النص بيتعرض كما هو؛ اللي بيتشال بس المسافات والـ BOM من الأطراف.
String _clean(Object? t) => '$t'.replaceAll('﻿', '').trim();

abstract final class QuranConfig {
  /// نطاق السور المعروضة — جزء تبارك (٦٧) + جزء عمّ (٧٨) إلى الناس (١١٤).
  static const from = 67, to = 114;

  /// ترتيب العرض: من الناس للأصغر — السور القصيرة الأول (ترتيب الحفظ المعتاد).
  static const descending = true;

  /// اسم الجزء حسب رقم السورة — بيظهر كعنوان فاصل في قائمة السور.
  static String juzOf(int n) => n >= 78 ? 'جزء عمّ' : 'جزء تبارك';
  static const rangeTitle = 'جزء عمّ وتبارك';

  /// AlQuran Cloud: شروطه بتسمح بتخزين النص وعرضه في التطبيقات (مع ذكر المصدر)، فهو اللي بيتخزّن.
  static final cloud = TextSource(
    id: 'alquran.cloud',
    label: 'AlQuran Cloud — النص العثماني (مشروع تنزيل)',
    chaptersUrl: 'https://api.alquran.cloud/v1/surah',
    versesUrl: (n) => 'https://api.alquran.cloud/v1/surah/$n/quran-uthmani',
    parseChapters: (j) => [
      for (final c in _list(j['data']))
        QuranChapter((c['number'] as num).toInt(), c['name'] as String, (c['numberOfAyahs'] as num).toInt()),
    ],
    parseVerses: (j) => [
      for (final a in _list((j['data'] as Map?)?['ayahs']))
        Ayah((a['numberInSurah'] as num).toInt(), _clean(a['text'])),
    ],
    basmalaInFirstAyah: true,
  );

  /// Quran.com (Quran Foundation): شروطه بتمنع تخزين النص أكتر من أسبوع من غير Content Sync —
  /// بنستخدمه بس في شاشة التحقق (بيتعرض ومابيتخزّنش).
  static final quranCom = TextSource(
    id: 'quran.com',
    label: 'Quran.com API v4 — النص العثماني (مجمع الملك فهد)',
    chaptersUrl: 'https://api.quran.com/api/v4/chapters?language=ar',
    versesUrl: (n) => 'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$n',
    parseChapters: (j) => [
      for (final c in _list(j['chapters']))
        QuranChapter((c['id'] as num).toInt(), c['name_arabic'] as String, (c['verses_count'] as num).toInt()),
    ],
    parseVerses: (j) => [
      for (final v in _list(j['verses']))
        Ayah(int.parse('${v['verse_key']}'.split(':')[1]), _clean(v['text_uthmani'])),
    ],
  );

  /// المصادر اللي النص بيتجاب منها ويتخزّن على الجهاز.
  static final sources = <TextSource>[cloud];

  /// شاشة التحقق بتقارن المصدرين حرف بحرف — من غير تخزين.
  static final checkSources = <TextSource>[quranCom, cloud];

  /// تلاوات مرتّلة معروفة ومعتمدة فقط.
  static const reciters = <Reciter>[
    Reciter('husary', 'الشيخ محمود خليل الحصري', 'Husary_128kbps'),
    Reciter('abdulbasit', 'الشيخ عبد الباسط عبد الصمد (مرتّل)', 'Abdul_Basit_Murattal_192kbps'),
    Reciter('minshawy', 'الشيخ محمد صديق المنشاوي (مرتّل)', 'Minshawy_Murattal_128kbps'),
    Reciter('minshawy_teacher', 'المنشاوي — المعلّم (مع ترديد الأطفال)', 'Minshawy_Teacher_128kbps', teacher: true),
    Reciter('husary_muallim', 'الحصري — المعلّم (مع الترديد)', 'Husary_Muallim_128kbps', teacher: true),
  ];

  static const defaultReciter = 'husary';

  /// القارئ المستخدم في وضع الترديد تحديدًا.
  static const defaultRepeatReciter = 'minshawy_teacher';

  static Reciter reciter(String id) => reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);

  /// رابط تلاوة آية واحدة — الصيغة القياسية لموقع everyayah.
  static Uri ayahAudioUrl(String folder, int surah, int ayah) => Uri.parse(
      'https://everyayah.com/data/$folder/${'$surah'.padLeft(3, '0')}${'$ayah'.padLeft(3, '0')}.mp3');

  /// غيّرها لو عايز تمسح الكاش وتعيد التحميل من المصدر.
  static const cacheVersion = 3;
}
