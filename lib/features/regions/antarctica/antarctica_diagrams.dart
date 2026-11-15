import 'dart:math' as math;

import 'package:flutter/material.dart';

class AntDiagram extends StatefulWidget {
  const AntDiagram(this.kind, {super.key});
  final String kind;
  @override
  State<AntDiagram> createState() => _AntDiagramState();
}

class _AntDiagramState extends State<AntDiagram> {
  int step = 0;
  bool december = true;
  String location = '南极点';
  @override
  Widget build(BuildContext c) {
    final kind = widget.kind.replaceFirst('antarctica-', '');
    final sequences = <String, List<(String, String)>>{
      'poles': [('南极洲', '大陆周围环绕海洋，厚冰覆盖许多陆地。'), ('北极地区', '中心是海洋，周围分布大陆。')],
      'snow': [
        ('积累', '没有全部融化的雪逐渐积累。'),
        ('压实', '上方的重量让雪粒间的空隙减少。'),
        ('形成与运动', '冰体形成，并在重力作用下缓慢运动。'),
      ],
      'core': [
        ('雪粒间的空气', '雪中原本有连通的空隙。'),
        ('气泡被封闭', '压实过程使一部分空气留在冰里。'),
        ('测量与理解', '气泡提供过去空气的线索；气体和冰的年龄可能不同。'),
      ],
      'team': [
        ('观测与记录', '科学人员提出问题、测量并整理资料。'),
        ('生活与设备', '厨师、医务和维修人员支持团队。'),
        ('补给与合作', '运输、通信与资料分享把不同工作联系起来。'),
      ],
      'level': [
        ('陆地冰', '从陆地进入海洋的冰与水增加海洋中的水。'),
        ('漂浮的冰', '已经漂在水中的冰与陆地冰的直接影响不同。'),
        ('冰架的联系', '冰架还可能影响后方冰流，存在间接作用。'),
      ],
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffe5f2f8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kind == 'ice') ...[
            const Text(
              '冰盖、冰架与海冰',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: '左侧岩石上的冰盖连接漂浮在海水上的冰架；右侧薄海冰由海水冻结形成。',
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(painter: _IcePainter()),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(['冰盖', '冰架', '海冰'][i]),
                    selected: step == i,
                    onSelected: (_) => setState(() => step = i),
                  ),
              ],
            ),
            Text(
              [
                '冰盖覆盖大陆的大片区域，下面有陆地。',
                '冰架与陆地冰相连，延伸到海上漂浮。',
                '海冰主要由海水冻结形成，不是陆地冰架的另一种叫法。',
              ][step],
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
          ] else if (kind == 'light') ...[
            const Text(
              '同一地轴，不同季节',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final p in ['南极点', '中山站'])
                  ChoiceChip(
                    label: Text(p),
                    selected: location == p,
                    onSelected: (_) => setState(() => location = p),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => december = true),
                    child: Text('12月${december ? ' ✓' : ''}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => december = false),
                    child: Text('6月${december ? '' : ' ✓'}'),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(painter: _LightPainter(december, location)),
            ),
            Text(
              location == '南极点'
                  ? (december ? '南极点：12月处在持续白昼中。' : '南极点：6月处在持续黑夜中。')
                  : '中山站位于南极圈以南，但纬度低于南极点，连续白昼与黑夜的时段较短。',
              style: const TextStyle(fontSize: 17, height: 1.6),
            ),
            const Text('地球仍在自转；准确起止日期还与定义和观测条件有关。'),
          ] else if (kind == 'food') ...[
            const Text(
              '一只小磷虾，连着谁？',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              width: double.infinity,
              child: CustomPaint(painter: _FoodPainter(step)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(['→ 阿德利企鹅', '→ 座头鲸', '→ 食蟹海豹'][i]),
                    selected: step == i,
                    onSelected: (_) => setState(() => step = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [
                '阿德利企鹅可以取食磷虾，也会吃其他食物。',
                '座头鲸是须鲸，磷虾是它可能取食的食物之一。',
                '食蟹海豹的名字带有“蟹”，食物却与磷虾有密切关系。',
              ][step],
            ),
            const Text('箭头表示：食物 → 吃它的动物。这里只展示部分关系。'),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < (sequences[kind]?.length ?? 0); i++)
                  ChoiceChip(
                    label: Text(sequences[kind]![i].$1),
                    selected: step == i,
                    onSelected: (_) => setState(() => step = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(painter: _ProcessPainter(kind, step)),
            ),
            const SizedBox(height: 16),
            Text(
              sequences[kind]?[step].$2 ?? '',
              style: const TextStyle(fontSize: 19, height: 1.7),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '原创原理示意 · 不按比例',
            style: TextStyle(fontSize: 12, color: Color(0xff53677d)),
          ),
        ],
      ),
    );
  }
}

