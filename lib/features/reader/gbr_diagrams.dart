import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/atlas_theme.dart';
import '../../map_engine/gbr_map_data.dart';
import '../../map_engine/gbr_learning_map.dart';

class GbrDiagram extends StatefulWidget {
  const GbrDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<GbrDiagram> createState() => _GbrDiagramState();
}

class _GbrDiagramState extends State<GbrDiagram> {
  Timer? timer;
  int beat = -1;
  String island = 'gbr-island-great-britain';
  final camera = GbrMapController();
  Future<GbrMapData>? map;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void play() {
    timer?.cancel();
    setState(() => beat = 0);
    SystemSound.play(SystemSoundType.click);
    timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (beat >= 3) {
        t.cancel();
        setState(() => beat = -1);
        return;
      }
      setState(() => beat++);
      SystemSound.play(SystemSoundType.click);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final title = switch (kind) {
      'gbr-islands-parts' => '国家与岛屿',
      'gbr-river-city' => '河流怎样连接城市',
      'gbr-interchange' => '在共同站点换乘',
      'gbr-column-cooling' => '冷却留下的线索',
      'gbr-rhythm' => '跟着共同的拍子',
      'gbr-puffin-habitat' => '海鹦的两处生活空间',
      'gbr-bilingual' => '两种名字，同一座城市',
      _ => '读懂山地等高线',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtlasPalette.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtlasPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 4, height: 22, color: AtlasPalette.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                '示意',
                style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (kind == 'gbr-islands-parts') ...[
            Wrap(
              spacing: 6,
              children: [
                for (final (id, label) in const [
                  ('gbr-island-great-britain', '大不列颠岛'),
                  ('gbr-island-ireland', '爱尔兰岛'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: island == id,
                    onSelected: widget.interactive
                        ? (_) => setState(() => island = id)
                        : null,
                  ),
              ],
            ),
            SizedBox(
              height: 240,
              child: FutureBuilder<GbrMapData>(
                future: map ??= GbrMapData.load(),
                builder: (context, snapshot) => snapshot.hasData
                    ? GbrLearningMap(
                        region: GbrRegion.all,
                        data: snapshot.data!.all,
                        places: const [],
                        controller: camera,
                        layer: 'islands',
                        selection: island,
                      )
                    : const Center(
                        child: Text('大不列颠岛：英格兰、苏格兰、威尔士主要陆地\n爱尔兰岛：爱尔兰与北爱尔兰'),
                      ),
              ),
            ),
            const Text('国家边界与岛屿海岸回答不同的问题。英国包括四个组成部分及许多周边岛屿。'),
          ] else if (kind == 'gbr-bilingual') ...[
            const _Pair('威尔士语', 'Caerdydd'),
            const SizedBox(height: 8),
            const _Pair('英语', 'Cardiff'),
            const SizedBox(height: 8),
            const Text(
              '都指卡迪夫。实拍车站牌上的 Bae Caerdydd / Cardiff Bay 指卡迪夫湾；Bae 和 Bay 都是「湾」。',
            ),
          ] else if (kind == 'gbr-rhythm') ...[
            const Text('看数字，按相同间隔轻拍四下。示范是原创练习，不是一首传统曲目的录音。'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: beat == i ? AtlasPalette.orange : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.interactive ? play : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('跟着拍四下'),
                ),
                TextButton(
                  onPressed: widget.interactive
                      ? () {
                          timer?.cancel();
                          setState(() => beat = -1);
                        }
                      : null,
                  child: const Text('停止'),
                ),
              ],
            ),
            const Text('示范：1—2—3—4。回应：1—2—3—4。相同间隔，也可以只看数字练习。'),
          ] else if (kind == 'gbr-puffin-habitat') ...[
            const _Pair('海里找食物', '海鹦在海中捕食鱼类。'),
            const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.swap_vert, color: AtlasPalette.navy),
            ),
            const _Pair('岸边育雏', '斯科默岛的草地洞穴提供繁殖空间。'),
            const SizedBox(height: 8),
            const Text('这张示意表示生境联系。季节不同，海鹦的活动也会变化。'),
          ] else ...[
            Semantics(
              label: switch (kind) {
                'gbr-column-cooling' => '从熔岩冷却到收缩开裂，再到柱状岩石显露。',
                'gbr-interchange' => '蓝线甲站到乙站；橙线乙站到丙站。两线在乙站共用站点。',
                'gbr-river-city' => '河流经过两岸之间，桥横跨水面连接两岸。',
                _ => '一圈圈等高线表示同一高度，靠近表示坡更陡。',
              },
              child: SizedBox(
                height: kind == 'gbr-column-cooling' ? 150 : 175,
                child: CustomPaint(painter: _GbrPainter(kind)),
              ),
            ),
            const SizedBox(height: 8),
            if (kind == 'gbr-column-cooling')
              const Text('熔岩冷却 → 收缩开裂 → 柱状岩石。后来的侵蚀让石柱露出来；柱顶并不都是六边形。图不按真实时间或比例。')
            else if (kind == 'gbr-interchange')
              const Text('蓝线：甲站—乙站；橙线：乙站—丙站。乙站为共同站点。原创练习示意，非乘车指南。')
            else if (kind == 'gbr-river-city')
              const Text('两端分别在河流两岸。图只解释关系，不表示伦敦真实的街道或潮位。')
            else
              const Text('每条线连接相同高度的点。同一幅等高线图中，线越密，坡通常越陡。'),
          ],
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.label, this.text);
  final String label, text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AtlasPalette.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 18)),
      ],
    ),
  );
}

