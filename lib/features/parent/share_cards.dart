/// صور تتشارك على واتساب من لوحة ولي الأمر: تقرير الأسبوع وشهادات الحفظ والمسارات.
/// صورة مش PDF: بتظهر جوه الشات على طول. ولي الأمر بيشوف الصورة قبل ما يشاركها.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../content/quran_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/toast.dart';
import '../../domain/certificates.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../daily/week_card.dart' show weekNotes;
import '../profiles/profiles.dart' show childName;
import '../quran/quran_repository.dart';
import 'dashboard_screen.dart' show fmtTime, skillLabel;

/// عرض الصورة بالنقط المنطقية — بتتصدّر ×٣ (١٠٨٠ بكسل).
const shareWidth = 360.0;

/// "٢٣ أكتوبر ٢٠٢٦".
String fmtLongDate(DateTime d) {
  const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  return ar('${d.day} ${months[d.month - 1]} ${d.year}');
}

/// أسماء السور من الكاش — نفس اللي اللوحة بتعرضه.
Map<int, String> surahNamesOf(WidgetRef ref) =>
    {for (final c in ref.watch(quranChaptersProvider).value ?? const <QuranChapter>[]) c.number: c.name};

/// يعرض الصورة ومعاها زرار المشاركة.
Future<void> showSharePreview(BuildContext context, {required Widget card, required String fileName, required String subject}) =>
    showDialog(
      context: context,
      builder: (_) => SharePreview(pages: [card], width: shareWidth, fileName: fileName, subject: subject),
    );

/// معاينة صورة أو أكتر وزرار المشاركة. [pdf] = الصفحات بتتجمع في ملف PDF (ورقة العمل)،
/// وإلا أول صورة بتتشارك PNG.
class SharePreview extends StatefulWidget {
  const SharePreview({
    super.key,
    required this.pages,
    required this.width,
    required this.fileName,
    required this.subject,
    this.pdf,
    this.note,
  });
  final List<Widget> pages;
  final double width;
  final String fileName, subject;

  /// بيحوّل صور الصفحات (PNG) لملف PDF.
  final Future<List<int>> Function(List<List<int>> pngs)? pdf;

  /// سطر فوق المعاينة.
  final String? note;

  @override
  State<SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<SharePreview> {
  late final _keys = [for (final _ in widget.pages) GlobalKey()];
  var _busy = false;

  Future<List<int>> _png(GlobalKey key) async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: widget.pdf != null ? 2.5 : 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final dir = (await getTemporaryDirectory()).path;
      final XFile out;
      if (widget.pdf case final toPdf?) {
        final file = File('$dir/${widget.fileName}.pdf');
        await file.writeAsBytes(await toPdf([for (final k in _keys) await _png(k)]), flush: true);
        out = XFile(file.path, mimeType: 'application/pdf');
      } else {
        final file = File('$dir/${widget.fileName}.png');
        await file.writeAsBytes(await _png(_keys.first), flush: true);
        out = XFile(file.path, mimeType: 'image/png');
      }
      await SharePlus.instance.share(ShareParams(files: [out], subject: widget.subject, sharePositionOrigin: origin));
    } catch (_) {
      if (mounted) {
        showToast(context, 'مقدرناش نعمل الملف — جرّب تاني', kind: ToastKind.error);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.note case final note?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(note, textAlign: TextAlign.center, style: kidText(14, weight: FontWeight.w600, color: AppColors.inkSoft)),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(children: [
                  for (var i = 0; i < widget.pages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FittedBox(
                        child: RepaintBoundary(key: _keys[i], child: SizedBox(width: widget.width, child: widget.pages[i])),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 8, children: [
              KidButton(_busy ? 'لحظة…' : (widget.pdf != null ? '🖨️ اطبع أو شارك' : '📤 شارك'), onTap: _busy ? null : _share),
              KidButton('إغلاق', kind: BtnKind.ghost, onTap: () => context.pop()),
            ]),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- الصور

/// إطار مشترك: لوجو رحلتي فوق وسطر تحت.
class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.border = AppColors.sky1, this.bg = AppColors.paper});
  final Widget child;
  final Color border, bg;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 6),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Text('🧭', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text('رحلتي', style: kidText(22, color: AppColors.grape)),
            ]),
            const SizedBox(height: 8),
            child,
            const SizedBox(height: 12),
            Text('من تطبيق رحلتي — بيانات الطفل على الجهاز بس',
                textAlign: TextAlign.center, style: kidText(11, weight: FontWeight.w600, color: AppColors.inkSoft)),
          ]),
        ),
      );
}

/// تقرير آخر ٧ أيام في صورة واحدة — بالكلام اللي ولي الأمر يفهمه من غير ما يفتح التطبيق.
class WeekReportImage extends StatelessWidget {
  const WeekReportImage({super.key, required this.p, required this.surahNames, required this.today});
  final ProgressData p;
  final Map<int, String> surahNames;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final w = p.weekSum();
    final total = w.correct + w.wrong;
    final (up, need) = weekNotes(p);
    final weak = p.weakest(3);
    final memorized = memorizedSurahs(p);
    final from = DateTime(today.year, today.month, today.day - 6);

