/// مراحل تقدّم الطفل — كؤوس بتتفتح بالنجوم المجمّعة (RANKS في js/rewards.js).
///
/// الطفل بيشوف الكأس الجاي والنجوم الفاضلة عليه — أقوى محفّز بعد السلسلة اليومية.
/// لزيادة مرحلة: ضيف سطر هنا وبس.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'progress_data.dart';

class Rank {
  const Rank(this.id, this.icon, this.name, this.at, this.color);
  final String id;
  final String icon;
  final String name;

  /// عدد النجوم اللي بيفتح الكأس.
  final int at;
  final Color color;
}

const ranks = [
  Rank('egg', '🥚', 'مبتدئ', 0, Color(0xFFA9B4C2)),
  Rank('bronze', '🥉', 'كأس برونزي', 50, Color(0xFFC97B3C)),
  Rank('silver', '🥈', 'كأس فضي', 150, Color(0xFF9AA7B4)),
  Rank('gold', '🏆', 'كأس ذهبي', 350, Color(0xFFE0A400)),
  Rank('platinum', '🥇', 'كأس بلاتيني', 650, Color(0xFF5FA8C7)),
  Rank('diamond', '💎', 'كأس ماسي', 1000, Color(0xFF3FC2D6)),
  Rank('crown', '👑', 'بطل الأبطال', 1500, Color(0xFF8B5CF6)),
];

int rankIndex(int stars) {
  var i = 0;
  for (final (k, r) in ranks.indexed) {
    if (stars >= r.at) i = k;
  }
  return i;
}

Rank rankOf(int stars) => ranks[rankIndex(stars)];
Rank? nextRank(int stars) => rankIndex(stars) + 1 < ranks.length ? ranks[rankIndex(stars) + 1] : null;

/// نسبة التقدّم ناحية الكأس الجاي (٠–١٠٠).
int rankPct(int stars) {
  final i = rankIndex(stars);
  if (i + 1 >= ranks.length) return 100;
  final from = ranks[i].at, to = ranks[i + 1].at;
  return ((stars - from) / (to - from) * 100).round().clamp(0, 100);
}

int starsToNext(int stars) => math.max(0, (nextRank(stars)?.at ?? stars) - stars);

/// ترقية؟ بترجّع الكأس الجديد مرة واحدة بس. أول مرة بنسجّل المرحلة الحالية من غير احتفال.
Rank? rankCheck(ProgressData p) {
  final now = rankIndex(p.stars);
  if (p.rankSeen == null) {
    p.rankSeen = now;
    return null;
  }
  if (now <= p.rankSeen!) return null;
  p.rankSeen = now;
  return ranks[now];
}
