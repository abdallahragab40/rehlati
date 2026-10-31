/// شاشة «صوت ماما وبابا» في لوحة ولي الأمر: تسجيل اسم كل حرف ورقم بصوت ولي الأمر.
/// المايك بيتطلب هنا بس (ورا سؤال ولي الأمر)، مش في أي شاشة للطفل.
library;

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/parent_voice.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../core/widgets/toast.dart';

class ParentVoiceScreen extends ConsumerStatefulWidget {
  const ParentVoiceScreen({super.key});

  @override
  ConsumerState<ParentVoiceScreen> createState() => _ParentVoiceScreenState();
}

class _ParentVoiceScreenState extends ConsumerState<ParentVoiceScreen> {
  final _rec = AudioRecorder();

  /// المقطع اللي بيتسجّل دلوقتي.
  String? _recording;
  Timer? _limit;

  @override
  void dispose() {
    _limit?.cancel();
    unawaited(_rec.dispose());
    unawaited(_restoreSession());
    super.dispose();
  }

  void _say(String msg) => showToast(context, msg, kind: ToastKind.error);

  /// التسجيل بيحوّل الجلسة لـ playAndRecord — بنرجّعها زي ما التطبيق عايزها.
  static Future<void> _restoreSession() async {
    try {
      await (await AudioSession.instance).configure(appAudioSession);
    } catch (_) {}
  }

  void _play(VoiceItem item) => ref.read(speechProvider).speak(item.prompt, clips: [item.key]);

  Future<void> _start(VoiceItem item) async {
    if (_recording != null) return;
    ref.read(speechProvider).stop();
    if (!await _rec.hasPermission()) {
      if (mounted) _say('محتاجين إذن المايك — فعّله لرحلتي من إعدادات الجهاز');
      return;
    }
    try {
      await _rec.start(const RecordConfig(numChannels: 1, bitRate: 64000), path: await ParentVoice.tempPath());
    } catch (_) {
      if (mounted) _say('مقدرناش نبدأ التسجيل — جرّب تاني');
      return;
    }
    if (!mounted) return;
    setState(() => _recording = item.key);
    _limit = Timer(ParentVoice.maxLength, () => _stop(item));
  }

  Future<void> _stop(VoiceItem item) async {
    if (_recording != item.key) return;
    _limit?.cancel();
    setState(() => _recording = null);
    final path = await _rec.stop();
    await _restoreSession();
    if (path == null) {
      if (mounted) _say('التسجيل ماتحفظش — جرّب تاني');
      return;
    }
    await ref.read(parentVoiceProvider.notifier).save(item.key, path);
    if (mounted) _play(item);
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('تمسح كل التسجيلات؟', style: kidText(20)),
        content: Text('التطبيق هيرجع للصوت الجاهز.', style: kidText(16, weight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('امسح', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (ok != true) return;
    for (final k in ParentVoice.keys) {
      await ref.read(parentVoiceProvider.notifier).remove(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(parentVoiceProvider);
    final letters = parentVoiceItems.where((i) => i.key.startsWith('l_')).toList();
    final numbers = parentVoiceItems.where((i) => i.key.startsWith('n')).toList();
    final count = parentVoiceItems.where((i) => done.contains(i.key)).length;
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🎙️ صوت ماما وبابا',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🎙️ صوت ماما وبابا', style: kidText(24)),
          const SizedBox(height: 8),
          const NoteBox(Text('سجّل اسم كل حرف ورقم بصوتك، والتطبيق هيقوله بصوتك بدل الصوت الجاهز. '
              'اضغط 🔴 وقول الكلمة، وبعدين ⏹️ (أو يقف لوحده بعد ٤ ثواني). '
              'التسجيلات على الجهاز ده بس: مابتتبعتش لأي مكان ومش جوه النسخة الاحتياطية.')),
          const SizedBox(height: 8),
          Text('سجّلت ${ar(count)} من ${ar(parentVoiceItems.length)}',
              style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          _section('🔤 الحروف', letters, done),
          _section('🔢 الأرقام', numbers, done),
          if (count > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _deleteAll,
                child: Text('🗑️ امسح كل التسجيلات', style: kidText(15, color: AppColors.coral)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _section(String title, List<VoiceItem> items, Set<String> done) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(top: 16, bottom: 6), child: Text(title, style: kidText(19))),
          for (final item in items) _row(item, done.contains(item.key)),
        ],
      );

  Widget _row(VoiceItem item, bool mine) {
    final rec = _recording == item.key;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: rec ? AppColors.noBg : AppColors.paper2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        SizedBox(width: 44, child: Text(item.label, textAlign: TextAlign.center, style: kidText(26))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('قول: ${item.prompt}', style: kidText(15)),
            Text(rec ? 'بيسجّل… اتكلم دلوقتي' : (mine ? '✅ بصوتك' : 'الصوت الجاهز'),
                style: kidText(12.5, weight: FontWeight.w600, color: rec ? AppColors.noInk : AppColors.inkSoft)),
          ]),
        ),
        IconButton(
          tooltip: 'اسمع',
          onPressed: _recording == null ? () => _play(item) : null,
          icon: const Text('🔊', style: TextStyle(fontSize: 22)),
        ),
        IconButton(
          tooltip: rec ? 'وقّف' : 'سجّل',
          onPressed: rec ? () => _stop(item) : (_recording == null ? () => _start(item) : null),
          icon: Text(rec ? '⏹️' : '🔴', style: const TextStyle(fontSize: 22)),
        ),
        if (mine)
          IconButton(
            tooltip: 'ارجع للصوت الجاهز',
            onPressed: _recording == null ? () => ref.read(parentVoiceProvider.notifier).remove(item.key) : null,
            icon: const Text('↩️', style: TextStyle(fontSize: 20)),
          ),
      ]),
    );
  }
}
