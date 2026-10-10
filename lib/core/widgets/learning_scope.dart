/// غلاف لكل شاشات الطفل: بيمنع الدخول لو وقت النهاردة خلص، وبيعدّ وقت الأنشطة.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/progress/learning_time.dart';

class LearningScope extends ConsumerStatefulWidget {
  const LearningScope({super.key, required this.child, this.track = true, this.stopsItself = false, this.world});
  final Widget child;

  /// العالم اللي الوقت بيتحسب عليه في تقرير الأسبوع.
  final String? world;

  /// false للخرايط والقوايم: بنتحقق من الحد بس من غير ما نعدّ وقت.
  final bool track;

  /// الشاشة بتقف لوحدها بين سؤال والتاني (الألعاب والقرآن). غير كده الغلاف بيوقفها
  /// أول ما الوقت يخلص، لأن مفيهاش أسئلة بنهاية واضحة.
  final bool stopsItself;

  /// كل قد إيه بنسجّل الوقت ونشيّك على الحد.
  static const tick = Duration(seconds: 30);

  @override
  ConsumerState<LearningScope> createState() => _LearningScopeState();
}

class _LearningScopeState extends ConsumerState<LearningScope> {
  late final LearningTimer _time;
  Timer? _tick;
  AppLifecycleListener? _life;
  bool _entered = false, _stopped = false;

  @override
  void initState() {
    super.initState();
    _time = ref.read(learningTimeProvider);
    // قراءة بس — مينفعش نعدّل التقدّم وإحنا بنبني الشاشة. الوقت المفتوح (أقل من ٣٠ ثانية) بيتسجّل مع أول tick
    if (_time.limitReached()) {
      _stop();
      return;
    }
    if (!widget.track) return;
    _time.enter(widget.world);
    _entered = true;
    _life = AppLifecycleListener(onStateChange: (s) => _time.setForeground(s == AppLifecycleState.resumed));
    _tick = Timer.periodic(LearningScope.tick, (_) {
      if (_time.checkpoint() && !widget.stopsItself) _stop();
    });
  }

  /// بنبدّل الشاشة بشاشة "وقت الراحة" — الرجوع منها بيودّي للي قبل النشاط.
  void _stop() {
    if (_stopped) return;
    setState(() => _stopped = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pushReplacement('/timeup');
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _life?.dispose();
    // برضه مينفعش نعدّل التقدّم جوه dispose — بنسجّل بعدها على طول
    if (_entered) Future.microtask(_time.leave);
    super.dispose();
  }

  // النشاط مايبدأش أصلًا (ولا صوته) لو الوقت خلص
  @override
  Widget build(BuildContext context) => _stopped ? const SizedBox.shrink() : widget.child;
}
