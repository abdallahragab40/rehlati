import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';

/// بوابة بسيطة تمنع الطفل من الدخول: سؤال ضرب (a من ١١–١٩ × b من ٣–٩).
/// Apple Kids Category بتطلب بوابة زي دي قبل أي إعدادات أو روابط خارجية.
Future<bool> askParent(BuildContext context) async {
  final r = Random();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _GateDialog(a: 11 + r.nextInt(9), b: 3 + r.nextInt(7)),
  );
  if (ok == false && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة غير صحيحة.')));
  }
  return ok ?? false;
}

/// لوحة ولي الأمر ورا السؤال — من زرار الرئيسية وشاشة الراحة.
Future<void> openParentArea(BuildContext context) async {
  final router = GoRouter.of(context);
  if (await askParent(context)) router.push('/parent');
}

/// الدايالوج بيملك الـ controller بتاعه — لو اتقفل بعد ما الدايالوج يرجع، الحقل
/// بيكون لسه ظاهر في أنيميشن القفل وبيقع.
class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.a, required this.b});
  final int a, b;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => context.pop(int.tryParse(latinDigits(_ctrl.text.trim())) == widget.a * widget.b);

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('للأهل فقط', style: kidText(22), textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('كام ${ar(widget.a)} × ${ar(widget.b)} ؟', style: kidText(26)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
            textAlign: TextAlign.center,
            style: kidText(24),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('إلغاء')),
          FilledButton(onPressed: _submit, child: const Text('دخول')),
        ],
      );
}

/// الكيبورد العربي بيكتب ٠–٩ — نحوّلها لأرقام عادية قبل المقارنة.
String latinDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
