/// ألوان ورسومات المدود — منقولة من css/madd.css.
///
/// كل نوع ليه لون + مربّع + اسم (مش اللون لوحده) عشان الأطفال اللي عندهم عمى ألوان.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/question.dart';

/// (لون النص والحدود، لون الخلفية) لكل نوع مد.
(Color, Color) maddColors(String? key) => switch (key) {
      'alif' => (const Color(0xFF1E7FBF), const Color(0xFFDDF1FF)),
      'waw' => (const Color(0xFF1F8A49), const Color(0xFFDEF7E5)),
      'yaa' => (const Color(0xFFA66F00), const Color(0xFFFFF0C2)),
      _ => (const Color(0xFFE8564F), AppColors.paper2),
    };

/// نص فيه حرف المد ملوّن.
TextSpan maddSpan(String text, {int? hl, String? typeKey, required TextStyle style}) {
  if (hl == null || hl < 0 || hl >= text.length) return TextSpan(text: text, style: style);
  final c = maddColors(typeKey).$1;
  return TextSpan(style: style, children: [
    TextSpan(text: text.substring(0, hl)),
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
      maddSpan(v.text, hl: v.hl, typeKey: v.typeKey, style: kidText(size, height: 1.5)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    if (v.pop) text = text.animate().scaleXY(begin: 1, end: 1.18, duration: 200.ms).then().scaleXY(begin: 1, end: 1 / 1.18, duration: 250.ms);
    if (v.say == null) return Center(child: text);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [text, ListenButton(v.say!, size: 56)],
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
