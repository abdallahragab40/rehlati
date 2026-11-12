/// بصمة السؤال: نوعه ونصه وإجابته وكل اللي الطفل بيشوفه — عشان نفس السؤال مايتعرضش تاني
/// في المحتوى الجديد (lib/domain/fresh_round.dart).
///
/// التوحيد شكلي بس: المسافات الزيادة، وترتيب الاختيارات والبطاقات (لأنها بتتلخبط في العرض).
/// التشكيل والهمزات جزء من البصمة، فـ«الطيورَ» و«الطيورِ» سؤالين مختلفين. النص الأصلي مابيتغيّرش.
library;

import 'dart:convert' show utf8;

import 'question.dart';

/// أوضاع لعب مش أسئلة: الجدول الفاضي، الذاكرة، الرسم بالصباع والألغاز. تكرارها هو التمرين نفسه،
/// فمابتتسجّلش ومابتتمنعش.
const activityModes = {
  QMode.grid, QMode.memory, QMode.color, QMode.rhythm, QMode.cups,
  QMode.maze, QMode.trace, QMode.sudoku, QMode.hanoi, QMode.slide,
};

bool isActivity(Question q) => activityModes.contains(q.mode);

/// البصمة: FNV-1a (٣٢ بت) لـ [questionSig].
int questionKey(Question q) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(questionSig(q))) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  return h;
}

String _t(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
String _sorted(Iterable<Object?> xs) => ([for (final x in xs) _t('$x')]..sort()).join('|');

/// النص اللي البصمة بتتحسب منه — مقروء عشان الاختبارات وتقرير التكرار.
String questionSig(Question q) => [
      q.type,
      q.mode.name,
      _t(q.ask),
      _t(q.speak),
      switch (q.answer) { final List<Object?> l => l.join('|'), final a => '$a' },
      _sorted(q.choices),
      _sorted(q.items),
      _sorted(q.right),
      _sorted([for (final e in q.pairMap.entries) '${e.key}=${e.value}']),
      _sorted([for (final c in q.cells) c.ch]),
      _sorted([for (final c in q.sortCards) c.text]),
      _sorted([for (final b in q.boxes) b.key]),
      q.mword ?? '',
      q.picName ?? '',
      for (final v in q.visuals) visualSig(v),
    ].join('§');

/// كل مرئية بقيمها. الـ switch كامل على [Visual] (sealed)، فأي مرئية جديدة لازم تتضاف هنا.
String visualSig(Visual v) => switch (v) {
      PicsVisual v => 'pics:${v.emoji}:${v.count}:${v.goneFrom}',
      ExprVisual v => 'expr:${v.parts.map(_part).join(',')}',
      BigLetterVisual v => 'big:${v.text}',
      CaptionVisual v => 'cap:${_t(v.text)}',
      WordLineVisual v => 'word:${v.word ?? v.letters!.map((l) => l ?? '_').join()}',
      LetterChipsVisual v => 'chips:${v.letters.join()}',
      TableVisual v => 'table:${v.kind.name}:${v.cells.map((c) => c ?? '_').join(',')}',
      MaddTextVisual v => 'madd:${v.text}:${v.hl}:${v.mamStart}',
      PatternVisual v => 'pattern:${v.items.join(',')}:${v.hole}',
      ClockVisual v => 'clock:${v.hour}:${v.minute}',
      TensOnesVisual v => 'tens:${v.tens}:${v.ones}',
      GroupsVisual v => 'groups:${v.emoji}:${v.groups}:${v.each}',
      MoneyVisual v => 'money:${v.pounds.join(',')}',
      PassageVisual v => 'passage:${v.title}:${_t(v.text)}',
      ListenVisual v => 'listen:${v.en}:${_t(v.say)}',
      EmojiVisual v => 'emoji:${v.emoji}:${v.caption}',
      ShapeVisual v => 'shape:${v.shape}',
      QueueVisual v => 'queue:${v.items.join(',')}:${v.flag}',
      PairsVisual v => 'pairs:${v.emoji}:${v.count}',
      CoinsVisual v => 'coins:${v.coins.join(',')}',
      CoordVisual v => 'coord:${v.points}:${v.lo}:${v.hi}',
      NumberLineVisual v => 'line:${v.lo}:${v.hi}:${v.mark}',
      BoxVisual v => 'box:${v.l}:${v.w}:${v.h}:${v.labels}',
      PieVisual v => 'pie:${v.eighths.join(',')}',
      AngleVisual v => 'angle:${v.degrees}',
      LinesVisual v => 'lines:${v.kind}',
      GridAreaVisual v => 'area:${v.cols}:${v.rows}:${v.cells}:${v.grid}:${v.sides}',
      DotPlotVisual v => 'dots:${v.rows}',
      ComposeVisual v => 'compose:${v.pieces}:${v.apart}',
      PrepVisual v => 'prep:${v.thing}:${v.place}:${v.prep}',
      BarGraphVisual v => 'bars:${v.rows}:${v.scale}',
      PicGraphVisual v => 'picgraph:${v.rows}',
      PlantVisual v => 'plant:${v.highlight}',
      OppositeVisual v => 'opposite:${v.spec}',
    };

String _part(ExprPart p) => switch (p) {
      ExprTile p => 't${p.value ?? '_'}',
      ExprCaption p => 'c${p.caption}=${_part(p.inner)}',
      ExprOp p => 'o${p.op}',
      ExprSide p => 's${p.emoji}${p.count}:${p.number}',
    };
