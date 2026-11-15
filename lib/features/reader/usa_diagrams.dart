import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/atlas_theme.dart';

class UsaDiagram extends StatelessWidget {
  const UsaDiagram(this.kind, {super.key, required this.interactive});
  final String kind;
  final bool interactive;

  @override
  Widget build(BuildContext context) => switch (kind) {
    'usa-canyon-erosion' => const _CanyonDiagram(),
    'usa-geyser-process' => const _GeyserDiagram(),
    'usa-jazz-response' => _RhythmDiagram(interactive: interactive),
    'usa-great-lakes-flow' => const _LakesDiagram(),
    'usa-apple-supply' => const _AppleDiagram(),
    _ => const SizedBox.shrink(),
  };
}

class _DiagramCard extends StatelessWidget {
  const _DiagramCard(this.title, {required this.child, this.caption});
  final String title;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AtlasPalette.canvas,
      border: Border.all(color: AtlasPalette.line),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 21,
              decoration: BoxDecoration(
                color: AtlasPalette.orange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 8),
            const Text(
              '示意',
              style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
        if (caption != null) ...[
          const SizedBox(height: 7),
          Text(
            caption!,
            style: const TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
        ],
      ],
    ),
  );
}

class _CanyonDiagram extends StatelessWidget {
  const _CanyonDiagram();
  static const stages = [
    ('岩层', '流水带走松动的碎屑。'),
    ('河道', '河水向下切出较深的河道。'),
    ('峡谷', '风化、崩落等过程使岩壁后退。'),
  ];

  @override
  Widget build(BuildContext context) => _DiagramCard(
    '侵蚀示意',
    caption: '蓝色是河水，过程和剖面未按真实时间或比例绘制。',
    child: LayoutBuilder(
      builder: (context, limits) {
        final vertical =
            limits.maxWidth < 242 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4;
        return Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, stage) in stages.indexed) ...[
              if (i != 0)
                Padding(
                  padding: EdgeInsets.only(top: vertical ? 3 : 48),
                  child: Icon(
                    vertical ? Icons.arrow_downward : Icons.arrow_forward,
                    color: AtlasPalette.muted,
                    size: 18,
                  ),
                ),
              if (vertical)
                _CanyonStage(stage: stage, index: i)
              else
                Expanded(
                  child: _CanyonStage(stage: stage, index: i),
                ),
            ],
          ],
        );
      },
    ),
  );
}

class _CanyonStage extends StatelessWidget {
  const _CanyonStage({required this.stage, required this.index});
  final (String, String) stage;
  final int index;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(child: _DiagramTag(stage.$1, const Color(0xffe2e9f1))),
      const SizedBox(height: 5),
      Semantics(
        label: '第 ${index + 1} 幅岩层剖面。蓝色河水在中间低处。',
        child: SizedBox(
          height: 69,
          child: CustomPaint(painter: _CanyonSection(index)),
        ),
      ),
      const SizedBox(height: 5),
      Text(stage.$2, style: const TextStyle(fontSize: 12.5, height: 1.35)),
    ],
  );
}

class _CanyonSection extends CustomPainter {
  const _CanyonSection(this.stage);
  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final floor = [25.0, 47.0, 75.0][stage];
    final rim = [8.0, 18.0, 29.0][stage];
    canvas.save();
    canvas.scale(size.width / 100, size.height / 85);
    final rock = Path()
      ..moveTo(0, 15)
      ..lineTo(50 - rim, 15)
      ..lineTo(53 - rim, 21)
      ..lineTo(46, floor - 2)
      ..quadraticBezierTo(50, floor + 2, 54, floor - 2)
      ..lineTo(47 + rim, 21)
      ..lineTo(50 + rim, 15)
      ..lineTo(100, 15)
      ..lineTo(100, 84)
      ..lineTo(0, 84)
      ..close();
    canvas.clipPath(rock);
    const colors = [
      0xffecc27c,
      0xffdca561,
      0xffbb804d,
      0xffc99363,
      0xffa96540,
      0xffd39e76,
    ];
    for (final (i, color) in colors.indexed) {
      final y = 13.0 + i * 12;
      final strip = Path()
        ..moveTo(0, y)
        ..cubicTo(31, y - 4, 58, y + 5, 100, y)
        ..lineTo(100, y + 14)
        ..lineTo(0, y + 14)
        ..close();
      canvas.drawPath(strip, Paint()..color = Color(color));
    }
    canvas.restore();
    final water = Path()
      ..moveTo(44, floor - 4)
      ..quadraticBezierTo(50, floor + 3, 56, floor - 4)
      ..close();
    canvas.save();
    canvas.scale(size.width / 100, size.height / 85);
    canvas.drawPath(water, Paint()..color = const Color(0xff0082ad));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CanyonSection oldDelegate) => oldDelegate.stage != stage;
}