class _IcePainter extends CustomPainter {
  const _IcePainter();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Rect.fromLTWH(0, 90, s.width, 100),
      Paint()..color = const Color(0xff529dbf),
    );
    final ground = Path()
      ..moveTo(0, 50)
      ..lineTo(s.width * .42, 135)
      ..lineTo(s.width, 180)
      ..lineTo(s.width, 190)
      ..lineTo(0, 190)
      ..close();
    c.drawPath(ground, Paint()..color = const Color(0xffa6927b));
    final ice = Path()
      ..moveTo(0, 15)
      ..lineTo(s.width * .4, 65)
      ..lineTo(s.width * .72, 75)
      ..lineTo(s.width * .72, 120)
      ..lineTo(s.width * .4, 125)
      ..lineTo(0, 50)
      ..close();
    c.drawPath(ice, Paint()..color = const Color(0xffd5f4ff));
    c.drawRect(
      Rect.fromLTWH(s.width * .82, 87, s.width * .15, 9),
      Paint()..color = Colors.white,
    );
    label(c, '冰盖', const Offset(8, 10));
    label(c, '冰架', Offset(s.width * .5, 40));
    label(c, '海冰', Offset(s.width * .8, 60));
    label(c, '海水', Offset(s.width * .55, 145));
    label(c, '陆地', const Offset(8, 140));
  }

  @override
  bool shouldRepaint(covariant _IcePainter old) => false;
}

void label(Canvas c, String s, Offset p) {
  final t = TextPainter(
    text: TextSpan(
      text: s,
      style: const TextStyle(
        color: Color(0xff12395b),
        fontFamily: 'NotoSansSC',
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  t.paint(c, p);
}

class _LightPainter extends CustomPainter {
  _LightPainter(this.december, this.location);
  final String location;
  final bool december;
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero), r = math.min(70.0, s.width * .24);
    c.drawCircle(center, r, Paint()..color = const Color(0xff12395b));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    c.drawRect(
      Rect.fromLTWH(
        december ? center.dx - r : center.dx,
        center.dy - r,
        r,
        r * 2,
      ),
      Paint()..color = const Color(0xff91d3ed),
    );
    c.restore();
    final axis = Offset(
      math.sin(23.44 * math.pi / 180),
      -math.cos(23.44 * math.pi / 180),
    );
    c.drawLine(
      center - axis * (r + 20),
      center + axis * (r + 20),
      Paint()
        ..color = const Color(0xff12395b)
        ..strokeWidth = 2,
    );
    c.drawCircle(
      center - axis * r,
      5,
      Paint()..color = const Color(0xffff9a3d),
    );
    for (final y in [-35.0, 0.0, 35.0]) {
      final from = Offset(december ? 8 : s.width - 8, center.dy + y),
          to = Offset(
            december ? center.dx - r - 8 : center.dx + r + 8,
            center.dy + y,
          );
      final paint = Paint()
        ..color = const Color(0xffffab35)
        ..strokeWidth = 2;
      c.drawLine(from, to, paint);
      c.drawLine(to, to + Offset(december ? -6 : 6, -4), paint);
      c.drawLine(to, to + Offset(december ? -6 : 6, 4), paint);
    }
    label(c, '南极点', center - axis * r + const Offset(7, 2));
    if (location == '中山站') {
      final q = center + Offset(-r * .65, r * .7);
      c.drawCircle(q, 5, Paint()..color = const Color(0xffff9a3d));
      label(c, '中山站（纬度示意）', Offset(4, s.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _LightPainter old) =>
      december != old.december || location != old.location;
}

class _FoodPainter extends CustomPainter {
  _FoodPainter(this.selected);
  final int selected;
  @override
  void paint(Canvas c, Size s) {
    const navy = Color(0xff12395b), orange = Color(0xffff9a3d);
    void arrow(Offset a, Offset b, bool active) {
      final p = Paint()
        ..color = active ? orange : navy
        ..strokeWidth = active ? 3 : 1.5;
      c.drawLine(a, b, p);
      final d = (b - a) / (b - a).distance;
      final side = Offset(-d.dy, d.dx);
      c.drawLine(b, b - d * 8 + side * 4, p);
      c.drawLine(b, b - d * 8 - side * 4, p);
    }

    void node(String text, Offset at, double width) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: at, width: width, height: 40),
          const Radius.circular(12),
        ),
        Paint()..color = Colors.white,
      );
      label(c, text, at + Offset(-width / 2 + 10, -10));
    }

    final middle = s.width / 2;
    node('浮游植物', Offset(middle, 24), 100);
    arrow(Offset(middle, 46), Offset(middle, 72), true);
    node('南极磷虾', Offset(middle, 96), 100);
    for (var i = 0; i < 3; i++) {
      final x = s.width * (i + .5) / 3;
      arrow(Offset(middle, 118), Offset(x, 154), selected == i);
      node(['企鹅', '须鲸', '海豹'][i], Offset(x, 180), s.width / 3 - 6);
    }
  }

  @override
  bool shouldRepaint(covariant _FoodPainter old) => selected != old.selected;
}

