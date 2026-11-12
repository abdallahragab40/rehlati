import 'package:flutter/material.dart';

import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';

/// الطفل حل كل الأسئلة الجديدة في المرحلة دي. بدل ما الأسئلة تتعاد من غير ما يعرف، بنقوله
/// بوضوح ونديله مراجعة مكتوب عليها «مراجعة» (lib/domain/fresh_round.dart).
class AllSeenView extends StatelessWidget {
  const AllSeenView({super.key, required this.session, required this.engine});
  final GameSession session;
  final GameEngine engine;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 8),
          const LionMascot(mood: LionMood.cheer),
          const SizedBox(height: 10),
          Text('خلّصت كل الأسئلة الجديدة هنا 🎉',
              textAlign: TextAlign.center, style: kidText(context.clampVw(24, 6.4, 34))),
          const SizedBox(height: 8),
          SpeechBubble('حليت كل أسئلة «${session.stage.icon} ${session.stage.name}» في كل المستويات. '
              'مفيش أسئلة جديدة هنا دلوقتي.'),
          const SpeechBubble('المراجعة بتعيد أسئلة شفتها قبل كده، عشان تثبّت اللي اتعلمته 🔁'),
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
            KidButton('🔁 راجع اللي اتعلمته', kind: BtnKind.go, onTap: engine.reviewStage),
            KidButton('🗺️ اختار مرحلة تانية', kind: BtnKind.ghost, onTap: () => context.back()),
          ]),
        ],
      );
}
