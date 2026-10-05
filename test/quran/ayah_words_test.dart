import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/features/quran/recitation.dart';

void main() {
  test('a standalone pause mark sticks to the previous word', () {
    expect(ayahWords('كَلَّا ۖ سَيَعْلَمُونَ'), ['كَلَّا ۖ', 'سَيَعْلَمُونَ']);
  });

  test('a leading mark sticks to the next word', () {
    expect(ayahWords('۞ أَلَمْ تَرَ'), ['۞ أَلَمْ', 'تَرَ']);
  });

  test('joining the words gives back the original text', () {
    const t = 'وَٱلْفَجْرِ ۚ وَلَيَالٍ عَشْرٍ ۩';
    expect(ayahWords(t).join(' '), t);
  });
}
