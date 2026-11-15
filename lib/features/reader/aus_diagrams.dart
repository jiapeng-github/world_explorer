import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original teaching diagrams. These explain relationships, not measurements.
class AusDiagram extends StatefulWidget {
  const AusDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<AusDiagram> createState() => _AusDiagramState();
}

class _AusDiagramState extends State<AusDiagram> {
  int selected = 0;
  @override
  void didUpdateWidget(AusDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final steps = switch (widget.kind) {
      'aus-coral' => const [
        ('珊瑚虫', Icons.filter_vintage_outlined, '珊瑚虫是动物，有触手，能够捕获食物。不是海草。'),
        ('群体', Icons.hub_outlined, '许多珊瑚虫连接生活，形成群体。群体的外形不代表一种植物。'),
        ('珊瑚礁', Icons.waves, '造礁珊瑚的骨骼等材料经过长期积累，参与形成珊瑚礁。不是一只珊瑚虫瞬间变成整座礁。'),
      ],
      'aus-seasons' => const [
        ('地轴倾斜', Icons.public, '地球自转轴相对公转轨道面倾斜，这是季节形成的重要原因。'),
        ('南北半球', Icons.swap_vert, '一年中，南北半球获得阳光的角度和白昼长度变化不同，季节大致相反。'),
        (
          '当地气候',
          Icons.wb_cloudy_outlined,
          '澳大利亚不同地区的季节表现不同，北部热带地区常以湿季和干季描述。不能用一个城市代表全国。',
        ),
      ],
      'aus-coast-erosion' => const [
        ('岩石海岸', Icons.landscape_outlined, '先看岩石、裂缝与海水的位置。照片中的形状是观察线索。'),
        ('长期变化', Icons.water, '波浪作用与风化等过程会逐渐改变海岸，不同岩石抵抗变化的能力不同。'),
        (
          '查证过程',
          Icons.history,
          '海蚀柱等形态需要结合地质资料理解。单张照片不能计算侵蚀速度，也不能证明所有海岸按同一顺序变化。',
        ),
      ],
      'aus-tram-transfer' => const [
        ('甲站', Icons.tram, '蓝线从甲站连接到乙站。先确认站名与方向。'),
        ('乙站换乘', Icons.alt_route, '乙站同时连接蓝线和橙线，从甲到丙在这里换乘。'),
        ('丙站', Icons.flag_outlined, '沿橙线到达丙站。原创练习，不是真实交通线路。'),
      ],
      'aus-food-label' => const [
        ('名称', Icons.apple, '名称：苹果。回答这是什么食品。'),
        ('单位', Icons.scale, '单位：千克。回答怎样计量。'),
        ('产地', Icons.place_outlined, '产地：澳大利亚。回答练习标签标注的来源。'),
      ],
      'aus-wheat-bread' => const [
        ('籽粒与面粉', Icons.grass, '小麦籽粒经过加工成为面粉。'),
        ('面团', Icons.bakery_dining, '面粉与水等配料制成面团；配方各有不同。'),
        ('面包', Icons.breakfast_dining, '烘焙等步骤将面团制成面包。简化流程并非每款产品的生产记录。'),
      ],
      'aus-kangaroo-pouch' => const [
        ('出生', Icons.child_care, '袋鼠幼崽出生时发育程度较低。'),
        ('袋中发育', Icons.favorite_outline, '幼崽在育儿袋中继续发育和吸乳。'),
        ('逐渐成长', Icons.pets, '逐渐能够在袋外活动。阶段示意不表示某张照片中幼崽的准确年龄。'),
      ],
      'aus-platypus' => const [
        ('嘴部', Icons.sensors, '嘴部的感觉能力帮助在水中寻找食物。外形像鸭嘴，不意味着属于鸟类。'),
        ('水中活动', Icons.water, '身体与肢体配合在水中活动。示意不表示真实尺寸。'),
        ('哺乳动物', Icons.child_care, '鸭嘴兽产卵，母体给幼体提供乳汁，属于单孔类哺乳动物。'),
      ],
      _ => const <(String, IconData, String)>[],
    };
    if (steps.isEmpty) return const SizedBox.shrink();
    final title = switch (widget.kind) {
      'aus-coral' => '海底的小动物，也能参与建造大家园',
      'aus-seasons' => '季节与阳光的关系',
      'aus-coast-erosion' => '海岸怎样改变',
      'aus-tram-transfer' => '甲 → 乙 → 丙：找到换乘点',
      'aus-food-label' => '一张标签，三个不同的问题',
      'aus-wheat-bread' => '从籽粒到面包',
      'aus-kangaroo-pouch' => '认识幼崽的成长阶段',
      _ => '从身体结构认识鸭嘴兽',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtlasPalette.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtlasPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '原创关系示意 · 不按时间或大小比例',
            style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, step) in steps.indexed)
                ChoiceChip(
                  avatar: Icon(step.$2, size: 20),
                  label: Text('${i + 1} ${step.$1}'),
                  selected: selected == i,
                  onSelected: widget.interactive
                      ? (_) => setState(() => selected = i)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: SizedBox(
              height: 132,
              child: CustomPaint(
                painter: _AusTeachingPainter(widget.kind, selected),
                child: widget.kind == 'aus-food-label'
                    ? Center(
                        child: Text(
                          const ['名称：苹果', '单位：千克', '产地：澳大利亚'][selected],
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : widget.kind == 'aus-tram-transfer'
                    ? const Align(
                        alignment: Alignment.bottomCenter,
                        child: Text('甲站                 乙站                 丙站'),
                      )
                    : widget.kind == 'aus-wheat-bread' ||
                          widget.kind == 'aus-kangaroo-pouch'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final (i, step) in steps.indexed)
                            Icon(
                              step.$2,
                              size: 45,
                              color: i == selected
                                  ? AtlasPalette.orange
                                  : AtlasPalette.navy,
                            ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              steps[selected].$3,
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
          ),
          if (!widget.interactive) ...[
            const SizedBox(height: 12),
            for (final step in steps.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${step.$1}：${step.$3}'),
              ),
          ],
        ],
      ),
    );
  }
}

