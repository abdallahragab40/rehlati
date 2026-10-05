import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/speech_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/progress_controller.dart';
import '../parent/parent_gate.dart';

Future<void> showSettingsSheet(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C0C1C30),
      builder: (_) => const _SettingsPanel(),
    );

class _SettingsPanel extends ConsumerStatefulWidget {
  const _SettingsPanel();

  @override
  ConsumerState<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<_SettingsPanel> {
  bool _showVoice = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(progressProvider.select((p) => p.settings));
    final progress = ref.read(progressProvider.notifier);
    final speech = ref.read(speechProvider);

    Widget row(String label, Widget trailing) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 2))),
          child: Row(children: [
            Expanded(child: Text(label, style: kidText(18, weight: FontWeight.w700))),
            trailing,
          ]),
        );

    Widget toggle(bool value, void Function(bool) set) => Switch(
          value: value,
          activeTrackColor: AppColors.grassDark,
          onChanged: (v) => progress.update((p) => set(v)),
        );

    Widget smallBtn(String label, VoidCallback onTap) =>
        TextButton(onPressed: onTap, child: Text(label, style: kidText(16, color: AppColors.grape)));

    return Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚙️ الإعدادات', style: kidText(24)),
              const SizedBox(height: 10),
              row('🔊 نطق الأسئلة', toggle(settings.speech, (v) {
                ref.read(progressProvider).settings.speech = v;
                if (!v) speech.stop();
              })),
              row('🎵 أصوات اللعبة', toggle(settings.sfx, (v) {
                ref.read(progressProvider).settings.sfx = v;
                if (v) ref.read(sfxProvider).good();
              })),
              row('🎤 صوت القراءة', smallBtn('جرّب', () {
                progress.update((p) => p.settings.speech = true);
                speech.speak(['أهلاً يا بطل، أنا الأسد صاحبك', 'واحد، اتنين، تلاتة']);
                ref.read(sfxProvider).good();
                Future.delayed(const Duration(milliseconds: 1800), () {
                  if (mounted) setState(() => _showVoice = true);
                });
              })),
              if (_showVoice && speech is SpeechService) _VoiceReport(speech),
              row('👨‍👩‍👦 لوحة ولي الأمر', smallBtn('افتح', () async {
                final ok = await askParent(context);
                if (ok && context.mounted) {
                  context.pop();
                  context.push('/parent');
                }
              })),
              row('📘 دليل الوالدين', smallBtn('افتح', () {
                context.pop();
                context.push('/guide');
              })),
              // فتح كل المراحل للتجربة — ورا بوابة الأهل عشان الطفل مايدخلش مراحل أصعب من مستواه
              row('🔓 فتح كل المراحل (للتطوير)', Switch(
                value: settings.dev,
                activeTrackColor: AppColors.grassDark,
                onChanged: (v) async {
                  if (v && !await askParent(context)) return;
                  progress.update((p) => p.settings.dev = v);
                },
              )),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  KidButton('🗑️ إعادة ضبط التقدم', kind: BtnKind.ghost, onTap: () => _confirmReset(context)),
                  KidButton('تمام', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: 14),
              const _Credit(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('إعادة ضبط التقدم؟', style: kidText(20)),
        content: Text('هيتمسح كل التقدم والنجوم والإنجازات. مفيش رجوع.', style: kidText(16, weight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
          TextButton(onPressed: () => c.pop(true), child: const Text('امسح', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ref.read(progressProvider.notifier).reset();
    context.pop();
    context.go('/');
  }
}

class _VoiceReport extends StatelessWidget {
  const _VoiceReport(this.s);
  final SpeechService s;

  @override
  Widget build(BuildContext context) {
    final ok = s.arVoiceName != null;
    final lines = [
      'أصوات متاحة على الجهاز: ${ar(s.voiceCount)}',
      s.arVoices.isNotEmpty ? 'أصوات عربية: ${s.arVoices.join(' • ')}' : '⚠️ مفيش صوت عربي مثبّت على الجهاز',
      'الصوت المختار: ${s.arVoiceName ?? 'لا يوجد'}',
      'آخر محاولة نطق: ${s.lastEvent}',
      '🎙️ مقاطع مسجّلة: ${ar(s.clipCount)}',
    ];
    return NoteBox(Text(
      lines.map((l) => '• $l').join('\n') +
          (ok
              ? ''
              : '\n\nتنزيل صوت عربي:\nأندرويد: الإعدادات ← تحويل النص إلى كلام ← نزّل العربية.\n'
                  'آيفون: الإعدادات ← تسهيلات الاستخدام ← المحتوى المنطوق ← الأصوات ← العربية.'),
    ));
  }
}

class _Credit extends StatelessWidget {
  const _Credit();

  @override
  Widget build(BuildContext context) => Column(children: [
        Text('رحلتي التعليمية — تصميم وتطوير', style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
        Text('Mahmoud Rabea Hassan', style: kidText(15)),
        Text('Software Engineer', style: kidText(12, weight: FontWeight.w600, color: AppColors.inkSoft)),
      ]);
}
