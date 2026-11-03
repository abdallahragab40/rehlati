import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/speech_service.dart';
import 'package:rehlati/core/audio/voice_lines.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/question.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  test('every spoken lesson card and task has recordings on disk, including English reading', () {
    final checked = <String>{};
    void recorded(Object text, {bool en = false}) {
      final keys = en ? SpeechService.enClipsFor(text) : SpeechService.clipsFor(text, null);
      expect(keys, isNotNull, reason: 'missing ${en ? 'English' : 'Arabic'} recording: $text');
      for (final key in keys!) {
        if (!checked.add(key)) continue;
        final file = File('assets/audio/clips/$key.m4a');
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(file.lengthSync(), greaterThan(100), reason: 'empty audio: ${file.path}');
      }
    }

    void card(LessonCard c, {bool read = false}) {
      if (!read || c.en == null) recorded(c.spoken);
      if (c.en case final text?) recorded(text, en: true);
      if (c.visual case ListenVisual(:final say, :final en)) recorded(say, en: en);
    }

    recorded(sayReadFirst);
    recorded(sayLessonDone);
    for (final l in allLessonFiles()) {
      for (final b in l.blocks) {
        switch (b) {
          case HookBlock(:final card, :final ask):
            // The screen combines the spoken card and hook question into parts.
            if (card.en case final text?) recorded(text, en: true);
            recorded([...(card.say ?? [card.text]), ?ask]);
          case ExplainBlock(:final card):
            // A card can have an Arabic explanation and a separate English button.
            recorded(card.spoken);
            if (card.en case final text?) recorded(text, en: true);
          case ExampleBlock(:final steps):
            steps.forEach(card);
          case StoryBlock(:final pages):
            pages.forEach(card);
          case ReadBlock(:final items):
            for (final item in items) {
              card(item, read: true);
            }
          case PoemBlock(:final lines):
            recorded(lines);
          case TryBlock(:final tasks):
            for (final t in tasks) {
              recorded(t.say ?? t.ask);
              recorded(t.hint);
              recorded(t.why);
              t.hints.values.forEach(recorded);
              if (t.help case final help?) card(help);
              if (t.visual case ListenVisual(:final say, :final en)) recorded(say, en: en);
            }
          case ActivityBlock(:final text):
            recorded(text);
          case SummaryBlock():
            break;
        }
      }
    }
    expect(checked.length, greaterThan(1000));
  });
}
