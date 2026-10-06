/// خلص وقت اللعب النهاردة — رسالة لطيفة، مش منع جاف (UI.timeUp في الويب).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../parent/parent_gate.dart';

class TimeUpScreen extends ConsumerStatefulWidget {
  const TimeUpScreen({super.key});

  @override
  ConsumerState<TimeUpScreen> createState() => _TimeUpScreenState();
}

class _TimeUpScreenState extends ConsumerState<TimeUpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(speechProvider).speak(sayTimeUp));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    return ScreenFrame(
      onBack: () => context.back(),
      title: 'وقت الراحة',
      child: QCard(
        child: Column(children: [
          const LionMascot(emoji: '🌙'),
          const SizedBox(height: 8),
          Text('خلاص يا بطل، بكرة نكمّل!', textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30))),
          const SizedBox(height: 6),
          Text(
            'لعبت النهاردة ${ar(p.todayMin)} دقيقة، وده كفاية عشان عينيك ترتاح.'
            '${p.goalDone ? ' وكمان خلّصت هدف النهاردة ⭐' : ''}',
            textAlign: TextAlign.center,
            style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft, height: 1.7),
          ),
          SpeechBubble('🔥 سلسلتك ${ar(p.streak)} يوم — حافظ عليها بكرة!', kind: BubbleKind.ok),
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('🏠 الصفحة الرئيسية', kind: BtnKind.ghost, onTap: () => context.go('/')),
            KidButton('👨‍👩‍👦 ولي الأمر', kind: BtnKind.ghost, onTap: () async {
              final router = GoRouter.of(context);
              if (await askParent(context)) router.push('/parent');
            }),
          ]),
        ]),
      ),
    );
  }
}
