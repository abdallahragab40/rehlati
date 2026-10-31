/// ورقة عمل تتطبع من لوحة ولي الأمر: صفحة A4 لكل مرحلة محتاجة تدريب، بنفس رسومات الأسئلة،
/// ومفتاح الإجابات تحت لولي الأمر. بتتشارك PDF (من قايمة المشاركة: طباعة، واتساب، ملفات).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/toast.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/question.dart';
import '../../domain/worksheet.dart';
import '../game/visuals.dart';
import '../profiles/profiles.dart' show childName;
import 'share_cards.dart';

/// صفحة A4 بالنقط (٥٩٥ × ٨٤٢).
const _pageSize = Size(595, 842);

/// يجمع صور الصفحات في PDF مقاس A4 — صفحة لكل صورة.
Future<List<int>> pagesToPdf(List<List<int>> pngs) async {
  final doc = pw.Document(title: 'ورقة عمل رحلتي', creator: 'رحلتي');
  for (final png in pngs) {
    final img = pw.MemoryImage(Uint8List.fromList(png));
    doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero, build: (_) => pw.Image(img, fit: pw.BoxFit.contain)));
  }
  return doc.save();
}

class WorksheetCard extends ConsumerWidget {
  const WorksheetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      NoteBox(Text('ورقة أسئلة على المهارات اللي ${childName(p)} محتاج يتدرّب عليها — تتطبع ويحلّها بالقلم. '
          'كل مرة بتطلع أسئلة جديدة، والإجابات تحت كل صفحة.')),
      const SizedBox(height: 8),
      Center(
        child: KidButton('📝 اعمل ورقة عمل', kind: BtnKind.ghost, onTap: () {
          final now = ProgressData.clock();
          final sheet = buildWorksheet(p, Rng());
          if (sheet.isEmpty) {
            showToast(context, 'العب كام مرحلة الأول — الورقة بتتعمل من المراحل اللي اتلعبت', kind: ToastKind.warn, icon: '📝');
            return;
          }
          showWorksheet(context, p, sheet, now);
        }),
      ),
    ]);
  }
}

/// معاينة الورقة ومشاركتها PDF — من لوحة ولي الأمر ومن دروس المدرسة.
Future<void> showWorksheet(BuildContext context, ProgressData p, List<WorksheetSection> sheet, DateTime now) => showDialog(
      context: context,
      builder: (_) => SharePreview(
        pages: [
          for (var i = 0; i < sheet.length; i++)
            WorksheetPage(name: childName(p), section: sheet[i], page: i + 1, pages: sheet.length, date: now),
        ],
        width: _pageSize.width,
        fileName: 'rehlati-worksheet-${ProgressData.dayKey(now)}',
        subject: 'ورقة عمل ${childName(p)}',
        pdf: pagesToPdf,
        note: countOf(sheet.length, (one: 'صفحة واحدة', two: 'صفحتين', few: 'صفحات', many: 'صفحة')),
      ),
    );

/// صفحة واحدة: عنوان، ٨ أسئلة في عمودين، ومفتاح الإجابات.
class WorksheetPage extends StatelessWidget {
  const WorksheetPage({super.key, required this.name, required this.section, required this.page, required this.pages, required this.date});
  final String name;
  final WorksheetSection section;
  final int page, pages;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final qs = section.questions;
    final key = [for (var i = 0; i < qs.length; i++) '${ar(i + 1)}) ${answerLetter(qs[i])}'].join('   ');
    // الرسومات بتتحسب على عرض الصفحة مش عرض الموبايل
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(size: _pageSize, textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: _pageSize.width,
          height: _pageSize.height,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('🧭 رحلتي', style: kidText(18, color: AppColors.grape)),
              const Spacer(),
              Text('${fmtLongDate(date)} • صفحة ${ar(page)} من ${ar(pages)}',
                  style: kidText(11, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ]),
            const SizedBox(height: 4),
            Text('📝 ورقة عمل: $name', style: kidText(22)),
            Text('${section.stage.icon} ${section.stage.name} — حوّط على الإجابة الصح',
                style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 10),
            Expanded(
              child: Column(children: [
                for (var row = 0; row < worksheetPerSection ~/ 2; row++)
                  Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final i in [row * 2, row * 2 + 1])
                        Expanded(child: i < qs.length ? _Cell(n: i + 1, q: qs[i]) : const SizedBox()),
                    ]),
                  ),
              ]),
            ),
            const Divider(color: AppColors.line),
            Text('للأهل — الإجابات: $key', style: kidText(10, weight: FontWeight.w600, color: AppColors.inkSoft)),
          ]),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.n, required this.q});
  final int n;
  final Question q;

  @override
  Widget build(BuildContext context) {
    final dir = q.ltr ? TextDirection.ltr : TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '${ar(n)}. ', style: kidText(13, color: AppColors.grape)),
            TextSpan(text: q.ask, style: kidText(13)),
          ]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: q.visuals.isEmpty
              ? const SizedBox()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: FittedBox(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      for (final v in q.visuals) VisualView(v, ltr: q.ltr),
                    ]),
                  ),
                ),
        ),
        Directionality(
          textDirection: dir,
          child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 4, children: [
            for (var i = 0; i < q.choices.length && i < choiceLetters(q).length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inkSoft, width: 1.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${choiceLetters(q)[i]}) ${ar('${q.choices[i]}')}', style: kidText(13, height: 1.3)),
              ),
          ]),
        ),
      ]),
    );
  }
}
