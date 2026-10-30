import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/language_data.dart';
import 'package:rehlati/core/audio/parent_voice.dart';

void main() {
  test('parents can record every letter name and the numbers 0 to 10', () {
    expect(parentVoiceItems.where((i) => i.key.startsWith('l_')), hasLength(arLetters.length));
    expect(parentVoiceItems.where((i) => i.key.startsWith('n')).map((i) => i.key), [for (var n = 0; n <= 10; n++) 'n$n']);
    expect(parentVoiceItems.firstWhere((i) => i.label == 'ب').prompt, 'باء');
    expect(parentVoiceItems.firstWhere((i) => i.key == 'n5').prompt, 'خمسة');
  });

  test('a saved recording replaces the clip until it is removed', () async {
    final dir = await Directory.systemTemp.createTemp('voice');
    addTearDown(() => dir.delete(recursive: true));
    ParentVoice.debugSet('${dir.path}/parent_voice', {});
    final take = File('${dir.path}/take.m4a')..writeAsBytesSync([1, 2, 3]);

    expect(ParentVoice.pathFor('n5'), isNull);
    await ParentVoice.save('n5', take.path);
    expect(ParentVoice.pathFor('n5'), '${dir.path}/parent_voice/n5.m4a');
    expect(File(ParentVoice.pathFor('n5')!).readAsBytesSync(), [1, 2, 3]);

    await ParentVoice.remove('n5');
    expect(ParentVoice.pathFor('n5'), isNull);
    expect(File('${dir.path}/parent_voice/n5.m4a').existsSync(), isFalse);
  });
}
