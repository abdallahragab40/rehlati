import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/kid_widgets.dart';
import '../core/widgets/top_bar.dart';

/// مكان مؤقت للشاشات اللي لسه في المراحل الجاية من الخطة (docs/PLAN.md).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) => ScreenFrame(
        onBack: () => context.pop(),
        title: title,
        child: QCard(
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text('$title — قريبًا', style: kidText(24), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.pop()),
          ]),
        ),
      );
}
