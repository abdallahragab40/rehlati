/// ألوان ورسومات المدود — منقولة من css/madd.css.
///
/// كل نوع ليه لون + مربّع + اسم (مش اللون لوحده) عشان الأطفال اللي عندهم عمى ألوان.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/features.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/question.dart';

/// (لون النص والحدود، لون الخلفية) لكل نوع مد.
(Color, Color) maddColors(String? key) => switch (key) {
      'alif' => (const Color(0xFF1E7FBF), const Color(0xFFDDF1FF)),
      'waw' => (const Color(0xFF1F8A49), const Color(0xFFDEF7E5)),
      'yaa' => (const Color(0xFFA66F00), const Color(0xFFFFF0C2)),
      'mamdoud' => (mamdoudColor, const Color(0xFFEFE7FF)),
      'maddletter' => (const Color(0xFFC2410C), const Color(0xFFFFE9DC)),
      _ => (const Color(0xFFE8564F), AppColors.paper2),
    };

const mamdoudColor = Color(0xFF6B3FC4);

/// نص فيه حرف المد ملوّن — ولو فيه [mamStart] الحرف الممدود بيتعلّم بخط متقطع بنفسجي.
/// (الويب بيحط إطار حوالين الممدود؛ هنا خط تحته عشان الحروف تفضل موصولة.)
TextSpan maddSpan(String text, {int? hl, int? mamStart, String? typeKey, required TextStyle style}) {
  if (hl == null || hl < 0 || hl >= text.length) return TextSpan(text: text, style: style);
  final c = maddColors(typeKey).$1;
  final m = (mamStart != null && mamStart >= 0 && mamStart < hl) ? mamStart : hl;
  return TextSpan(style: style, children: [
    TextSpan(text: text.substring(0, m)),
    if (m < hl)
      TextSpan(
        text: text.substring(m, hl),
        style: const TextStyle(
          color: mamdoudColor,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dashed,
          decorationColor: mamdoudColor,
          decorationThickness: 2.5,
        ),
      ),
    TextSpan(text: text.substring(hl, hl + 1), style: TextStyle(color: c, fontWeight: FontWeight.w900)),
    TextSpan(text: text.substring(hl + 1)),
  ]);
}

/// المقطع أو الكلمة بخط كبير (.msyl) — ومعاه 🔊 صغيرة لو فيه say.
class MaddTextView extends ConsumerWidget {
  const MaddTextView(this.v, {super.key});
  final MaddTextVisual v;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = v.big ? context.clampVw(72, 22, 120) : context.clampVw(64, 19, 104);
    Widget text = Text.rich(
      maddSpan(v.text, hl: v.hl, mamStart: v.mamStart, typeKey: v.typeKey, style: kidText(size, height: 1.5)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    if (v.pop) text = text.anim().scaleXY(begin: 1, end: 1.18, duration: 200.ms).then().scaleXY(begin: 1, end: 1 / 1.18, duration: 250.ms);
    if (v.say == null) return Center(child: text);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [text, if (voiceEnabled) ListenButton(v.say!, size: 56)],
    );
  }
}

/// زرار السماعة البنفسجي (.mlisten).
class ListenButton extends ConsumerWidget {
  const ListenButton(this.say, {super.key, this.size});
  final String say;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = size ?? context.clampVw(96, 28, 130);
    return Pressable3D(
      onTap: () => ref.read(speechProvider).speak(say),
      color: AppColors.grape,
      radius: d,
      depth: d > 60 ? 8 : 5,
      semanticLabel: 'اسمع',
      child: SizedBox.square(
        dimension: d,
        child: Center(child: Text('🔊', style: TextStyle(fontSize: d * .46))),
      ),
    );
  }
}
