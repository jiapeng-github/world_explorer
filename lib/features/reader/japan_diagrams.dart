import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original teaching models, never used as photographs or geographic outlines.
class JapanDiagram extends StatefulWidget {
  const JapanDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<JapanDiagram> createState() => _JapanDiagramState();
}

class _JapanDiagramState extends State<JapanDiagram> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final (title, steps, notes) = switch (widget.kind) {
      'japan-volcano' => (
        '从地下到山体',
        ['地下岩浆', '到达地表', '山体与侵蚀'],
        [
          '地下熔融岩石称岩浆。剖面用符号展示看不见的关系。',
          '到达地表的岩浆称熔岩；喷发也可能带出碎屑。',
          '多次活动的堆积与后来的侵蚀共同影响山形。',
        ],
      ),
      'japan-transfer' => (
        '在哪里换乘？',
        ['甲站出发', '乙站换乘', '到达丙站'],
        [
          '蓝线连接甲站与乙站。站名和线型帮助识别路线。',
          '乙站是两条线的共同站点，在这里从蓝线换到橙线。',
          '沿橙线从乙到丙。全图是虚构练习，不表示真实距离。',
        ],
      ),
      'japan-rice' => (
        '稻谷到米饭',
        ['收获稻谷', '去壳与碾磨', '加水烹煮'],
        [
          '稻谷外面有壳，它和碗里的米饭处于不同阶段。',
          '去壳得到糙米，继续碾磨会改变米粒外层。',
          '米吸收水并受热，质地发生变化；照片不能直接说明产地。',
        ],
      ),
      'japan-miso' => (
        '发酵中的变化',
        ['认识原料', '微生物参与', '核对过程'],
        [
          '常见原料包括大豆、盐与曲；具体配方查看产品说明。',
          '放大的小圆点象征微生物参与，不是显微镜实拍。',
          '结果与原料、温度、时间等条件有关，不能只凭颜色判断。',
        ],
      ),
      'japan-woodblock' => (
        '颜色怎样套在一起？',
        ['第一色版', '第二色版', '对齐套印'],
        ['原创圆形图案印出第一种颜色。', '另一块色版提供蓝色波纹。注意两块版的定位角标。', '按照同一组标记对齐，圆形与波纹组合成图案。'],
      ),
      'japan-forest' => (
        '一座森林的三个层次',
        ['高处树冠', '树干与林下', '地面层'],
        ['树冠是树木上部枝叶组成的部分。', '树干与较低植物形成不同高度的空间。', '落叶、苔藓和倒木也是环境的一部分；远景照片未必看得清。'],
      ),
      'japan-scale' => (
        '画面大小 ≠ 现实大小',
        ['世界范围', '列岛范围', '地区范围'],
        [
          '大范围图适合找国家相对位置，许多小岛只占很小区域。',
          '缩小观察范围，岛屿细节变得清楚。',
          '同样大的画框能展示更小地区，每次切换都重新看比例尺。',
        ],
      ),
      _ => (
        '沿着水流看陆地',
        ['上游山地', '支流汇合', '下游入海'],
        [
          '水受重力影响沿地形流动；上游不固定等于画面左侧。',
          '不同支流汇入同一条河，周围土地也属于水系关系的一部分。',
          '河流可以流向海洋。图中是原创模型，不是真实河道或流域边界。',
        ],
      ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtlasPalette.canvas,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            '原创关系示意 · 非实拍，不按实际比例',
            style: TextStyle(fontSize: 12, color: AtlasPalette.muted),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: Colors.white,
              child: Semantics(
                image: true,
                label: '$title：${steps[selected]}。${notes[selected]}',
                child: SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _JapanScene(widget.kind, selected),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final (i, step) in steps.indexed)
                ChoiceChip(
                  label: Text('${i + 1} $step'),
                  selected: selected == i,
                  selectedColor: AtlasPalette.orangeSoft,
                  onSelected: widget.interactive
                      ? (_) => setState(() => selected = i)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes[selected],
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _JapanScene extends CustomPainter {
  _JapanScene(this.kind, this.step);
  final String kind;
  final int step;
  static const navy = AtlasPalette.navy, orange = AtlasPalette.orange;
  static const green = Color(0xff467e68), blue = Color(0xff48a2cd);
  void line(Canvas c, Offset a, Offset b, Color color, [double width = 4]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void text(
    Canvas c,
    String value,
    Offset p, {
    double size = 14,
    Color color = navy,
  }) {
    final t = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontFamily: 'NotoSansSC',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 280);
    t.paint(c, p);
  }

  void disc(Canvas c, Offset p, double r, Color color) =>
      c.drawCircle(p, r, Paint()..color = color);
  void box(Canvas c, Rect r, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, const Radius.circular(10)),
    Paint()..color = color,
  );
  void path(Canvas c, List<Offset> ps, Color color) {
    final p = Path()..moveTo(ps.first.dx, ps.first.dy);
    for (final v in ps.skip(1)) {
      p.lineTo(v.dx, v.dy);
    }
    p.close();
    c.drawPath(p, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 330, size.height / 210);
    final c = canvas;
    switch (kind) {
      case 'japan-volcano':
        box(c, const Rect.fromLTWH(0, 157, 330, 53), const Color(0xffe5d8c4));
        path(c, const [
          Offset(22, 158),
          Offset(143, 46),
          Offset(185, 46),
          Offset(308, 158),
        ], const Color(0xffafbcba));
        path(c, const [
          Offset(65, 158),
          Offset(151, 78),
          Offset(179, 78),
          Offset(265, 158),
        ], const Color(0xffd3c1a6));
        path(c, const [
          Offset(107, 158),
          Offset(156, 110),
          Offset(175, 110),
          Offset(226, 158),
        ], const Color(0xffa5b1ae));
        c.drawOval(
          const Rect.fromLTWH(125, 173, 80, 27),
          Paint()..color = (step == 0 ? orange : const Color(0xffd48658)),
        );
        line(
          c,
          const Offset(164, 181),
          const Offset(164, 65),
          step == 1 ? orange : const Color(0xffd48658),
          12,
        );
        line(c, const Offset(164, 63), const Offset(149, 85), orange, 4);
        line(c, const Offset(164, 63), const Offset(180, 85), orange, 4);
        text(c, '地下', const Offset(24, 177));
        text(c, '地表', const Offset(270, 169));
        text(
          c,
          step == 0
              ? '① 岩浆'
              : step == 1
              ? '② 到达地表'
              : '③ 堆积与侵蚀',
          const Offset(15, 12),
        );
        break;
      case 'japan-transfer':
        line(c, const Offset(48, 95), const Offset(165, 95), blue, 10);
        line(c, const Offset(165, 95), const Offset(280, 145), orange, 10);
        for (final (i, p) in [
          const Offset(48, 95),
          const Offset(165, 95),
          const Offset(280, 145),
        ].indexed) {
          disc(c, p, step == i ? 19 : 14, navy);
          disc(c, p, 8, Colors.white);
          text(c, ['甲', '乙', '丙'][i], p + const Offset(-8, 26), size: 18);
        }
        text(c, '蓝线', const Offset(74, 45), color: blue);
        text(c, '橙线', const Offset(235, 80), color: orange);
        text(c, '虚构站点 · 非真实线路', const Offset(18, 183), size: 12);
        break;
      case 'japan-forest':
        box(c, const Rect.fromLTWH(0, 170, 330, 40), const Color(0xffdbc9aa));
        for (final x in [68.0, 157.0, 254.0]) {
          line(
            c,
            Offset(x, 175),
            Offset(x, 60),
            step == 1 ? orange : const Color(0xff8c684b),
            13,
          );
          disc(
            c,
            Offset(x, 60),
            39,
            step == 0 ? green : green.withValues(alpha: .6),
          );
          disc(c, Offset(x - 20, 70), 25, green);
        }
        for (var i = 0; i < 9; i++) {
          final x = 15 + i * 37.0;
          disc(
            c,
            Offset(x, 163),
            12,
            step == 1 ? green : const Color(0xff9fc29d),
          );
        }
        line(
          c,
          const Offset(95, 183),
          const Offset(188, 190),
          step == 2 ? orange : const Color(0xff8c684b),
          9,
        );
        text(c, ['① 树冠', '② 林下', '③ 落叶与倒木'][step], const Offset(12, 12));
        break;
      case 'japan-woodblock':
        for (var i = 0; i < 3; i++) {
          final x = 12 + i * 106.0;
          box(
            c,
            Rect.fromLTWH(x, 55, 94, 116),
            i == step ? AtlasPalette.orangeSoft : const Color(0xffedf2f5),
          );
          if (i == 0 || i == 2) disc(c, Offset(x + 45, 102), 24, orange);
          if (i == 1 || i == 2) {
            for (var j = 0; j < 3; j++) {
              final p = Path()
                ..moveTo(x + 12, 122 + j * 10)
                ..quadraticBezierTo(x + 43, 103 + j * 10, x + 82, 126 + j * 10);
              c.drawPath(
                p,
                Paint()
                  ..color = blue
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4,
              );
            }
          }
          line(c, Offset(x + 7, 158), Offset(x + 7, 165), navy, 2);
          line(c, Offset(x + 7, 165), Offset(x + 18, 165), navy, 2);
          text(c, ['第一色', '第二色', '套印'][i], Offset(x + 15, 178));
        }
        text(c, '对齐角标 → 组合图形', const Offset(18, 15));
        break;
      case 'japan-scale':
        for (var i = 0; i < 3; i++) {
          final x = 12 + i * 106.0;
          box(
            c,
            Rect.fromLTWH(x, 54, 94, 106),
            i == step ? const Color(0xffd6eaf4) : const Color(0xffedf2f5),
          );
          for (var n = 1; n < 4; n++) {
            line(
              c,
              Offset(x + n * 23, 60),
              Offset(x + n * 23, 155),
              Colors.white,
              1,
            );
            line(
              c,
              Offset(x + 5, 55 + n * 25),
              Offset(x + 89, 55 + n * 25),
              Colors.white,
              1,
            );
          }
          c.drawRect(
            Rect.fromLTWH(x + 16, 75, 22 + i * 19, 20 + i * 19),
            Paint()
              ..color = orange
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          text(c, ['大范围', '中范围', '小范围'][i], Offset(x + 14, 173));
        }
        text(c, '同样画框 · 不同观察范围', const Offset(18, 16));
        break;
      case 'japan-rice':
        for (var i = 0; i < 3; i++) {
          final x = 20 + i * 104.0;
          box(
            c,
            Rect.fromLTWH(x, 53, 85, 117),
            i == step ? AtlasPalette.orangeSoft : const Color(0xffedf2f5),
          );
          if (i < 2) {
            for (var n = 0; n < 5; n++) {
              c.drawOval(
                Rect.fromLTWH(
                  x + 19 + (n % 2) * 22,
                  72 + (n ~/ 2) * 23,
                  15,
                  28,
                ),
                Paint()
                  ..color = (i == 0 ? const Color(0xffc0a168) : Colors.white),
              );
            }
          } else {
            c.drawOval(
              Rect.fromLTWH(x + 10, 99, 65, 30),
              Paint()..color = Colors.white,
            );
            path(c, [
              Offset(x + 10, 114),
              Offset(x + 75, 114),
              Offset(x + 60, 144),
              Offset(x + 25, 144),
            ], navy);
            for (var n = 0; n < 3; n++) {
              line(
                c,
                Offset(x + 25 + n * 17, 87),
                Offset(x + 25 + n * 17, 69),
                blue,
                3,
              );
            }
          }
          text(c, ['稻谷', '米粒', '米饭'][i], Offset(x + 22, 178));
        }
        break;
      case 'japan-miso':
        box(c, const Rect.fromLTWH(93, 62, 145, 118), const Color(0xffeadac7));
        box(c, const Rect.fromLTWH(85, 48, 161, 22), navy);
        box(c, const Rect.fromLTWH(105, 99, 121, 68), const Color(0xffb98a60));
        for (var i = 0; i < 8; i++) {
          final x = 119 + (i % 4) * 29.0, y = 111 + (i ~/ 4) * 30.0;
          disc(
            c,
            Offset(x, y),
            step == 1 ? 7 : 4,
            step == 1 ? orange : const Color(0xffe4c48b),
          );
        }
        text(
          c,
          ['原料：大豆 / 盐 / 曲', '微生物参与（符号）', '原料 + 条件 + 时间'][step],
          const Offset(27, 16),
        );
        text(c, '关系模型 · 不按数量比例', const Offset(69, 185), size: 12);
        break;
      default:
        path(c, const [
          Offset(10, 112),
          Offset(65, 37),
          Offset(115, 110),
        ], const Color(0xff9db2a1));
        path(c, const [
          Offset(72, 112),
          Offset(125, 58),
          Offset(180, 119),
        ], const Color(0xffc0ceba));
        box(c, const Rect.fromLTWH(0, 145, 330, 65), const Color(0xffdfebd8));
        box(c, const Rect.fromLTWH(255, 115, 75, 95), const Color(0xffc6e7f3));
        final river = Path()
          ..moveTo(100, 97)
          ..cubicTo(185, 119, 120, 159, 205, 163)
          ..quadraticBezierTo(235, 167, 285, 177);
        c.drawPath(
          river,
          Paint()
            ..color = blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9,
        );
        final branch = Path()
          ..moveTo(55, 130)
          ..quadraticBezierTo(80, 165, 159, 143);
        c.drawPath(
          branch,
          Paint()
            ..color = blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        disc(
          c,
          [
            const Offset(100, 97),
            const Offset(159, 143),
            const Offset(280, 176),
          ][step],
          10,
          orange,
        );
        text(c, ['上游山地', '支流汇合', '下游入海'][step], const Offset(15, 12));
        text(c, '海洋', const Offset(279, 125));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_JapanScene oldDelegate) =>
      kind != oldDelegate.kind || step != oldDelegate.step;
}