class _GbrPainter extends CustomPainter {
  const _GbrPainter(this.kind);
  final String kind;
  void label(Canvas c, String s, Offset p, {Color color = AtlasPalette.navy}) {
    final t = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, p - Offset(t.width / 2, 0));
    t.dispose();
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 360, size.height / 180);
    final p = Paint();
    if (kind == 'gbr-column-cooling') {
      for (var stage = 0; stage < 3; stage++) {
        final x = stage * 122.0;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 20, 112, 114),
            const Radius.circular(10),
          ),
          p
            ..color = stage == 0
                ? const Color(0xffc46736)
                : const Color(0xffc2c6c4),
        );
        if (stage == 0) {
          for (var j = 0; j < 4; j++) {
            c.drawLine(
              Offset(x + 10, 40 + j * 22),
              Offset(x + 98, 49 + j * 19),
              p
                ..color = const Color(0xffffbc61)
                ..strokeWidth = 4,
            );
          }
        } else {
          for (var row = 0; row < 2; row++) {
            for (var col = 0; col < 3; col++) {
              final cx = x + 20 + col * 33 + (row == 1 ? 8 : 0),
                  cy = 48 + row * 40.0;
              final top = Path();
              final sides = col == 1 ? 5 : 6;
              for (var k = 0; k < sides; k++) {
                final a = k * 2 * math.pi / sides;
                final q = Offset(cx + 17 * math.cos(a), cy + 13 * math.sin(a));
                if (k == 0) {
                  top.moveTo(q.dx, q.dy);
                } else {
                  top.lineTo(q.dx, q.dy);
                }
              }
              top.close();
              if (stage == 2) {
                c.drawLine(
                  Offset(cx - 14, cy + 5),
                  Offset(cx - 14, cy + 42),
                  p
                    ..color = const Color(0xff586169)
                    ..strokeWidth = 2,
                );
                c.drawLine(
                  Offset(cx + 13, cy + 5),
                  Offset(cx + 13, cy + 42),
                  p,
                );
              }
              c.drawPath(
                top,
                p
                  ..style = PaintingStyle.fill
                  ..color = const Color(0xff929d9d),
              );
              c.drawPath(
                top,
                p
                  ..style = PaintingStyle.stroke
                  ..color = const Color(0xff414d58)
                  ..strokeWidth = 2,
              );
              p.style = PaintingStyle.fill;
            }
          }
        }
        label(c, ['熔岩冷却', '收缩开裂', '柱状岩石'][stage], Offset(x + 55, 148));
      }
    } else if (kind == 'gbr-interchange') {
      c.drawLine(
        const Offset(45, 55),
        const Offset(185, 55),
        p
          ..color = Colors.blue
          ..strokeWidth = 8,
      );
      c.drawLine(
        const Offset(185, 55),
        const Offset(310, 125),
        p
          ..color = AtlasPalette.orange
          ..strokeWidth = 8,
      );
      for (final (s, q) in const [
        ('甲站', Offset(45, 55)),
        ('乙站', Offset(185, 55)),
        ('丙站', Offset(310, 125)),
      ]) {
        c.drawCircle(q, 11, p..color = AtlasPalette.navy);
        c.drawCircle(q, 6, p..color = Colors.white);
        label(c, s, q + const Offset(0, 17));
      }
    } else if (kind == 'gbr-river-city') {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 360, 180),
        p..color = const Color(0xffcfdcb8),
      );
      final r = Path()
        ..moveTo(130, 0)
        ..cubicTo(90, 70, 240, 105, 170, 180)
        ..lineTo(250, 180)
        ..cubicTo(310, 100, 180, 70, 220, 0)
        ..close();
      c.drawPath(r, p..color = const Color(0xff72b6dc));
      c.drawLine(
        const Offset(80, 85),
        const Offset(295, 85),
        p
          ..color = Colors.white
          ..strokeWidth = 21,
      );
      c.drawLine(
        const Offset(80, 85),
        const Offset(295, 85),
        p
          ..color = AtlasPalette.navy
          ..strokeWidth = 4,
      );
      label(c, '一岸', const Offset(45, 120));
      label(c, '另一岸', const Offset(306, 120));
      label(c, '桥', const Offset(180, 60));
    } else {
      for (var i = 0; i < 5; i++) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(170 + i * 8, 90 - i * 3),
            width: 290 - i * 46,
            height: 155 - i * 25,
          ),
          p
            ..style = PaintingStyle.stroke
            ..color = const Color(0xff698c62)
            ..strokeWidth = 2,
        );
      }
      label(c, '等高线', const Offset(290, 155));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_GbrPainter old) => old.kind != kind;
}
