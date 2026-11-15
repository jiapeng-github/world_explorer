import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original explanatory drawings, never presented as measured geography.
class NorwayDiagram extends StatefulWidget {
  const NorwayDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<NorwayDiagram> createState() => _NorwayDiagramState();
}

class _NorwayDiagramState extends State<NorwayDiagram> {
  int step = 0;
  @override
  void didUpdateWidget(covariant NorwayDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) step = 0;
  }

  @override
  Widget build(BuildContext context) {
    final (title, labels, notes) = switch (widget.kind) {
      'norway-fjord' => (
        '冰川与峡湾',
        ['冰川侵蚀', '冰退后山谷', '海水进入'],
        ['流动的冰和碎石磨蚀岩石，谷地逐渐改变。', '冰退后，较深、较宽的谷地显露。', '低处谷地被海水占据，与海洋相连。'],
      ),
      'norway-climate' => (
        '环境不只由纬度决定',
        ['海洋', '山地', '内陆'],
        ['海洋与大气影响沿岸的热量和水汽。', '地形抬升与海拔会影响温度和降水。', '距离海洋与山脉位置共同影响环境。'],
      ),
      'norway-transfer' => (
        '在共同站点换乘',
        ['蓝线 · 甲站', '共同 · 乙站', '橙线 · 丙站'],
        ['从甲站出发，沿蓝线到乙站。', '乙站连接蓝线和橙线，是换乘站。', '换到橙线后，可以继续到丙站。'],
      ),
      'norway-lunch' => (
        '一份便当的组成',
        ['面包', '配料', '组合'],
        ['面包是便当的一种常见基础。', '配料可以多样，家庭与个人选择不同。', '这是组合示意，不是统一菜单或用量建议。'],
      ),
      'norway-cod' => (
        '从鳕鱼到干制品',
        ['原料与处理', '架上风干', '运输与餐桌'],
        ['具体产品有具体处理要求，鳕鱼不等于所有鱼。', 'stockfish通过风干制成，不等于盐渍鱼。', '加工、运输和销售连接不同地方。'],
      ),
      'norway-daylight' => (
        '午夜太阳从哪里来？',
        ['夏季示意', '冬季示意'],
        ['北端朝向太阳：高纬地点转一圈仍可留在受光侧。', '地轴方向大体不变：地球公转到另一侧，北端背向太阳。'],
      ),
      'norway-aurora' => (
        '极光的主要关系',
        ['太阳粒子', '地球磁场', '高层大气'],
        [
          '太阳与地球之间有空间环境的联系。',
          '磁场影响带电粒子的运动，不是直穿地球的光线。',
          '粒子与高层大气作用产生光；不是极昼，也不是冰雪反光。',
        ],
      ),
      _ => (
        '海冰中的生命联系',
        ['海冰环境', '海豹等动物', '北极熊'],
        [
          '海冰是海水冻结形成的环境，不同于陆地冰川。',
          '动物利用海冰与海洋的空间，形成生态联系。',
          '北极熊与海冰及猎物相联系，变化需长期研究。',
        ],
      ),
    };
    final current = step.clamp(0, labels.length - 1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffedf5fc),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AtlasPalette.navy,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: '$title。${notes[current]}',
            image: true,
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: 1.7,
                child: CustomPaint(
                  painter: _NorwayPainter(widget.kind, current),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(labels[i]),
                  selected: i == current,
                  onSelected: widget.interactive
                      ? (_) => setState(() => step = i)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes[current],
            style: const TextStyle(fontSize: 16, height: 1.65),
          ),
          const SizedBox(height: 7),
          Text(
            widget.kind == 'norway-transfer'
                ? '原创虚构线路 · 非实际班次与距离'
                : '原创关系示意 · 不按比例，不是历史实拍',
            style: const TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
          if (widget.kind == 'norway-daylight') ...[
            const SizedBox(height: 10),
            const Text(
              '奥斯陆：夏季白天长，仍有夜晚。\n特罗姆瑟：夏季有一段极昼。\n朗伊尔城：纬度更高，夏季极昼时段更长。',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 8),
            const Text(
              '不是整个挪威全年都有极昼。地形、折射与采用的定义影响实际观测。',
              style: TextStyle(fontSize: 13, color: AtlasPalette.navy),
            ),
          ],
        ],
      ),
    );
  }
}

