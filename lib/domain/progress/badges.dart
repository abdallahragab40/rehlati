/// نظام الإنجازات (Badges) — منقول من js/rewards.js.
library;

import 'progress_data.dart';

class Achievement {
  const Achievement(this.id, this.icon, this.name, this.when);
  final String id;
  final String icon;
  final String name;
  final bool Function(ProgressData p) when;
}

final badges = <Achievement>[
  Achievement('first_game', '🏆', 'أول لعبة', (p) => p.games >= 1),
  Achievement('stars10', '⭐', '١٠ نجوم', (p) => p.stars >= 10),
  Achievement('stars50', '🌟', '٥٠ نجمة', (p) => p.stars >= 50),
  Achievement('stars100', '💯', '١٠٠ نجمة', (p) => p.stars >= 100),
  Achievement('first_surah', '📖', 'أول سورة', (p) => p.quran.isNotEmpty),
  Achievement('num_master', '🔢', 'إتقان الأرقام',
      (p) => (p.best['counting'] ?? 0) >= 2 && (p.best['chooseNumber'] ?? 0) >= 2),
  Achievement('add_master', '➕', 'إتقان الجمع', (p) => (p.best['addition'] ?? 0) >= 2),
  Achievement('sub_master', '➖', 'إتقان الطرح', (p) => (p.best['subtraction'] ?? 0) >= 2),
  Achievement('ar_letters', '🔤', 'إتقان الحروف', (p) => p.learned('ar_learn').length >= 28),
  Achievement('en_words10', '🇬🇧', 'أول ١٠ كلمات English', (p) => p.learned('en_learn').length >= 10),
  Achievement('quran5', '🕌', '٥ أنشطة قرآن', (p) => p.quran.length >= 5),
];

/// يضيف الإنجازات الجديدة للملف ويرجّعها (عشان نعرض لها toast).
List<Achievement> checkBadges(ProgressData p) {
  final fresh = badges.where((b) => !p.achievements.contains(b.id) && b.when(p)).toList();
  for (final b in fresh) {
    p.achievements.add(b.id);
  }
  return fresh;
}
