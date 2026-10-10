/// نسخة احتياطية محلية يتحكم فيها ولي الأمر: ملف JSON فيه تقدّم طفل أو أكتر (والصورة لو اختار).
///
/// مابيدخلش فيها: تلاوات القرآن المتنزّلة (بتتنزّل تاني)، ولا التذكير وإذن الإشعارات
/// (إعدادات الجهاز نفسه). الاسترجاع بيضيف أطفال جداد افتراضيًا — الاستبدال اختيار صريح.
library;

import 'dart:convert';

import 'progress_controller.dart';
import 'progress_data.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// طفل في النسخة: تقدّمه (بعد الترقية لنسخة التطبيق) وصورته لو موجودة.
class BackupChild {
  BackupChild(this.progress, {this.photo});
  final ProgressData progress;
  final List<int>? photo;
}

abstract final class Backup {
  static const format = 'rehlati-backup';
  static const version = 1;

  /// أكبر ملف بنقبله (الصور مصغّرة ٢٥٦ بكسل — ده كفاية جدًا).
  static const maxBytes = 5 * 1024 * 1024;

  static String encode(List<BackupChild> children, {required DateTime at}) => jsonEncode({
        'format': format,
        'version': version,
        'exportedAt': at.toIso8601String(),
        'children': [
          for (final c in children)
            {
              'progress': c.progress.toJson(),
              if (c.photo != null) 'photo': base64Encode(c.photo!),
            },
        ],
      });

  /// بيتأكد من كل حاجة قبل أي تعديل: الشكل، النسخة، وكل ملف تقدّم بيتقري ويترقّى.
  /// ملف من نسخة تطبيق أحدث بيترفض بدل ما يتقري ناقص.
  static List<BackupChild> decode(String raw) {
    if (raw.length > maxBytes) throw BackupException('الملف كبير قوي — ده مش ملف نسخة احتياطية من رحلتي');
    final Object? j;
    try {
      j = jsonDecode(raw);
    } catch (_) {
      throw BackupException('الملف ده مش ملف نسخة احتياطية من رحلتي');
    }
    if (j is! Map || j['format'] != format) throw BackupException('الملف ده مش ملف نسخة احتياطية من رحلتي');
    final v = j['version'];
    if (v is! int || v > version) throw BackupException('النسخة دي من تطبيق أحدث — حدّث التطبيق الأول');
    final list = j['children'];
    if (list is! List || list.isEmpty) throw BackupException('الملف مفيهوش أطفال');
    return [
      for (final (i, c) in list.indexed) _child(c, i + 1),
    ];
  }

  static BackupChild _child(Object? c, int n) {
    if (c is! Map || c['progress'] is! Map) throw BackupException('بيانات الطفل رقم $n ناقصة');
    final ({ProgressData data, bool newer}) d;
    try {
      d = ProgressRepository.decode(jsonEncode(c['progress']));
    } catch (_) {
      throw BackupException('بيانات الطفل رقم $n مش سليمة');
    }
    if (d.newer) throw BackupException('النسخة دي من تطبيق أحدث — حدّث التطبيق الأول');
    List<int>? photo;
    if (c['photo'] != null) {
      try {
        photo = base64Decode(c['photo'] as String);
      } catch (_) {
        throw BackupException('صورة الطفل رقم $n مش سليمة');
      }
    }
    return BackupChild(d.data, photo: photo);
  }
}