class _NorwayPainter extends CustomPainter {
  _NorwayPainter(this.kind, this.step);
  final String kind;
  final int step;
  final navy = const Color(0xff12395b),
      blue = const Color(0xff268abe),
      orange = const Color(0xffff9a3d);
  void text(
    Canvas c,
    String value,
    Offset at, {
    double size = 14,
    Color? color,
    double width = 160,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color ?? navy,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: width);
    p.paint(c, at);
  }

  void line(Canvas c, Offset a, Offset b, Color color, {double width = 3}) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void arrow(Canvas c, Offset a, Offset b, Color color) {
    line(c, a, b, color);
    final v = (b - a) / ((b - a).distance);
    final n = Offset(-v.dy, v.dx);
    final p = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo((b - v * 9 + n * 4).dx, (b - v * 9 + n * 4).dy)
      ..lineTo((b - v * 9 - n * 4).dx, (b - v * 9 - n * 4).dy)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 340, s.height / 200);
    const w = 340.0, h = 200.0;
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
    if (kind == 'norway-daylight') {
      const center = Offset(165, 110), r = 73.0;
      final sun = Offset(step == 0 ? 315 : 25, 64);
      c.drawCircle(sun, 20, Paint()..color = orange);
      final earth = Path()..addOval(Rect.fromCircle(center: center, radius: r));
      c.save();
      c.clipPath(earth);
      c.drawCircle(center, r, Paint()..color = const Color(0xff153d62));
      c.drawRect(
        Rect.fromLTWH(step == 0 ? 165 : 92, 37, 73, 146),
        Paint()..color = const Color(0xff66b5c3),
      );
      // North points right in BOTH seasons; the Sun changes sides.
      final axis = Offset(
        math.sin(23.44 * math.pi / 180),
        -math.cos(23.44 * math.pi / 180),
      );
      final perpendicular = Offset(-axis.dy, axis.dx);
      const lat = 70.0;
      final track = Path();
      for (var i = 0; i <= 120; i++) {
        final t = i / 120 * 2 * math.pi;
        final p =
            center +
            axis * (r * math.sin(lat * math.pi / 180)) +
            perpendicular * (r * math.cos(lat * math.pi / 180) * math.cos(t));
        if (i == 0) {
          track.moveTo(p.dx, p.dy);
        } else {
          track.lineTo(p.dx, p.dy);
        }
      }
      c.drawPath(
        track,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final marker =
          center +
          axis * (r * math.sin(lat * math.pi / 180)) +
          perpendicular * (r * math.cos(lat * math.pi / 180) * .65);
      c.drawCircle(marker, 4, Paint()..color = orange);
      c.restore();
      line(c, center - axis * 88, center + axis * 88, navy, width: 2);
      text(c, '北极', center + axis * 89 + const Offset(-10, -12), size: 11);
      text(c, '地轴', const Offset(215, 27), size: 11);
      text(c, '70°N地点的日运动投影', const Offset(82, 182), size: 11, width: 230);
      for (final y in [91.0, 119.0, 147.0]) {
        arrow(
          c,
          Offset(step == 0 ? 325 : 15, y),
          Offset(step == 0 ? 248 : 82, y),
          orange,
        );
      }
      text(c, '平行阳光', Offset(step == 0 ? 260 : 4, 158), size: 10, width: 75);
    } else if (kind == 'norway-fjord') {
      final mountain = Path()
        ..moveTo(0, 165)
        ..lineTo(0, 45)
        ..lineTo(53, 10)
        ..lineTo(111, 93)
        ..quadraticBezierTo(170, 158, 227, 91)
        ..lineTo(289, 12)
        ..lineTo(340, 60)
        ..lineTo(340, 180)
        ..close();
      c.drawPath(mountain, Paint()..color = const Color(0xff77986e));
      final valley = Path()
        ..moveTo(80, 69)
        ..quadraticBezierTo(112, 166, 170, 169)
        ..quadraticBezierTo(225, 168, 265, 65)
        ..lineTo(224, 183)
        ..lineTo(114, 183)
        ..close();
      c.drawPath(valley, Paint()..color = const Color(0xffb8aba0));
      if (step == 0) {
        final ice = Path()
          ..moveTo(106, 95)
          ..quadraticBezierTo(167, 138, 236, 92)
          ..lineTo(218, 166)
          ..quadraticBezierTo(165, 192, 119, 164)
          ..close();
        c.drawPath(ice, Paint()..color = const Color(0xffbce8ee));
        arrow(c, const Offset(175, 110), const Offset(166, 158), blue);
      } else if (step == 2) {
        final sea = Path()
          ..moveTo(104, 131)
          ..lineTo(238, 131)
          ..lineTo(220, 181)
          ..lineTo(117, 181)
          ..close();
        c.drawPath(sea, Paint()..color = blue);
        arrow(c, const Offset(170, 195), const Offset(170, 149), Colors.white);
      }
      text(
        c,
        step == 0
            ? '流动的冰与碎石'
            : step == 1
            ? '冰退后显露的谷地'
            : '海水与海洋连通',
        const Offset(90, 4),
        size: 13,
        width: 190,
      );
    } else if (kind == 'norway-transfer') {
      line(c, const Offset(30, 80), const Offset(168, 80), blue, width: 8);
      line(c, const Offset(168, 80), const Offset(305, 145), orange, width: 8);
      final positions = [
        const Offset(30, 80),
        const Offset(168, 80),
        const Offset(305, 145),
      ];
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
          positions[i],
          i == step ? 13 : 9,
          Paint()..color = i == step ? orange : Colors.white,
        );
        c.drawCircle(
          positions[i],
          9,
          Paint()
            ..color = navy
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        text(
          c,
          ['甲站', '乙站', '丙站'][i],
          positions[i] + const Offset(-16, 18),
          size: 13,
          width: 55,
        );
      }
      text(c, '蓝线', const Offset(60, 40));
      text(c, '橙线', const Offset(241, 86));
    } else if (kind == 'norway-aurora') {
      c.drawCircle(const Offset(38, 94), 24, Paint()..color = orange);
      c.drawCircle(const Offset(270, 109), 43, Paint()..color = blue);
      final field = Path()
        ..moveTo(267, 57)
        ..cubicTo(170, 1, 142, 177, 264, 164);
      c.drawPath(
        field,
        Paint()
          ..color = navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      arrow(c, const Offset(68, 78), const Offset(126, 78), orange);
      arrow(c, const Offset(183, 47), const Offset(246, 67), orange);
      c.drawArc(
        Rect.fromCircle(center: const Offset(270, 109), radius: 49),
        3.9,
        1,
        false,
        Paint()
          ..color = const Color(0xff49ba93)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
      text(c, '太阳', const Offset(21, 133));
      text(c, '磁场影响运动', const Offset(112, 168), size: 12);
      text(c, '高层大气发光', const Offset(225, 17), size: 12, width: 110);
    } else {
      final entries = switch (kind) {
        'norway-climate' => [
          (Icons.waves, '海洋', '热量与水汽'),
          (Icons.landscape, '山地', '海拔与抬升'),
          (Icons.terrain, '内陆', '海陆位置'),
        ],
        'norway-lunch' => [
          (Icons.bakery_dining, '面包', '一种基础'),
          (Icons.eco, '配料', '多样选择'),
          (Icons.lunch_dining, '便当', '不同组合'),
        ],
        'norway-cod' => [
          (Icons.set_meal, '鳕鱼', '原料与处理'),
          (Icons.air, '风干', '不同于盐渍'),
          (Icons.local_shipping, '运输', '连接餐桌'),
        ],
        _ => [
          (Icons.ac_unit, '海冰', '生活空间'),
          (Icons.water, '海洋动物', '食物联系'),
          (Icons.pets, '北极熊', '依赖环境'),
        ],
      };
      for (var i = 0; i < 3; i++) {
        final x = 10 + i * 112.0;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 29, 99, 132),
            const Radius.circular(12),
          ),
          Paint()
            ..color = i == step
                ? const Color(0xffffead2)
                : const Color(0xffedf5fc),
        );
        final icon = entries[i].$1;
        final p = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              fontSize: 38,
              color: i == step ? orange : blue,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        p.paint(c, Offset(x + 30, 45));
        text(c, entries[i].$2, Offset(x + 18, 95), size: 17, width: 83);
        text(c, entries[i].$3, Offset(x + 7, 127), size: 11, width: 88);
        if (i < 2) arrow(c, Offset(x + 100, 92), Offset(x + 110, 92), orange);
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _NorwayPainter old) =>
      old.kind != kind || old.step != step;
}
