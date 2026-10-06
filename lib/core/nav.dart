/// الرجوع: pop لو فيه شاشة قبلها، وإلا نروح للشاشة "الأب" — زي لما التطبيق يتفتح
/// على شاشة جوه (START أو بعد go)، أو بعد pushReplacement لمرحلة من عالم تاني.
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/stages.dart';

extension BackNav on BuildContext {
  void back() {
    if (canPop()) {
      pop();
    } else {
      go(parentRoute(GoRouterState.of(this).uri.path));
    }
  }
}

/// الشاشة اللي فوق [path] في شجرة التطبيق.
String parentRoute(String path) {
  final seg = path.split('/').where((s) => s.isNotEmpty).toList();
  if (seg.isEmpty) return '/';
  switch (seg.first) {
    case 'play' || 'madd' || 'learn':
      final world = seg.length > 1 ? packs[seg[1]]?.world : null;
      return world == null ? '/' : '/world/$world';
    case 'quran' when seg.length > 1:
      return '/${seg.sublist(0, seg.length - 1).join('/')}';
    case 'pg' when seg.length > 1:
      return seg[1] == 'play' ? '/pg/kids' : '/pg';
    case 'guide' || 'quran-check':
      return '/parent';
    default:
      return '/';
  }
}