class _ProcessPainter extends CustomPainter {
  _ProcessPainter(this.kind, this.step);
  final String kind;
  final int step;
  @override
  void paint(Canvas c, Size s) {
    const navy = Color(0xff12395b),
        ice = Color(0xffb6dfef),
        water = Color(0xff529dbf),
        ground = Color(0xffb5a18b);
    void rect(double x, double y, double w, double h, Color color) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(8),
        ),
        Paint()..color = color,
      );
    }

    if (kind == 'poles') {
      final r = math.min(s.width / 5, 65.0);
      for (var i = 0; i < 2; i++) {
        final center = Offset(s.width * (i == 0 ? .25 : .75), 85);
        c.drawCircle(center, r, Paint()..color = i == 0 ? water : ground);
        c.drawCircle(
          center,
          r * .7,
          Paint()..color = i == 0 ? Colors.white : water,
        );
        label(c, i == 0 ? '大陆' : '海洋', center - const Offset(15, 8));
        label(c, i == 0 ? '南极洲' : '北极地区', Offset(center.dx - 30, 160));
      }
    } else if (kind == 'snow' || kind == 'core') {
      final x = s.width * .22, w = s.width * .56;
      for (var i = 0; i < 4; i++) {
        rect(x, 12 + i * 35, w, 33, Color.lerp(Colors.white, ice, i / 3)!);
        for (var k = 0; k < 8; k++) {
          final p = Offset(x + 12 + k * (w - 24) / 7, 26 + i * 35);
          c.drawCircle(
            p,
            i < 2 ? 3.5 : 2,
            Paint()..color = i < 2 ? const Color(0xff8cb3c6) : Colors.white,
          );
        }
      }
      label(
        c,
        kind == 'core' ? '冰芯中的层与气泡' : '松雪 → 压实 → 冰',
        const Offset(4, 165),
      );
      if (kind == 'core') {
        c.drawLine(
          Offset(x + w + 12, 10),
          Offset(x + w + 12, 148),
          Paint()
            ..color = navy
            ..strokeWidth = 3,
        );
        label(c, '深', Offset(x + w + 18, 126));
      }
    } else if (kind == 'level') {
      final w = (s.width - 14) / 2;
      for (var i = 0; i < 2; i++) {
        rect(i * (w + 14), 60, w, 88, water);
        if (i == 0) {
          rect(0, 88, w * .55, 60, ground);
          rect(8, 45, w * .4, 42, Colors.white);
        } else {
          rect(w + 28, 45, w * .5, 38, Colors.white);
        }
        label(c, i == 0 ? '原先在陆地' : '原先在海上', Offset(i * (w + 14) + 4, 165));
      }
    } else {
      for (var i = 0; i < 3; i++) {
        final x = s.width * (i + .5) / 3;
        c.drawCircle(
          Offset(x, 75),
          26,
          Paint()..color = i == step ? const Color(0xffffbd7a) : Colors.white,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: ['1', '2', '3'][i],
            style: const TextStyle(
              color: navy,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(x - 8, 58));
        label(c, ['观测', '记录', '共享'][i], Offset(x - 15, 118));
        if (i < 2) {
          c.drawLine(
            Offset(x + 28, 75),
            Offset(x + s.width / 3 - 28, 75),
            Paint()
              ..color = navy
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProcessPainter old) =>
      kind != old.kind || step != old.step;
}

/// Formation-based illustrations: a field photograph cannot establish ice origin.
class AntIceSample extends StatelessWidget {
  const AntIceSample(this.kind, {super.key});
  final String kind;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$kind 原创关系示意，不按比例',
    child: SizedBox(
      width: 110,
      height: 104,
      child: CustomPaint(painter: _IceSamplePainter(kind)),
    ),
  );
}

class _IceSamplePainter extends CustomPainter {
  const _IceSamplePainter(this.kind);
  final String kind;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xffa8d7ed));
    c.drawRect(
      Rect.fromLTWH(0, 58, s.width, 46),
      Paint()..color = const Color(0xff287aa7),
    );
    if (kind == '冰盖') {
      c.drawPath(
        Path()
          ..moveTo(0, 81)
          ..quadraticBezierTo(52, 39, 110, 80)
          ..lineTo(110, 104)
          ..lineTo(0, 104)
          ..close(),
        Paint()..color = const Color(0xffaa9479),
      );
      c.drawPath(
        Path()
          ..moveTo(0, 66)
          ..quadraticBezierTo(52, 4, 110, 65)
          ..lineTo(110, 80)
          ..quadraticBezierTo(52, 39, 0, 81)
          ..close(),
        Paint()..color = Colors.white,
      );
    } else if (kind == '冰架') {
      c.drawPath(
        Path()
          ..moveTo(0, 58)
          ..lineTo(34, 77)
          ..lineTo(48, 104)
          ..lineTo(0, 104)
          ..close(),
        Paint()..color = const Color(0xffaa9479),
      );
      c.drawPath(
        Path()
          ..moveTo(0, 26)
          ..lineTo(34, 43)
          ..lineTo(84, 46)
          ..lineTo(84, 72)
          ..lineTo(34, 77)
          ..lineTo(0, 58)
          ..close(),
        Paint()..color = Colors.white,
      );
    } else {
      for (final r in [
        const Rect.fromLTWH(4, 55, 27, 9),
        const Rect.fromLTWH(36, 57, 32, 8),
        const Rect.fromLTWH(76, 54, 26, 10),
      ]) {
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)),
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IceSamplePainter old) => kind != old.kind;
}
