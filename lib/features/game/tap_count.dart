/// العدّ باللمس: كل صورة الطفل يلمسها بتنط وتاخد رقمها بالترتيب (١، ٢، ٣…) — بدل
/// "نعد مع بعض" بالصوت. في الجمع العدّ بيكمّل من مجموعة للتانية فآخر رقم = الإجابة.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';

/// بيلم أرقام الصور اللي جوه مرئية واحدة. سؤال جديد = مرئية جديدة = عدّ من الأول.
class TapCountScope extends StatefulWidget {
  const TapCountScope({super.key, required this.child});
  final Widget child;

  @override
  State<TapCountScope> createState() => _TapCountScopeState();
}

class _TapCountScopeState extends State<TapCountScope> {
  final _numbers = <Object, int>{};

  void _count(Object id) {
    if (_numbers.containsKey(id)) return;
    setState(() => _numbers[id] = _numbers.length + 1);
  }

  @override
  Widget build(BuildContext context) =>
      _TapCounts(numbers: Map.of(_numbers), count: _count, child: widget.child);
}

class _TapCounts extends InheritedWidget {
  const _TapCounts({required this.numbers, required this.count, required super.child});
  final Map<Object, int> numbers;
  final void Function(Object id) count;

  @override
  bool updateShouldNotify(_TapCounts old) => old.numbers.length != numbers.length;
}

/// صورة بتتعد باللمس. [enabled] = false للصور المشطوبة في الطرح.
class TapCountItem extends StatelessWidget {
  const TapCountItem({super.key, required this.id, required this.child, this.enabled = true});
  final Object id;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TapCounts>();
    if (scope == null || !enabled) return child;
    final n = scope.numbers[id];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => scope.count(id),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        n == null
            ? child
            : child
                .animate(key: ValueKey(n))
                .scaleXY(begin: 1, end: 1.3, duration: 130.ms, curve: Curves.easeOut)
                .then()
                .scaleXY(begin: 1, end: 1 / 1.3, duration: 320.ms, curve: Curves.elasticOut),
        if (n != null)
          PositionedDirectional(
            top: -6,
            end: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.grape,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(ar(n), style: kidText(13, color: Colors.white, height: 1.1)),
            ).animate().scaleXY(begin: 0, end: 1, duration: 300.ms, curve: Curves.easeOutBack),
          ),
      ]),
    );
  }
}
