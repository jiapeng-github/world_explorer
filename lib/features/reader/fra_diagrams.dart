import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Authored relationship diagrams. No quantitative measurements are invented.
class FraDiagram extends StatefulWidget {
  const FraDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<FraDiagram> createState() => _FraDiagramState();
}

class _FraDiagramState extends State<FraDiagram> {
  int step = 0;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void play() {
    timer?.cancel();
    setState(() => step = 1);
    timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => step = (step + 1) % 5);
      if (step == 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final (title, labels, caption) = switch (k) {
      'fra-tides' => ('同一海湾，不同潮位', ['低潮', '高潮'], '固定地形与视角，只改变水位。示意不提供现场潮时。'),
      'fra-river-city' => ('河流穿过城市', ['左岸', '桥', '右岸'], '桥连接两岸；此图不是巴黎导航图。'),
      'fra-transfer' => (
        '在共同站点换乘',
        ['甲站', '乙站 · 换乘', '丙站'],
        '蓝线甲—乙，橙线乙—丙。原创虚构线路，不按距离比例。',
      ),
      'fra-fermentation' => (
        '面团里的变化',
        ['揉合', '发酵产气', '烘烤成形'],
        '面团结构留住部分气体。过程不按真实时间比例。',
      ),
      'fra-triangles' => (
        '杆件组成三角形',
        ['支脚', '斜杆', '三角构件'],
        '找重复的三角形；此图不代替真实工程计算。',
      ),
      'fra-glacier' => (
        '从积雪到缓慢流动',
        ['积累', '成冰', '缓慢流动'],
        '箭头表示冰的流动。末端退缩不等于冰向山顶倒流。',
      ),
      'fra-volcano' => (
        '从地下到地表',
        ['岩浆', '熔岩', '凝固成岩'],
        '不同火山活动方式不同。这不是实时喷发预报。',
      ),
      'fra-rhythm' => (
        '轮流回应四拍',
        ['1', '2', '3', '4'],
        '四拍之间间隔相同。原创练习，关闭声音也能完成。',
      ),
      'fra-names' => (
        '同一地点，两种名称',
        ['Strasbourg · 法语', 'Straßburg · 德语'],
        '都指斯特拉斯堡。德语名称不等于阿尔萨斯语名称。',
      ),
      'fra-market' => (
        '读懂标签字段',
        ['①名称：苹果', '②单位：千克', '③产地：法国'],
        '原创练习标签，不代表实拍商品的真实标签或现价。',
      ),
      'fra-cheese' => (
        '从说明里找原料',
        ['产品名称', '原料：牛奶', '制作资料'],
        '原创字段练习，不把照片颜色当成原料证据。',
      ),
      _ => (
        '从法律到参与',
        ['1944 · 法规', '1945 · 选举'],
        '两个时间节点，不按时间长度比例。适用范围须查具体资料。',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff0f5fa),
        border: Border.all(color: AtlasPalette.line),
        borderRadius: BorderRadius.circular(16),
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
          if (k == 'fra-tides')
            Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          labels[i],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(
                          height: 116,
                          child: CustomPaint(
                            painter: _FranceScience(k, i),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else if ({
            'fra-names',
            'fra-market',
            'fra-cheese',
            'fra-votes',
          }.contains(k)) ...[
            for (final label in labels)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ] else if (k == 'fra-rhythm') ...[
            Row(
              children: [
                for (var i = 1; i <= 4; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: step == i ? AtlasPalette.orange : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$i',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: widget.interactive ? play : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('跟着拍四下'),
            ),
          ] else ...[
            SizedBox(
              height: 140,
              child: CustomPaint(
                painter: _FranceScience(k, step),
                child: const SizedBox.expand(),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 6,
              children: [
                for (var i = 0; i < labels.length; i++)
                  ActionChip(
                    label: Text(labels[i]),
                    backgroundColor: step == i
                        ? AtlasPalette.orangeSoft
                        : Colors.white,
                    onPressed: widget.interactive
                        ? () => setState(() => step = i)
                        : null,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AtlasPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FranceScience extends CustomPainter {
  const _FranceScience(this.kind, this.step);
  final String kind;
  final int step;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(size.width / 300, size.height / 140);
    final fill = Paint()..color = const Color(0xffcfe7f5),
        line = Paint()
          ..color = AtlasPalette.navy
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
    void path(List<Offset> pts, Color color, {bool close = true}) {
      final p = Path()..addPolygon(pts, close);
      c.drawPath(p, Paint()..color = color);
    }

    void arrow(Offset a, Offset b) {
      c.drawLine(a, b, line);
      final d = (b - a) / ((b - a).distance);
      final n = Offset(-d.dy, d.dx);
      c.drawLine(b, b - d * 10 + n * 5, line);
      c.drawLine(b, b - d * 10 - n * 5, line);
    }

    if (kind == 'fra-tides') {
      c.drawRect(const Rect.fromLTWH(5, 10, 290, 125), fill);
      path([
        const Offset(5, 135),
        const Offset(5, 107),
        const Offset(115, 100),
        const Offset(145, 43),
        const Offset(173, 100),
        const Offset(295, 107),
        const Offset(295, 135),
      ], const Color(0xffb7a483));
      c.drawRect(
        Rect.fromLTRB(5, step == 0 ? 119 : 97, 295, 135),
        Paint()..color = const Color(0xff67b7dc),
      );
      c.drawRect(
        const Rect.fromLTWH(134, 45, 25, 34),
        Paint()..color = const Color(0xff596b76),
      );
      path([
        const Offset(135, 45),
        const Offset(146, 25),
        const Offset(158, 45),
      ], AtlasPalette.navy);
      c.drawLine(const Offset(146, 25), const Offset(146, 12), line);
    } else if (kind == 'fra-transfer') {
      c.drawLine(
        const Offset(35, 80),
        const Offset(150, 80),
        Paint()
          ..color = const Color(0xff258bb6)
          ..strokeWidth = 9,
      );
      c.drawLine(
        const Offset(150, 80),
        const Offset(260, 35),
        Paint()
          ..color = AtlasPalette.orange
          ..strokeWidth = 9,
      );
      for (final p in [
        const Offset(35, 80),
        const Offset(150, 80),
        const Offset(260, 35),
      ]) {
        c.drawCircle(p, 9, Paint()..color = Colors.white);
        c.drawCircle(p, 9, line);
      }
    } else if (kind == 'fra-river-city') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(115, 5, 65, 130),
          const Radius.circular(25),
        ),
        fill..color = const Color(0xff72b7d4),
      );
      c.drawRect(
        const Rect.fromLTWH(55, 62, 190, 19),
        Paint()..color = const Color(0xffad987a),
      );
      arrow(const Offset(146, 95), const Offset(146, 125));
    } else if (kind == 'fra-glacier') {
      path([
        const Offset(0, 130),
        const Offset(70, 12),
        const Offset(130, 60),
        const Offset(165, 40),
        const Offset(230, 115),
        const Offset(300, 133),
      ], const Color(0xffb6c8ce));
      path([
        const Offset(70, 13),
        const Offset(46, 55),
        const Offset(78, 43),
        const Offset(100, 56),
      ], Colors.white);
      path([
        const Offset(80, 48),
        const Offset(106, 85),
        const Offset(215, 128),
        const Offset(156, 125),
        const Offset(73, 74),
      ], const Color(0xffe5f5ff));
      arrow(const Offset(89, 64), const Offset(160, 107));
    } else if (kind == 'fra-triangles') {
      for (final points in [
        [const Offset(50, 130), const Offset(150, 10), const Offset(250, 130)],
        [const Offset(80, 95), const Offset(220, 95)],
        [const Offset(110, 60), const Offset(190, 60)],
        [const Offset(80, 95), const Offset(190, 60)],
        [const Offset(110, 60), const Offset(220, 95)],
        [const Offset(50, 130), const Offset(220, 95)],
        [const Offset(80, 95), const Offset(250, 130)],
      ]) {
        final p = Path()..addPolygon(points, false);
        c.drawPath(p, line);
      }
    } else if (kind == 'fra-fermentation') {
      for (var i = 0; i < 3; i++) {
        final x = 48 + i * 100.0;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, 87),
            width: 70,
            height: 40 + i * 15,
          ),
          Paint()
            ..color = i == 2
                ? const Color(0xffc8904f)
                : const Color(0xfff1d7a4),
        );
        for (var j = 0; j < (i + 1) * 3; j++) {
          c.drawCircle(
            Offset(x - 20 + (j % 3) * 19, 77 + (j ~/ 3) * 11),
            3,
            Paint()..color = const Color(0xffa77a43),
          );
        }
        if (i < 2) arrow(Offset(x + 39, 53), Offset(x + 62, 53));
      }
    } else {
      path([
        const Offset(0, 128),
        const Offset(125, 35),
        const Offset(172, 35),
        const Offset(300, 128),
      ], const Color(0xff9b978f));
      c.drawOval(
        const Rect.fromLTWH(104, 101, 85, 30),
        Paint()..color = AtlasPalette.orange,
      );
      c.drawLine(
        const Offset(148, 110),
        const Offset(148, 42),
        Paint()
          ..color = AtlasPalette.orange
          ..strokeWidth = 13,
      );
      path([
        const Offset(145, 40),
        const Offset(175, 35),
        const Offset(243, 106),
        const Offset(226, 112),
      ], const Color(0xffd6743d));
      arrow(const Offset(75, 82), const Offset(109, 58));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_FranceScience old) =>
      kind != old.kind || step != old.step;
}