class _GeyserDiagram extends StatelessWidget {
  const _GeyserDiagram();
  @override
  Widget build(BuildContext context) => _DiagramCard(
    '间歇泉示意',
    caption: '地下通道的窄口会影响压力。压力降低时，蒸汽迅速增多，推动水从出口喷出。',
    child: Column(
      children: [
        const Wrap(
          spacing: 4,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DiagramTag('水进入地下', Color(0xffd6e8f8)),
            Icon(Icons.arrow_forward, size: 14),
            _DiagramTag('热量加热水', Color(0xffffe7c9)),
            Icon(Icons.arrow_forward, size: 14),
            _DiagramTag('水和蒸汽喷出', Color(0xffc7e6ff)),
          ],
        ),
        const SizedBox(height: 7),
        Semantics(
          label: '地表剖面。蓝色的水从左侧进入下方的储水空间。下方橙色箭头表示热量，水从上方狭窄的蓝色通道喷出。',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const SizedBox(
              height: 152,
              width: double.infinity,
              child: CustomPaint(painter: _GeyserSection()),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GeyserSection extends CustomPainter {
  const _GeyserSection();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 190);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 190),
      Paint()..color = const Color(0xffdceefa),
    );
    for (final (i, color) in const [
      0xffcda377,
      0xffb5865f,
      0xffa77753,
      0xff92644b,
    ].indexed) {
      final top = 60.0 + i * 34;
      final rock = Path()
        ..moveTo(0, top)
        ..cubicTo(90, top + 9, 146, top - 8, 184, top)
        ..cubicTo(226, top + 8, 290, top - 4, 360, top)
        ..lineTo(360, 190)
        ..lineTo(0, 190)
        ..close();
      canvas.drawPath(rock, Paint()..color = Color(color));
    }
    final dots = math.Random(410);
    final pebbles = Paint()..color = const Color(0x25875434);
    for (var i = 0; i < 95; i++) {
      canvas.drawCircle(
        Offset(dots.nextDouble() * 360, 71 + dots.nextDouble() * 114),
        1 + dots.nextDouble() * 2,
        pebbles,
      );
    }
    final water = Path()
      ..moveTo(0, 114)
      ..cubicTo(52, 112, 77, 139, 117, 134)
      ..cubicTo(141, 131, 145, 123, 151, 104)
      ..cubicTo(164, 79, 164, 69, 160, 60)
      ..lineTo(179, 60)
      ..cubicTo(175, 74, 179, 85, 182, 107)
      ..cubicTo(208, 113, 232, 133, 223, 150)
      ..cubicTo(215, 163, 139, 163, 112, 150)
      ..cubicTo(71, 154, 42, 128, 0, 132)
      ..close();
    canvas.drawPath(
      water,
      Paint()
        ..color = const Color(0xffd6effe)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(water, Paint()..color = const Color(0xff48a9de));
    final spray = Path()
      ..moveTo(164, 62)
      ..quadraticBezierTo(167, 40, 148, 33)
      ..quadraticBezierTo(126, 27, 137, 14)
      ..quadraticBezierTo(149, 4, 162, 31)
      ..quadraticBezierTo(167, 39, 169, 51)
      ..quadraticBezierTo(175, 13, 193, 9)
      ..quadraticBezierTo(210, 9, 195, 26)
      ..quadraticBezierTo(176, 39, 173, 62)
      ..close();
    canvas.drawPath(spray, Paint()..color = Colors.white);
    _arrow(
      canvas,
      const Offset(109, 139),
      const Offset(145, 139),
      Colors.white,
    );
    _arrow(canvas, const Offset(168, 112), const Offset(170, 76), Colors.white);
    _arrow(
      canvas,
      const Offset(168, 56),
      const Offset(168, 15),
      const Color(0xff1477af),
    );
    for (final x in [141.0, 175.0, 209.0]) {
      _arrow(canvas, Offset(x, 185), Offset(x, 163), const Color(0xffffb15c));
    }
    canvas.restore();
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Color color) {
    final vector = b - a;
    final unit = vector / vector.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, paint);
    canvas.drawLine(b, b - unit * 7 + normal * 4, paint);
    canvas.drawLine(b, b - unit * 7 - normal * 4, paint);
  }

  @override
  bool shouldRepaint(_GeyserSection oldDelegate) => false;
}

class _RhythmDiagram extends StatefulWidget {
  const _RhythmDiagram({required this.interactive});
  final bool interactive;
  @override
  State<_RhythmDiagram> createState() => _RhythmDiagramState();
}

class _RhythmDiagramState extends State<_RhythmDiagram> {
  static const rhythms = [
    [true, true, false, true],
    [true, false, true, true],
  ];
  static const titles = ['一句乐句', '另一句回应'];
  Timer? timer;
  int? beat;

