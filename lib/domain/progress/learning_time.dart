/// وقت التعلّم الفعلي: بيتعد بس والطفل جوه نشاط والتطبيق قدامه.
///
/// تعريف واحد لكل الأنشطة (الألعاب والقرآن ولوحة الحروف والمدود وأنشطة دليل ولي الأمر).
/// الخرايط وشاشات ولي الأمر والوقت اللي التطبيق فيه في الخلفية مابيتعدّوش.
library;

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_controller.dart';
import 'progress_data.dart';

class LearningTimer {
  LearningTimer({
    required this.now,
    required this.add,
    required this.limitReached,
    this.maxSegment = const Duration(minutes: 2),
  });

  final DateTime Function() now;

  /// بيسجّل [ms] في ملف الطفل تحت يوم [day].
  final void Function(int ms, DateTime day) add;
  final bool Function() limitReached;

  /// أطول مدة بتتحسب بين تسجيلين. النشاط المفتوح بيسجّل كل ٣٠ ثانية، فالفجوة الأكبر
  /// معناها إن التطبيق كان واقف (الجهاز نام من غير ما يبلّغنا) — مانعدّهاش كلها.
  final Duration maxSegment;

  int _open = 0;
  bool _foreground = true;
  DateTime? _since;

  bool get running => _since != null;

  /// نشاط اتفتح.
  void enter() {
    _open++;
    _sync();
  }

  /// نشاط اتقفل — الوقت اللي فات بيتسجّل.
  void leave() {
    flush();
    _open = math.max(0, _open - 1);
    _sync();
  }

  /// التطبيق راح الخلفية أو رجع.
  void setForeground(bool foreground) {
    flush();
    _foreground = foreground;
    _sync();
  }

  /// يسجّل الوقت اللي فات من آخر تسجيل في ملف الطفل، ويقسمه عند نص الليل.
  void flush() {
    final since = _since;
    if (since == null) return;
    final to = now();
    _since = to;
    if (!to.isAfter(since)) return; // الساعة رجعت لورا — مانعدّش سالب
    var from = to.difference(since) > maxSegment ? to.subtract(maxSegment) : since;
    while (true) {
      final midnight = DateTime(from.year, from.month, from.day + 1);
      if (!to.isAfter(midnight)) break;
      add(midnight.difference(from).inMilliseconds, from);
      from = midnight;
    }
    final ms = to.difference(from).inMilliseconds;
    if (ms > 0) add(ms, from);
  }

  /// نقطة وقوف (بين سؤال والتاني أو آية والتانية): يسجّل ويقول لو وقت النهاردة خلص.
  bool checkpoint() {
    flush();
    return limitReached();
  }

  void _sync() {
    final on = _open > 0 && _foreground;
    if (on && _since == null) _since = now();
    if (!on && _since != null) {
      flush();
      _since = null;
    }
  }
}

final learningTimeProvider = Provider<LearningTimer>((ref) => LearningTimer(
      now: () => ProgressData.clock(),
      add: (ms, day) {
        if (ref.mounted) ref.read(progressProvider.notifier).update((p) => p.addTime(ms, day));
      },
      limitReached: () => ref.read(progressProvider).limitReached,
    ));
