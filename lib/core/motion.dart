/// الحركة: لما الجهاز طالب "تقليل الحركة" أو ولي الأمر شغّل الوضع الهادي، الأنيميشن
/// بتظهر في آخرها على طول من غير حركة — الإشارات (زي توهّج التلميح) بتفضل باينة ثابتة.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

abstract final class Motion {
  /// بيتظبط من فوق التطبيق (MotionSync في app.dart) — الشاشات الجديدة بتاخده على طول.
  static bool reduced = false;
}

extension MotionAnimate on Widget {
  /// زي `animate()` بس بيحترم تقليل الحركة: الأنيميشن بتبدأ من آخرها ومابتتكررش.
  Animate anim({Key? key, Duration? delay, AnimateCallback? onPlay, bool? autoPlay}) => Motion.reduced
      ? animate(key: key, autoPlay: false, value: 1)
      : animate(key: key, delay: delay, onPlay: onPlay, autoPlay: autoPlay);
}
