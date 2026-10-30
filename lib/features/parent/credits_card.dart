/// لوحة ولي الأمر: مصادر المحتوى والتراخيص — نص فقط، من غير روابط لبره التطبيق (Kids Category).
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kid_widgets.dart';

/// ذكر المصادر مطلوب: Tanzil بيشترط ذكر المشروع وموقعه، و AlQuran Cloud بيطلب ذكر المصدر.
const creditLines = [
  'نص القرآن: النص العثماني من مشروع تنزيل (tanzil.net)، عن طريق AlQuran Cloud (alquran.cloud) — كما هو من غير تعديل.',
  'التلاوات: EveryAyah (everyayah.com) — الحقوق للقرّاء.',
  'التحقق من النص: Quran.com — للمقارنة بس، ومابيتخزّنش على الجهاز.',
  'صوت الأسئلة: Microsoft Azure (Shakir و Ana).',
  'الخطوط: Baloo Bhaijaan 2 و Amiri Quran — رخصة SIL Open Font License 1.1.',
];

class CreditsCard extends StatelessWidget {
  const CreditsCard({super.key});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NoteBox(Text(creditLines.map((l) => '• $l').join('\n'),
            style: kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft))),
        const SizedBox(height: 8),
        Center(
          child: KidButton('📄 التراخيص',
              kind: BtnKind.ghost,
              onTap: () => showLicensePage(context: context, applicationName: 'رحلتي', applicationLegalese: '© 2026 رحلتي')),
        ),
      ]);
}