    Widget stat(String value, String label) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              FittedBox(child: Text(value, style: kidText(20, height: 1.2))),
              Text(label, style: kidText(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ]),
          ),
        );
    Widget note(String text, Color bg, Color fg) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Text(text, style: kidText(13, weight: FontWeight.w700, color: fg, height: 1.6)),
        );

    return _Frame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('📅 تقرير ${childName(p)} الأسبوعي', style: kidText(19)),
        Text('من ${fmtLongDate(from)} لـ ${fmtLongDate(today)}',
            style: kidText(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
        const SizedBox(height: 10),
        Row(children: [
          stat(ar(w.stars), 'نجمة'),
          stat(ar(w.games), 'لعبة'),
          stat(ar(w.days), 'أيام نشاط'),
          stat(total == 0 ? '—' : '${ar((w.correct / total * 100).round())}٪', 'دقة'),
        ]),
        const SizedBox(height: 6),
        Text('⏱️ وقت التعلّم: ${fmtTime(w.ms)}', style: kidText(13)),
        note('✅ اتحسّن: ${up.isEmpty ? 'الأسبوع ماشي زي اللي قبله' : up.join(' • ')}', AppColors.okBg, AppColors.okInk),
        note('💡 محتاج: ${need.isEmpty ? 'مفيش حاجة واضحة — كمّلوا كده' : need.join(' • ')}', AppColors.noteBg, AppColors.noteInk),
        if (weak.isNotEmpty)
          note(
            '🧠 بيتدرّب على: ${[
              for (final s in weak) '${packs[s.pack]?.name ?? s.pack} (${skillLabel(s.skill)})',
            ].join('، ')}',
            AppColors.paper2,
            AppColors.ink,
          ),
        if (memorized.isNotEmpty)
          note(
            '📖 حفظ ${countOf(memorized.length, surahWord)}: ${memorized.take(6).map((s) => surahTitle(s, surahNames[s])).join('، ')}'
            '${memorized.length > 6 ? ' …' : ''}',
            const Color(0xFFDDF6F1),
            const Color(0xFF04332C),
          ),
      ]),
    );
  }
}

/// شهادة تتطبع أو تتشارك: اسم الطفل والإنجاز وتاريخ إصدارها.
class CertificateImage extends StatelessWidget {
  const CertificateImage({super.key, required this.name, required this.cert, required this.date});
  final String name;
  final Certificate cert;
  final DateTime date;

  @override
  Widget build(BuildContext context) => _Frame(
        border: AppColors.gold,
        bg: const Color(0xFFFFFBEF),
        child: Column(children: [
          const Text('🏅', style: TextStyle(fontSize: 56)),
          Text('شهادة تقدير', style: kidText(28, color: AppColors.goldDark)),
          const SizedBox(height: 10),
          Text('البطل', style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          Text(name, textAlign: TextAlign.center, style: kidText(32, color: AppColors.grape, height: 1.3)),
          const SizedBox(height: 10),
          Text('${cert.icon} ${cert.title}', textAlign: TextAlign.center, style: kidText(21, height: 1.4)),
          const SizedBox(height: 6),
          Text('ما شاء الله! كمّل يا بطل 🌟', style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          Text(fmtLongDate(date), style: kidText(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
        ]),
      );
}

// ---------------------------------------------------------------- في اللوحة

/// زرار مشاركة تقرير الأسبوع (فوق كارت التقرير).
class ShareWeekButton extends ConsumerWidget {
  const ShareWeekButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final names = surahNamesOf(ref);
    final now = ProgressData.clock();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => showSharePreview(
          context,
          card: WeekReportImage(p: p, surahNames: names, today: now),
          fileName: 'rehlati-week-${ProgressData.dayKey(now)}',
          subject: 'تقرير ${childName(p)} الأسبوعي',
        ),
        icon: const Text('📤', style: TextStyle(fontSize: 18)),
        label: Text('شارك التقرير على واتساب', style: kidText(15, color: AppColors.grape)),
      ),
    );
  }
}

/// الشهادات المستحقة — كل واحدة بتتفتح صورة تتشارك.
class CertificatesCard extends ConsumerWidget {
  const CertificatesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final certs = certificates(p, surahNamesOf(ref));
    if (certs.isEmpty) {
      return NoteBox(Text('لما ${childName(p)} يحفظ سورة أو يخلّص مسار تعلّم، شهادته هتظهر هنا وتقدر تشاركها.'));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final c in certs)
        ActionChip(
          avatar: Text(c.icon),
          label: Text(c.title, style: kidText(14)),
          backgroundColor: const Color(0xFFFFF4D6),
          onPressed: () => showSharePreview(
            context,
            card: CertificateImage(name: childName(p), cert: c, date: ProgressData.clock()),
            fileName: 'rehlati-${c.id.replaceAll(':', '-')}',
            subject: 'شهادة ${childName(p)}',
          ),
        ),
    ]);
  }
}
