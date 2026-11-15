import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// A comparison of environments, not a map of their geographic boundaries.
class BrazilBiomesDiagram extends StatefulWidget {
  const BrazilBiomesDiagram({super.key, this.interactive = true});
  final bool interactive;

  @override
  State<BrazilBiomesDiagram> createState() => _BrazilBiomesDiagramState();
}

class _BrazilBiomesDiagramState extends State<BrazilBiomesDiagram> {
  int selected = 0;
  static const biomes = [
    (
      '亚马孙',
      'Amazônia',
      Icons.forest_outlined,
      Color(0xff24725b),
      '热带森林',
      '广阔的热带森林与河流相联系；区域内部也有不同环境。',
      '观察线索：植物有不同高度，河流穿过森林。',
    ),
    (
      '塞拉多',
      'Cerrado',
      Icons.park_outlined,
      Color(0xff8b6b22),
      '草、灌木与树',
      '这里既有开阔的草地，也有灌木和树木，不能只用“草原”概括。',
      '观察线索：比较开阔地与有树的地方。',
    ),
    (
      '卡廷加',
      'Caatinga',
      Icons.wb_sunny_outlined,
      Color(0xffa76339),
      '半干旱环境',
      '许多植物适应季节性的缺水。半干旱不等于全年没有降水。',
      '观察线索：比较同一地点不同季节的植物。',
    ),
    (
      '大西洋森林',
      'Mata Atlântica',
      Icons.forest,
      Color(0xff397e83),
      '森林与海岸',
      '分布在巴西东部等地区，包含多样的森林环境。它与亚马孙是不同的生物群系。',
      '观察线索：先查地点，不能只凭树木认定是亚马孙。',
    ),
    (
      '潘塔纳尔',
      'Pantanal',
      Icons.water_outlined,
      Color(0xff3575a0),
      '季节性湿地',
      '水位变化影响哪些地方被水覆盖，也改变动物可以使用的空间。',
      '观察线索：记录水面、岸边与拍摄日期。',
    ),
    (
      '潘帕',
      'Pampa',
      Icons.grass,
      Color(0xff607c43),
      '南部草地',
      '巴西南部有大片草地环境，草地中也存在其他植物与多种动物。',
      '观察线索：留意低矮植物，不把没有高树理解为没有生命。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = biomes[selected];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff0f6f2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '六种环境，六组线索',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            '点一个名字，认识巴西不同的自然环境。',
            style: TextStyle(color: AtlasPalette.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, biome) in biomes.indexed)
                ChoiceChip(
                  avatar: Icon(biome.$3, color: biome.$4, size: 20),
                  label: Text(biome.$1),
                  showCheckmark: false,
                  selected: selected == i,
                  selectedColor: const Color(0xffdcece0),
                  side: BorderSide(
                    color: selected == i ? biome.$4 : AtlasPalette.line,
                  ),
                  onSelected: widget.interactive
                      ? (_) => setState(() => selected = i)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: current.$4, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(current.$3, color: current.$4, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${current.$1} · ${current.$5}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    current.$2,
                    style: const TextStyle(
                      color: AtlasPalette.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current.$6,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current.$7,
                    style: TextStyle(
                      color: current.$4,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '按 IBGE 六个陆地生物群系分类整理。图标帮助比较，不表示面积或地理分布。',
            style: TextStyle(
              fontSize: 12,
              color: AtlasPalette.muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class BrazilMeetingDiagram extends StatefulWidget {
  const BrazilMeetingDiagram({super.key, this.interactive = true});
  final bool interactive;
  @override
  State<BrazilMeetingDiagram> createState() => _BrazilMeetingDiagramState();
}

class _BrazilMeetingDiagramState extends State<BrazilMeetingDiagram> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xfffff6e7),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '两条河，各有线索',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Text(
          '原创关系示意 · 不按地理距离或真实流速绘制',
          style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
        ),
        const SizedBox(height: 8),
        Semantics(
          image: true,
          label: '内格罗河与索利蒙伊斯河汇合，河水在下游逐渐混合。',
          child: SizedBox(
            height: 150,
            child: CustomPaint(painter: _WaterPainter(selected)),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, name) in ['内格罗河', '索利蒙伊斯河', '下游混合'].indexed)
              ChoiceChip(
                label: Text(name),
                selected: selected == i,
                onSelected: widget.interactive
                    ? (_) => setState(() => selected = i)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          [
            '深色水与植物分解产生的物质有关，不能单靠颜色判断水质。',
            '黄褐色水携带较多泥沙。照片不提供其中物质的精确含量。',
            '水流与涡旋使两股水逐渐混合，可见边界并不是一堵墙。',
          ][selected],
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
      ],
    ),
  );
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter(this.selected);
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 150);
    final upper = Path()
      ..moveTo(0, 15)
      ..cubicTo(90, 15, 90, 57, 165, 58)
      ..lineTo(320, 58)
      ..lineTo(320, 85)
      ..lineTo(160, 85)
      ..cubicTo(80, 82, 75, 52, 0, 48)
      ..close();
    final lower = Path()
      ..moveTo(0, 107)
      ..cubicTo(80, 107, 95, 80, 165, 80)
      ..lineTo(320, 80)
      ..lineTo(320, 120)
      ..lineTo(160, 120)
      ..cubicTo(80, 118, 80, 142, 0, 142)
      ..close();
    canvas.drawPath(upper, Paint()..color = const Color(0xff213f48));
    canvas.drawPath(lower, Paint()..color = const Color(0xffb18a53));
    canvas.drawRect(
      const Rect.fromLTWH(190, 58, 130, 62),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00213f48), Color(0xff73765e)],
        ).createShader(const Rect.fromLTWH(190, 58, 130, 62)),
    );
    for (final (x, y) in [(53.0, 33.0), (53.0, 120.0), (252.0, 90.0)]) {
      final p = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawLine(Offset(x, y), Offset(x + 27, y), p);
      canvas.drawLine(Offset(x + 27, y), Offset(x + 20, y - 5), p);
      canvas.drawLine(Offset(x + 27, y), Offset(x + 20, y + 5), p);
    }
    final label = TextPainter(
      text: const TextSpan(
        text: '水流方向 →',
        style: TextStyle(
          fontSize: 13,
          color: AtlasPalette.navy,
          fontFamily: 'NotoSansSC',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(211, 20));
    label.dispose();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterPainter old) => old.selected != selected;
}
