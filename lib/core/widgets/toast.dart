/// إشعار قصير فوق الشاشة (toast) — للتنبيه لما حاجة ناقصة، أو تأكيد إن حاجة اتحفظت، أو خطأ.
///
/// واحد بس ظاهر في المرة: الجديد بيشيل اللي قبله. بيختفي لوحده، ولو اتداس عليه يقفل.
/// قارئ الشاشة بيقراه (liveRegion)، والتنبيه والخطأ معاهم اهتزازة خفيفة.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion.dart';
import '../theme/app_theme.dart';

enum ToastKind { info, ok, warn, error }

OverlayEntry? _current;

/// يعرض [message] فوق الشاشة. [icon] بيغيّر الإيموجي الافتراضي للنوع.
void showToast(BuildContext context, String message, {ToastKind kind = ToastKind.info, String? icon, Duration? duration}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  hideToast();
  if (kind == ToastKind.warn || kind == ToastKind.error) HapticFeedback.mediumImpact();
  late final OverlayEntry entry;
  void close() {
    if (identical(_current, entry)) hideToast();
  }

  entry = OverlayEntry(
    builder: (_) => _ToastView(
      message: message,
      kind: kind,
      icon: icon,
      // الرسالة الأطول بتقعد أكتر عشان تتقري
      duration: duration ?? Duration(milliseconds: 2600 + message.length * 30),
      onDone: close,
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

void hideToast() {
  final e = _current;
  _current = null;
  if (e != null && e.mounted) e.remove();
}

/// الـ Timer جوه الـ State عشان يتلغي لو الشاشة كلها اتقفلت قبل ما الإشعار يختفي.
class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.kind, required this.icon, required this.duration, required this.onDone});
  final String message;
  final ToastKind kind;
  final String? icon;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDone);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ToastView(:message, :kind, :icon) = widget;
    final (bg, ink, edge, emoji) = switch (kind) {
      ToastKind.info => (AppColors.paper, AppColors.ink, AppColors.grape, 'ℹ️'),
      ToastKind.ok => (AppColors.okBg, AppColors.okInk, AppColors.grassDark, '✅'),
      ToastKind.warn => (AppColors.noteBg, AppColors.noteInk, AppColors.goldDark, '✋'),
      ToastKind.error => (AppColors.noBg, AppColors.noInk, AppColors.coral, '⚠️'),
    };
    final card = Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDone,
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: BorderDirectional(start: BorderSide(color: edge, width: 7)),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: Text(icon ?? emoji, style: const TextStyle(fontSize: 28))),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: kidText(16, weight: FontWeight.w700, color: ink, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: Center(
        child: Motion.reduced
            ? card
            : card.animate().fadeIn(duration: 220.ms).moveY(begin: -16, end: 0, duration: 320.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}
