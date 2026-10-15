/// لوحة ولي الأمر: نسخة احتياطية في ملف (تصدير واسترجاع).
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/backup.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../profiles/profiles.dart';
import 'avatar.dart';

/// يكتب ملف النسخة في فولدر مؤقت ويرجّعه — المشاركة بعد كده بتحفظه في المكان اللي ولي الأمر يختاره.
Future<File> writeBackupFile(Directory dir, List<BackupChild> children, DateTime now) async {
  final f = File('${dir.path}/rehlati-backup-${ProgressData.dayKey(now)}.json');
  await f.writeAsString(Backup.encode(children, at: now), flush: true);
  return f;
}

class BackupCard extends ConsumerWidget {
  const BackupCard({super.key});

  void _say(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final kids = ref.read(childrenProvider);
    final active = ref.read(activeChildProvider);
    var all = kids.length > 1, photos = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('نسخة احتياطية', style: kidText(20)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (kids.length > 1)
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(childName(kids.firstWhere((k) => k.$1 == active).$2))),
                  const ButtonSegment(value: true, label: Text('كل الأطفال')),
                ],
                selected: {all},
                onSelectionChanged: (v) => set(() => all = v.first),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: photos,
              onChanged: (v) => set(() => photos = v ?? false),
              title: const Text('الصورة كمان'),
            ),
            Text('الملف فيه بيانات الطفل (الاسم والتقدّم${photos ? ' والصورة' : ''}) — احفظه في مكان آمن.',
                style: kidText(14, weight: FontWeight.w600, color: AppColors.inkSoft)),
          ]),
          actions: [
            TextButton(onPressed: () => c.pop(false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => c.pop(true), child: const Text('صدّر')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ref.read(progressProvider.notifier).flush();
      final chosen = [for (final k in kids) if (all || k.$1 == active) k];
      final file = await writeBackupFile(await getTemporaryDirectory(), [
        for (final (id, p) in chosen) BackupChild(p, photo: photos ? AvatarController.readPhoto(id) : null),
      ], DateTime.now());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'نسخة رحلتي',
        sharePositionOrigin: origin,
      ));
    } catch (_) {
      if (context.mounted) _say(context, 'مقدرناش نعمل الملف — جرّب تاني');
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final List<BackupChild> children;
    try {
      final picked = await openFile(acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json'], mimeTypes: ['application/json'], uniformTypeIdentifiers: ['public.json']),
      ]);
      if (picked == null) return;
      // الحجم الأول — ملف ضخم مايتقراش كله في الذاكرة
      if (await picked.length() > Backup.maxBytes) throw BackupException('الملف كبير قوي — ده مش ملف نسخة احتياطية من رحلتي');
      children = await _checkPhotos(Backup.decode(await picked.readAsString()));
    } on BackupException catch (e) {
      if (context.mounted) _say(context, e.message);
      return;
    } catch (_) {
      if (context.mounted) _say(context, 'مقدرناش نقرا الملف');
      return;
    }
    if (!context.mounted) return;
    final current = childName(ref.read(progressProvider));
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('استرجاع نسخة', style: kidText(20)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final k in children)
            Text('🧒 ${childName(k.progress)}${k.progress.age != null ? ' • ${ar(k.progress.age)} سنين' : ''} • ⭐ ${ar(k.progress.stars)}'
                '${k.photo != null ? ' • 📷' : ''}', style: kidText(16)),
          const SizedBox(height: 8),
          Text('هيتضافوا كأطفال جداد — الأطفال اللي على الجهاز مش هيتغيّروا.',
              style: kidText(14, weight: FontWeight.w600, color: AppColors.inkSoft)),
        ]),
        actions: [
          TextButton(onPressed: () => c.pop(), child: const Text('إلغاء')),
          if (children.length == 1)
            TextButton(onPressed: () => c.pop('replace'), child: Text('استبدل تقدّم $current', style: const TextStyle(color: AppColors.coral))),
          FilledButton(onPressed: () => c.pop('new'), child: const Text('ضيفهم')),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'replace') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('تستبدل تقدّم $current؟', style: kidText(20)),
          content: Text('تقدّمه الحالي هيتبدّل بالنسخة دي.', style: kidText(16, weight: FontWeight.w600)),
          actions: [
            TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
            TextButton(onPressed: () => c.pop(true), child: const Text('استبدل', style: TextStyle(color: AppColors.coral))),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
    }
    final n = ref.read(progressProvider.notifier);
    final List<String> ids;
    try {
      ids = choice == 'replace'
          ? [ref.read(activeChildProvider)]
          : await n.importAsNew([for (final k in children) k.progress]);
      if (choice == 'replace') await n.replaceActive(children.single.progress);
    } catch (_) {
      if (context.mounted) _say(context, 'الاسترجاع ماكملش — مفيش حاجة اتغيّرت');
      return;
    }
    // التقدّم اترجع خلاص — لو الصورة بس فشلت نقول كده بالظبط
    var photosOk = true;
    for (final (i, k) in children.indexed) {
      if (k.photo case final photo?) {
        try {
          await AvatarController.writePhoto(ids[i], photo);
        } catch (_) {
          photosOk = false;
        }
      }
    }
    ref.invalidate(avatarProvider);
    if (context.mounted) _say(context, photosOk ? '✅ النسخة اترجعت' : '✅ التقدّم اترجع، بس الصورة ماتحفظتش');
  }

  /// كل صورة في النسخة لازم تبقى صورة فعلًا — بتتعمل من جديد قبل أي تعديل، والملف كله بيترفض لو واحدة بايظة.
  static Future<List<BackupChild>> _checkPhotos(List<BackupChild> children) async => [
        for (final (i, c) in children.indexed)
          if (c.photo == null)
            c
          else
            BackupChild(
              c.progress,
              photo: await compute(normalizePhoto, Uint8List.fromList(c.photo!)) ??
                  (throw BackupException('صورة الطفل رقم ${i + 1} مش سليمة')),
            ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('احفظ تقدّم الأطفال في ملف (على الجهاز أو Drive أو ابعته لنفسك) ورجّعه على أي جهاز. '
            'التلاوات المتنزّلة والتذكير مش جوه الملف.', style: kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 4, children: [
          KidButton('📤 صدّر نسخة', kind: BtnKind.ghost, onTap: () => _export(context, ref)),
          KidButton('📥 استرجع نسخة', kind: BtnKind.ghost, onTap: () => _import(context, ref)),
        ]),
      ]);
}
