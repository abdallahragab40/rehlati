/// جواز رحلتي: كل عالم «بلد» ليه صفحة، وفيها ٣ أختام بتتختم مع تقدّم الطفل فيه.
/// محسوب من نسبة إنجاز العالم (worldPct) — مفيش بيانات جديدة بتتخزّن.
library;

import 'progress/progress_data.dart';
import 'stages.dart';

/// الختم بيتختم من النسبة دي وطالع: زار البلد، نص الطريق، أتقنها.
const stampAt = [1, 50, 80];

const stampNames = ['زرتها', 'نص الطريق', 'أتقنتها'];

class PassportPage {
  const PassportPage(this.world, this.pct);
  final WorldMeta world;
  final int pct;

  int get stamps => stampAt.where((t) => pct >= t).length;
}

List<PassportPage> passport(ProgressData p) => [for (final w in worlds) PassportPage(w, p.worldPct(w.id))];

int stampCount(ProgressData p) => passport(p).fold(0, (s, page) => s + page.stamps);

int get stampTotal => worlds.length * stampAt.length;
