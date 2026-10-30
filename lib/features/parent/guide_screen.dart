import 'package:flutter/material.dart';

import '../../content/guide_content.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';

/// نص فيه **كلام عريض**.
TextSpan richGuide(String text, TextStyle style) {
  final parts = text.split('**');
  return TextSpan(style: style, children: [
    for (var i = 0; i < parts.length; i++)
      TextSpan(text: parts[i], style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null),
  ]);
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) => ScreenFrame(
        onBack: () => context.back(),
        title: '📘 إزاي تستخدم التطبيق',
        child: QCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('📘 إزاي تستخدم التطبيق', style: kidText(24)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(14)),
              child: Text(guideLead, style: kidText(15.5, weight: FontWeight.w600, height: 1.6)),
            ),
            const SizedBox(height: 14),
            for (final s in guideSections) _Section(s),
            const SizedBox(height: 10),
            Center(child: KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back())),
          ]),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.s);
  final GuideSection s;

  @override
  Widget build(BuildContext context) {
    final body = kidText(15, weight: FontWeight.w500, height: 1.85);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.line, width: 2),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: ExpansionTile(
        initiallyExpanded: s.open,
        backgroundColor: AppColors.paper2,
        collapsedBackgroundColor: AppColors.paper2,
        shape: shape,
        collapsedShape: shape,
        iconColor: AppColors.inkSoft,
        collapsedIconColor: AppColors.inkSoft,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(children: [
          Text(s.icon, style: const TextStyle(fontSize: 21)),
          const SizedBox(width: 10),
          Expanded(child: Text(s.title, style: kidText(17))),
        ]),
        children: [
          for (final b in s.body)
            switch (b) {
              GP(:final text) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text.rich(richGuide(text, body)),
                ),
              GList(:final items, :final ordered) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 24, child: Text(ordered ? '${ar(i + 1)}.' : '•', style: body)),
                          Expanded(child: Text.rich(richGuide(items[i], body))),
                        ]),
                      ),
                  ]),
                ),
            },
        ],
      ),
    );
  }
}