  void play(int start, int end) {
    timer?.cancel();
    var step = start;
    void showBeat() {
      setState(() => beat = step);
      if (rhythms[step ~/ 4][step % 4]) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
    }

    showBeat();
    timer = Timer.periodic(const Duration(milliseconds: 460), (t) {
      if (++step == end) {
        t.cancel();
        setState(() => beat = null);
      } else {
        showBeat();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _DiagramCard(
    '接话示意',
    caption: '每句都有四拍。实心点表示拍手，空心点表示停一拍。',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, limits) {
            final vertical =
                limits.maxWidth < 245 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.4;
            Widget row(int index) {
              final active = beat != null && beat! ~/ 4 == index;
              final beats = rhythms[index];
              final description = beats.map((b) => b ? '响' : '停').join('、');
              return Semantics(
                label: '${titles[index]}，$description',
                button: widget.interactive,
                child: Material(
                  color: index == 0
                      ? AtlasPalette.orangeSoft
                      : const Color(0xffdceefa),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.interactive
                        ? () => play(index * 4, index * 4 + 4)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            index == 0 ? Icons.music_note : Icons.queue_music,
                            size: 25,
                            color: index == 0
                                ? const Color(0xffa84913)
                                : AtlasPalette.navy,
                          ),
                          Text(
                            titles[index],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final (i, strike) in beats.indexed)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Icon(
                                    strike
                                        ? Icons.circle
                                        : Icons.circle_outlined,
                                    size: 12,
                                    color: active && beat! % 4 == i
                                        ? const Color(0xffb44d10)
                                        : AtlasPalette.navy,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              children: [
                if (vertical) row(0) else Expanded(child: row(0)),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    vertical ? Icons.arrow_downward : Icons.arrow_forward,
                    color: const Color(0xffb44d10),
                    size: 18,
                  ),
                ),
                if (vertical) row(1) else Expanded(child: row(1)),
              ],
            );
          },
        ),
        if (widget.interactive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => play(0, 8),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('试着拍手接一句'),
            ),
          ),
      ],
    ),
  );
}

class _LakesDiagram extends StatelessWidget {
  const _LakesDiagram();
  @override
  Widget build(BuildContext context) => const _DiagramCard(
    '五大湖的水往哪里去？',
    caption: '箭头表示整体流向。密歇根湖和休伦湖以麦基诺水道相连，连接线不表示局部流向。',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiagramSteps([
          '苏必利尔湖',
          '休伦湖',
          '伊利湖',
          '安大略湖',
          '圣劳伦斯河',
        ], Color(0xffd9eef9)),
        SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DiagramTag('密歇根湖', Color(0xffd9eef9)),
            Text('─ 麦基诺水道 ─', style: TextStyle(fontSize: 13)),
            _DiagramTag('休伦湖', Color(0xffd9eef9)),
          ],
        ),
      ],
    ),
  );
}

class _AppleDiagram extends StatelessWidget {
  const _AppleDiagram();
  @override
  Widget build(BuildContext context) => const _DiagramCard(
    '一颗苹果怎样走到市场？',
    caption: '图中是本文例子的路线。直接从果园出售的苹果可以走不同的路线。',
    child: _DiagramSteps(['果园采收', '分选与储存', '运送到市场'], AtlasPalette.orangeSoft),
  );
}

class _DiagramSteps extends StatelessWidget {
  const _DiagramSteps(this.labels, this.color);
  final List<String> labels;
  final Color color;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 7,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final (i, label) in labels.indexed)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i != 0)
              const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(Icons.arrow_forward, size: 15),
              ),
            _DiagramTag(label, color),
          ],
        ),
    ],
  );
}

class _DiagramTag extends StatelessWidget {
  const _DiagramTag(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );
}
