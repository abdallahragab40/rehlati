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
  final a = 11 + r.nextInt(9), b = 3 + r.nextInt(7);
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) {
      void submit() => c.pop(int.tryParse(_latin(ctrl.text.trim())) == a * b);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('للأهل فقط', style: kidText(22), textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('كام ${ar(a)} × ${ar(b)} ؟', style: kidText(26)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
            textAlign: TextAlign.center,
            style: kidText(24),
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => c.pop(), child: const Text('إلغاء')),
          FilledButton(onPressed: submit, child: const Text('دخول')),
        ],
      );
    },
  );
  ctrl.dispose();
  if (ok == false && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة غير صحيحة.')));
  }
  return ok ?? false;
}

/// الكيبورد العربي بيكتب ٠–٩ — نحوّلها لأرقام عادية قبل المقارنة.
String _latin(String s) => s.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