class _AusTeachingPainter extends CustomPainter {
  _AusTeachingPainter(this.kind, this.step);
  final String kind;
  final int step;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 300, size.height / 132);
    final navy = Paint()..color = AtlasPalette.navy;
    final orange = Paint()..color = AtlasPalette.orange;
    final blue = Paint()..color = const Color(0xff81c6d7);
    final line = Paint()
      ..color = AtlasPalette.navy
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (kind == 'aus-coral') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 300, 132),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xffdceff2),
      );
      final count = step == 0
          ? 1
          : step == 1
          ? 4
          : 7;
      for (var i = 0; i < count; i++) {
        final x = count == 1 ? 150.0 : 35.0 + i * 230 / (count - 1),
            y = 68.0 + (i % 2) * 12;
        c.drawLine(
          Offset(x, 111),
          Offset(x, y),
          line
            ..color = const Color(0xffdc7352)
            ..strokeWidth = step == 2 ? 9 : 6,
        );
        c.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 20, height: 26),
          orange,
        );
        for (var n = 0; n < 5; n++) {
          final angle = math.pi + n * math.pi / 4;
          c.drawLine(
            Offset(x, y - 7),
            Offset(x + math.cos(angle) * 22, y - 7 + math.sin(angle) * 22),
            line..strokeWidth = 3,
          );
        }
        c.drawCircle(Offset(x, y - 3), 3, navy);
      }
      if (step == 2) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 109, 280, 17),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xffcfaa8b),
        );
      }
    } else if (kind == 'aus-tram-transfer') {
      c.drawLine(
        const Offset(40, 60),
        const Offset(150, 60),
        line
          ..color = AtlasPalette.navy
          ..strokeWidth = 8,
      );
      c.drawLine(
        const Offset(150, 60),
        const Offset(260, 60),
        line..color = AtlasPalette.orange,
      );
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
          Offset(40 + i * 110, 60),
          i == step ? 16 : 11,
          Paint()..color = Colors.white,
        );
        c.drawCircle(
          Offset(40 + i * 110, 60),
          i == step ? 16 : 11,
          line
            ..color = AtlasPalette.navy
            ..strokeWidth = 3,
        );
      }
    } else if (kind == 'aus-seasons') {
      c.drawCircle(const Offset(65, 66), 26, orange);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawLine(
          Offset(65 + math.cos(a) * 33, 66 + math.sin(a) * 33),
          Offset(65 + math.cos(a) * 42, 66 + math.sin(a) * 42),
          line
            ..color = AtlasPalette.orange
            ..strokeWidth = 3,
        );
      }
      c.drawCircle(const Offset(221, 66), 37, blue);
      c.drawLine(
        const Offset(200, 16),
        const Offset(242, 116),
        line..color = AtlasPalette.navy,
      );
      c.drawLine(
        const Offset(185, 81),
        const Offset(255, 51),
        line..strokeWidth = 2,
      );
      for (var i = 0; i < 3; i++) {
        c.drawLine(
          Offset(113, 43 + i * 22),
          Offset(170, 43 + i * 22),
          line
            ..color = const Color(0xffeccb6a)
            ..strokeWidth = 2,
        );
      }
    } else if (kind == 'aus-coast-erosion') {
      c.drawRect(const Rect.fromLTWH(0, 78, 300, 54), blue);
      c.drawPath(
        Path()
          ..moveTo(0, 10)
          ..lineTo(135, 10)
          ..lineTo(130, 60)
          ..lineTo(101, 78)
          ..lineTo(105, 110)
          ..lineTo(0, 110)
          ..close(),
        Paint()..color = const Color(0xffc9a783),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(190, 32, 35, 79),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xffc9a783),
      );
      for (var i = 0; i < 3; i++) {
        c.drawLine(
          Offset(240, 86 + i * 16),
          Offset(285, 81 + i * 16),
          line
            ..color = Colors.white
            ..strokeWidth = 3,
        );
      }
    } else if (kind == 'aus-platypus') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 300, 132),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xffdceff2),
      );
      final brown = Paint()..color = const Color(0xff98765c);
      c.drawOval(const Rect.fromLTWH(70, 34, 145, 65), brown);
      c.drawOval(
        const Rect.fromLTWH(192, 48, 73, 33),
        step == 0 ? orange : brown,
      );
      c.drawOval(const Rect.fromLTWH(23, 53, 76, 30), brown);
      c.drawOval(
        const Rect.fromLTWH(99, 84, 40, 15),
        step == 1 ? orange : brown,
      );
      c.drawOval(
        const Rect.fromLTWH(167, 84, 40, 15),
        step == 1 ? orange : brown,
      );
      c.drawCircle(const Offset(201, 50), 3, navy);
    } else if (kind == 'aus-food-label') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 20, 290, 92),
          const Radius.circular(12),
        ),
        Paint()..color = Colors.white,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 20, 8, 92),
          const Radius.circular(4),
        ),
        orange,
      );
    } else {
      c.drawLine(
        const Offset(44, 66),
        const Offset(256, 66),
        Paint()
          ..color = const Color(0xffd8e3ec)
          ..strokeWidth = 3,
      );
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
          Offset(50 + i * 100, 66),
          34,
          Paint()..color = Colors.white,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_AusTeachingPainter old) =>
      old.kind != kind || old.step != step;
}
