import '../regions/antarctica/antarctica_diagrams.dart';

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';
import 'usa_diagrams.dart';
import 'gbr_diagrams.dart';
import 'fra_diagrams.dart';
import 'deu_diagrams.dart';
import 'kenya_diagrams.dart';
import 'norway_diagrams.dart';
import 'zaf_diagrams.dart';
import 'japan_diagrams.dart';
import 'brazil_diagrams.dart';
import 'brazil_interactions.dart';
import 'aus_diagrams.dart';

/// Small, accessible teaching models. They are labelled as diagrams and never
/// used as geographic geometry or as substitutes for documentary photographs.
class LearningDiagram extends StatefulWidget {
  const LearningDiagram(
    this.kind, {
    super.key,
    this.interactive = true,
    this.initialStep = 0,
  });
  final String kind;
  final bool interactive;
  final int initialStep;
  @override
  State<LearningDiagram> createState() => _LearningDiagramState();
}

class _LearningDiagramState extends State<LearningDiagram> {
  int selected = -1;
  late int paperStep = widget.initialStep.clamp(0, 2);
  @override
  Widget build(BuildContext context) {
    if (widget.kind.startsWith('antarctica-')) return AntDiagram(widget.kind);
    if (widget.kind.startsWith('zaf-')) {
      return ZafDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('aus-')) {
      return AusDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind == 'brazil-meeting-waters') {
      return BrazilMeetingDiagram(interactive: widget.interactive);
    }
    if (widget.kind == 'brazil-six-biomes') {
      return BrazilBiomesDiagram(interactive: widget.interactive);
    }
    if (widget.kind.startsWith('brazil-')) {
      return BrazilInteraction(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('japan-')) {
      return JapanDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('norway-')) {
      return NorwayDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('kenya-')) {
      return KenyaDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('deu-')) {
      return DeuDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('fra-')) {
      return FraDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('gbr-')) {
      return GbrDiagram(widget.kind, interactive: widget.interactive);
    }
    if (widget.kind.startsWith('usa-')) {
      return UsaDiagram(widget.kind, interactive: widget.interactive);
    }
    final terrain = widget.kind == 'terrain', paper = widget.kind == 'paper';
    if (widget.kind == 'nile-flow') return const _NileFlowDiagram();
    if (widget.kind == 'papyrus-steps') {
      return _PapyrusDiagram(
        step: paperStep,
        onStep: widget.interactive
            ? (value) => setState(() => paperStep = value)
            : null,
      );
    }
    final data = switch (widget.kind) {
      'ecosystem' => [
        ('竹林', Icons.grass, '竹子提供食物。观察动物时，也要看看它吃的植物。'),
        ('水源', Icons.water_drop_outlined, '水是生活条件的一部分；保护环境不能只关注一只动物。'),
        ('连通的森林', Icons.forest_outlined, '适合生活的空间与连接，让动物有机会移动和寻找食物。'),
      ],
      'waterway' => [
        ('自然河流', Icons.water, '自然河流的走向受到地形等因素影响。'),
        ('人工水道', Icons.construction, '人们开凿水道，连接不同的水系；实际工程还要处理水位等问题。'),
        ('城镇往来', Icons.sailing_outlined, '船只沿水路运输物品，把不同地方联系起来。'),
      ],
      'food' => [
        ('原料', Icons.grass, '先认一认：食物的原料是什么？不同食物可能来自不同地方。'),
        ('制作', Icons.restaurant, '加工和烹饪会改变原料的形态。不同食物有不同方法。'),
        ('餐桌', Icons.dining_outlined, '到达餐桌之前，种植、运输、制作等工作可能由许多人共同完成。'),
      ],
      'evidence' => [
        ('我看见', Icons.visibility_outlined, '只写可以直接看见的细节，例如墙体、颜色和形状。'),
        ('我猜想', Icons.psychology_outlined, '解释为什么会这样。猜想还需要更多证据来支持。'),
        ('我查证', Icons.menu_book_outlined, '查资料或观察更多例子，看看是否支持原来的猜想。'),
      ],
      'nile-irrigation' => [
        ('尼罗河', Icons.water, '河水是一些河谷和三角洲农田的水源。'),
        ('灌渠', Icons.call_split, '渠道把水分到不同方向，真实路线要看当地地图。'),
        ('农田', Icons.grass, '水到达田地，作物可以得到生长所需的一部分水。'),
      ],
      'reef-habitat' => [
        ('珊瑚', Icons.bubble_chart_outlined, '许多造礁珊瑚有坚硬的骨骼，会形成礁体的一部分。'),
        ('礁缝', Icons.texture, '大小不同的凹处，可能为小动物提供遮挡。'),
        ('小动物', Icons.set_meal_outlined, '动物还需要食物、合适的水和可以活动的空间。'),
      ],
      'heritage-move' => [
        ('先记录', Icons.straighten, '拍照、测量和编号，记下构件的位置。'),
        ('分块迁移', Icons.view_in_ar_outlined, '将能移动的石块移到更安全的位置。'),
        ('重新组装', Icons.account_balance_outlined, '按原来的关系把构件安放到新地点。'),
      ],
      'terrain' => [
        ('高原', Icons.terrain, '高原海拔较高，地面仍然会起伏，不是完全平的桌面。'),
        ('山地与盆地', Icons.landscape_outlined, '山地和盆地有不同起伏。一片广阔地区常包含多种地形。'),
        ('平原与海岸', Icons.waves, '整体向东地势降低，但“西高东低”不等于处处平缓，也不等于每条河都向东流。'),
      ],
      'paper' => <(String, IconData, String)>[],
      _ => <(String, IconData, String)>[],
    };
    if (data.isEmpty && !paper) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtlasPalette.canvas,
        border: Border.all(color: AtlasPalette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (widget.kind) {
            'terrain' => '从高原走向海岸',
            'paper' => '同一个剪口，展开会怎样？',
            'ecosystem' => '看见动物，也看见它的家',
            'waterway' => '水路怎样把地方连起来？',
            'food' => '从原料到餐桌',
            'nile-irrigation' => '水怎样从河里到达农田？',
            'reef-habitat' => '礁缝可以是谁的家？',
            'heritage-move' => '怎样在高处重组神庙？',
            _ => '把观察和猜想分开',
          }, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 14),
          if (terrain) ...[
            Semantics(
              label: '地势概念示意：左侧西部高原较高，向右过渡到山地、盆地、平原和海岸。不是精确地形剖面。',
              child: SizedBox(
                height: 172,
                width: double.infinity,
                child: CustomPaint(painter: _TerrainDiagramPainter()),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('西', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '地势示意 · 非精确比例',
                  style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
                ),
                Text('东', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (paper) ...[
            Semantics(
              label: paperStep == 2
                  ? '红纸沿中线展开，同一位置出现两个相互对称的圆形剪口。'
                  : paperStep == 1
                  ? '对折后的红纸剪去一个圆形。'
                  : '红纸沿中线对折。',
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(painter: _PaperDiagramPainter(paperStep)),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(['1 对折', '2 剪形', '3 展开'][i]),
                    selected: paperStep == i,
                    onSelected: widget.interactive
                        ? (_) => setState(() => paperStep = i)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '这是一次数字对称实验。真实的剪纸还有不同材料、图案和剪刻方法。',
              style: TextStyle(fontSize: 14, color: AtlasPalette.muted),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < data.length; i++)
                    SizedBox(
                      width: MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 3,
                      child: OutlinedButton(
                        onPressed: widget.interactive
                            ? () => setState(() => selected = i)
                            : null,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected == i
                              ? AtlasPalette.orangeSoft
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(data[i].$2, size: 28),
                            const SizedBox(height: 7),
                            Text(
                              data[i].$1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (selected >= 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  data[selected].$3,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            if (selected < 0 && widget.interactive)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '点一个词，看看其中的联系。',
                  style: TextStyle(fontSize: 14, color: AtlasPalette.muted),
                ),
              ),
            if (!terrain)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '关系示意 · 用来帮助观察和思考',
                  style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TerrainDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCCE7F6), Color(0xFFF7FBFD)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      sky,
    );
    final earth = Path()
      ..moveTo(0, h * .45)
      ..lineTo(w * .08, h * .15)
      ..lineTo(w * .15, h * .38)
      ..lineTo(w * .23, h * .25)
      ..lineTo(w * .29, h * .48)
      ..lineTo(w * .35, h * .50)
      ..lineTo(w * .41, h * .42)
      ..lineTo(w * .50, h * .70)
      ..lineTo(w * .58, h * .68)
      ..lineTo(w * .65, h * .55)
      ..lineTo(w * .72, h * .78)
      ..lineTo(w * .85, h * .81)
      ..lineTo(w * .91, h * .85)
      ..lineTo(w, h * .85)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      earth,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFA68865), Color(0xFFD0B58D), Color(0xFF81A973)],
        ).createShader(Offset.zero & size),
    );
    final snow = Path()
      ..moveTo(w * .035, h * .32)
      ..lineTo(w * .08, h * .15)
      ..lineTo(w * .13, h * .32)
      ..lineTo(w * .10, h * .29)
      ..lineTo(w * .08, h * .34)
      ..lineTo(w * .06, h * .29)
      ..close();
    canvas.drawPath(snow, Paint()..color = Colors.white);
    final sea = Path()
      ..moveTo(w * .86, h * .84)
      ..quadraticBezierTo(w * .93, h * .80, w, h * .84)
      ..lineTo(w, h)
      ..lineTo(w * .86, h)
      ..close();
    canvas.drawPath(sea, Paint()..color = const Color(0xFF81CAE8));
    final river = Path()
      ..moveTo(w * .29, h * .48)
      ..cubicTo(w * .50, h * .78, w * .66, h * .58, w * .72, h * .80)
      ..cubicTo(w * .81, h * .88, w * .77, h * .83, w * .9, h * .87);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF287CB2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperDiagramPainter extends CustomPainter {
  _PaperDiagramPainter(this.step);
  final int step;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paper = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        Rect.fromLTRB(step == 2 ? w * .14 : w * .5, h * .08, w * .86, h * .9),
      );
    if (step > 0) {
      paper.addOval(
        Rect.fromCircle(center: Offset(w * .69, h * .46), radius: h * .12),
      );
    }
    if (step == 2) {
      paper.addOval(
        Rect.fromCircle(center: Offset(w * .31, h * .46), radius: h * .12),
      );
    }
    canvas.drawShadow(paper, Colors.black26, 4, true);
    canvas.drawPath(paper, Paint()..color = const Color(0xFFC83C3C));
    for (var y = h * .08; y < h * .9; y += 12) {
      canvas.drawLine(
        Offset(w * .5, y),
        Offset(w * .5, y + 6),
        Paint()
          ..color = step == 2 ? Colors.white70 : AtlasPalette.muted
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PaperDiagramPainter oldDelegate) =>
      oldDelegate.step != step;
}

class _NileFlowDiagram extends StatelessWidget {
  const _NileFlowDiagram();

  @override
  Widget build(BuildContext context) => _DiagramFrame(
    title: '',
    caption: '水系示意 · 非精确比例 · 只画埃及境内的一段',
    child: Semantics(
      label: '尼罗河水系示意：北在上方。箭头从阿斯旺向开罗，再通过三角洲的分支指向地中海。',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 198,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _NileFlowPainter(),
              child: Stack(
                children: [
                  const Positioned(
                    top: 9,
                    left: 12,
                    child: Text(
                      '北 ↑',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Align(
                    alignment: Alignment(0, -.89),
                    child: Text(
                      '地中海',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AtlasPalette.navy,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment(.88, -.42),
                    child: Text(
                      '三角洲',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Align(
                    alignment: Alignment(-.76, -.06),
                    child: Text(
                      '开罗',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Align(
                    alignment: Alignment(.81, .67),
                    child: Text(
                      '阿斯旺',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DiagramFrame extends StatelessWidget {
  const _DiagramFrame({
    required this.title,
    required this.child,
    required this.caption,
  });
  final String title, caption;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(title.isEmpty ? 9 : 16),
    decoration: BoxDecoration(
      color: AtlasPalette.canvas,
      border: Border.all(color: AtlasPalette.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
        ],
        child,
        const SizedBox(height: 10),
        Text(
          caption,
          style: const TextStyle(color: AtlasPalette.muted, fontSize: 13),
        ),
      ],
    ),
  );
}

class _NileFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawColor(const Color(0xFFFFF3DB), BlendMode.src);
    canvas.drawPath(
      Path()
        ..lineTo(0, h * .21)
        ..quadraticBezierTo(w * .19, h * .27, w * .35, h * .23)
        ..quadraticBezierTo(w * .56, h * .16, w, h * .25)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = const Color(0xFFB6DFF1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .49, h * .44)
        ..quadraticBezierTo(w * .44, h * .33, w * .28, h * .234)
        ..quadraticBezierTo(w * .52, h * .19, w * .69, h * .205)
        ..quadraticBezierTo(w * .55, h * .37, w * .49, h * .44),
      Paint()..color = const Color(0xFFBFD9A8),
    );
    final p = Paint()
      ..color = const Color(0xFF117AB2)
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(w * .45, h)
        ..cubicTo(w * .55, h * .84, w * .67, h * .79, w * .54, h * .70)
        ..cubicTo(w * .43, h * .61, w * .46, h * .55, w * .49, h * .44)
        ..quadraticBezierTo(w * .39, h * .35, w * .34, h * .22)
        ..moveTo(w * .49, h * .44)
        ..quadraticBezierTo(w * .61, h * .31, w * .62, h * .205),
      p,
    );
    void arrow(Offset tip, Offset previous) {
      final vector = tip - previous;
      final along = vector / vector.distance;
      final normal = Offset(-along.dy, along.dx);
      canvas.drawPath(
        Path()
          ..moveTo(
            (tip - along * 9 + normal * 4).dx,
            (tip - along * 9 + normal * 4).dy,
          )
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(
            (tip - along * 9 - normal * 4).dx,
            (tip - along * 9 - normal * 4).dy,
          ),
        p,
      );
    }

    arrow(Offset(w * .34, h * .22), Offset(w * .37, h * .29));
    arrow(Offset(w * .62, h * .205), Offset(w * .60, h * .28));
    arrow(Offset(w * .51, h * .673), Offset(w * .54, h * .7));
    for (final point in [
      Offset(w * .475, h * .496),
      Offset(w * .546, h * .857),
    ]) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = AtlasPalette.navy);
    }
  }

  @override
  bool shouldRepaint(covariant _NileFlowPainter oldDelegate) => false;
}

class _PapyrusDiagram extends StatelessWidget {
  const _PapyrusDiagram({required this.step, required this.onStep});
  final int step;
  final ValueChanged<int>? onStep;

  static const labels = ['切成薄条', '两层交叉铺', '压合与干燥'];
  static const descriptions = [
    '取出茎的内部，切成一条条薄片。',
    '下层每条朝同一个方向。上层的薄条转九十度后平铺在下层上。',
    '压合、干燥后成为片材。古代各地的具体做法仍有研究空间。',
  ];

  @override
  Widget build(BuildContext context) => _DiagramFrame(
    title: '纸莎草片材的三步',
    caption: '做法示意 · 两层分别平铺，没有上下交替编织。',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          image: true,
          label: descriptions[step],
          child: SizedBox(
            height: 148,
            width: double.infinity,
            child: CustomPaint(painter: _PapyrusPainter(step)),
          ),
        ),
        if (onStep != null)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final (i, label) in labels.indexed)
                ChoiceChip(
                  selected: step == i,
                  onSelected: (_) => onStep!(i),
                  label: Text('${i + 1} $label'),
                ),
            ],
          ),
        const SizedBox(height: 10),
        Text(
          onStep == null ? '观察第 ${step + 1} 步的两组线条。' : descriptions[step],
          style: const TextStyle(fontSize: 16, color: AtlasPalette.navy),
        ),
      ],
    ),
  );
}

class _PapyrusPainter extends CustomPainter {
  const _PapyrusPainter(this.step);
  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * .8,
      height: 120,
    );
    final pale = Paint()..color = const Color(0xFFE2BA76);
    final dark = Paint()
      ..color = const Color(0xFFAC722D).withValues(alpha: .72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = const Color(0xFFFAEBD2),
    );
    if (step == 0) {
      for (var i = 0; i < 6; i++) {
        final dx = rect.left + rect.width * (.10 + .14 * i);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              dx,
              rect.top + 5 + i * 3,
              rect.width * .095,
              rect.height - 26,
            ),
            const Radius.circular(4),
          ),
          pale,
        );
      }
      return;
    }
    if (step == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        pale,
      );
    }
    for (var i = 0; i < 10; i++) {
      final y = rect.top + rect.height * (i + .4) / 10;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, y, rect.width, step == 1 ? 7 : 1.1),
          const Radius.circular(2),
        ),
        step == 1 ? pale : dark,
      );
    }
    // All vertical strips lie on top of a completed horizontal layer.
    // Keeping opacity consistent across each strip avoids a woven effect.
    for (var i = 0; i < 13; i++) {
      final x = rect.left + rect.width * (i + .35) / 13;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            rect.top,
            step == 1 ? rect.width / 24 : 1,
            rect.height,
          ),
          const Radius.circular(2),
        ),
        dark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PapyrusPainter oldDelegate) =>
      step != oldDelegate.step;
}
