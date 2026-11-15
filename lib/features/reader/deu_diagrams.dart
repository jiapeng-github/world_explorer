import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original teaching relationships; geometry is intentionally not a map.
class DeuDiagram extends StatefulWidget {
  const DeuDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<DeuDiagram> createState() => _DeuDiagramState();
}

class _DeuDiagramState extends State<DeuDiagram> {
  int step = 0;
  Timer? timer;
  @override
  void didUpdateWidget(covariant DeuDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      timer?.cancel();
      step = 0;
    }
  }

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
    final (title, labels, note) = switch (k) {
      'deu-river' => (
        '河流会越过国界',
        ['一条河流', '不同国家', '继续向下游'],
        '原创关系示意 · 虚线是假设国界，不是莱茵河实际路线。',
      ),
      'deu-landscapes' => (
        '从北部低地到南方高山',
        ['北部低地', '中部山地', '南部阿尔卑斯'],
        '概略地形关系 · 并非整齐的三条色带，不按海拔比例。',
      ),
      'deu-transfer' => (
        '在共同站点换乘',
        ['甲站', '乙站 · 换乘', '丙站'],
        '原创虚构线路 · 蓝线甲—乙，橙线乙—丙。',
      ),
      'deu-food-flow' => (
        '土豆走到餐桌之前',
        ['种植与收获', '运输与整理', '烹调与食用'],
        '原创流程示意 · 不同食品可能经过不同环节。',
      ),
      'deu-type' => (
        '活字可以重新组合',
        ['排字', '上墨与压印', '拆开再组合'],
        '字模印刷面与纸上印迹互为镜像；示意不是历史文物。',
      ),
      'deu-rhythm' => (
        '一起回应四拍',
        ['1', '2', '3', '4'],
        '每拍间隔相同 · 这是原创节拍练习，不代表所有德国音乐。',
      ),
      'deu-deadwood' => (
        '倒木仍在参与森林生活',
        ['倒木', '真菌与小动物', '养分循环'],
        '原创关系示意 · 分解逐渐进行，箭头不表示精确时间。',
      ),
      _ => ('潮水往返，滩面露出与淹没', ['低潮', '高潮'], '同一剖面，只改变水位；不提供现场潮时或步行路线。'),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffedf3f7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AtlasPalette.navy,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '$title。${labels.join('，')}。$note',
            child: SizedBox(
              height: 150,
              child: CustomPaint(painter: _DeuPainter(k, step)),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8,
            runSpacing: 5,
            children: [
              for (final (i, label) in labels.indexed)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: k == 'deu-rhythm' && step == i + 1
                        ? AtlasPalette.orange
                        : AtlasPalette.navy,
                  ),
                ),
            ],
          ),
          if (widget.interactive && k == 'deu-rhythm')
            TextButton.icon(
              onPressed: play,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('播放四拍'),
            ),
          if (widget.interactive && (k == 'deu-tides' || k == 'deu-type'))
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 2; i++)
                  ChoiceChip(
                    label: Text(
                      k == 'deu-tides' ? ['低潮', '高潮'][i] : ['第一组字', '重新排列'][i],
                    ),
                    selected: step == i,
                    onSelected: (_) => setState(() => step = i),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AtlasPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeuPainter extends CustomPainter {
  _DeuPainter(this.kind, this.step);
  final String kind;
  final int step;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 330, size.height / 150);
    const blue = Color(0xff2984ad),
        green = Color(0xff6c916b),
        brown = Color(0xff906b45);
    void line(Offset a, Offset b, Color c, [double w = 4]) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = c
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    void text(
      String s,
      Offset p, [
      double fs = 18,
      Color color = AtlasPalette.navy,
    ]) {
      final t = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: fs,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, p - Offset(t.width / 2, t.height / 2));
      t.dispose();
    }

    void arrow(Offset a, Offset b) {
      line(a, b, AtlasPalette.orange, 3);
      final d = b - a;
      final u = d / d.distance;
      final n = Offset(-u.dy, u.dx);
      line(b, b - u * 9 + n * 5, AtlasPalette.orange, 3);
      line(b, b - u * 9 - n * 5, AtlasPalette.orange, 3);
    }

    if (kind == 'deu-river') {
      for (final x in [105.0, 225.0]) {
        for (double y = 8; y < 144; y += 16) {
          line(Offset(x, y), Offset(x, y + 8), const Color(0xff94a6b7), 2);
        }
      }
      final p = Path()
        ..moveTo(15, 110)
        ..cubicTo(65, 15, 95, 125, 150, 65)
        ..cubicTo(205, 5, 235, 125, 310, 30);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..color = blue
          ..strokeCap = StrokeCap.round,
      );
      arrow(const Offset(275, 71), const Offset(302, 44));
    } else if (kind == 'deu-landscapes') {
      final p = Path()
        ..moveTo(0, 124)
        ..lineTo(10, 105)
        ..lineTo(75, 104)
        ..lineTo(110, 80)
        ..lineTo(135, 102)
        ..lineTo(170, 60)
        ..lineTo(195, 103)
        ..lineTo(242, 20)
        ..lineTo(268, 65)
        ..lineTo(295, 6)
        ..lineTo(330, 98)
        ..lineTo(330, 135)
        ..lineTo(0, 135)
        ..close();
      canvas.drawPath(p, Paint()..color = green);
      final snow = Path()
        ..moveTo(231, 40)
        ..lineTo(242, 20)
        ..lineTo(254, 42)
        ..lineTo(243, 36)
        ..close();
      canvas.drawPath(snow, Paint()..color = Colors.white);
      text('北 → 南', const Offset(70, 40), 15);
    } else if (kind == 'deu-transfer') {
      line(const Offset(35, 110), const Offset(165, 55), blue, 7);
      line(
        const Offset(165, 55),
        const Offset(295, 110),
        AtlasPalette.orange,
        7,
      );
      for (final p in [
        const Offset(35, 110),
        const Offset(165, 55),
        const Offset(295, 110),
      ]) {
        canvas.drawCircle(p, 13, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          13,
          Paint()
            ..color = AtlasPalette.navy
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      text('蓝线', const Offset(82, 56), 16, blue);
      text('橙线', const Offset(251, 56), 16, AtlasPalette.orange);
    } else if (kind == 'deu-type') {
      final letters = step == 0 ? ['A', 'B', 'C'] : ['C', 'A', 'B'];
      for (var i = 0; i < 3; i++) {
        final x = 62.0 + i * 100;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 55), width: 62, height: 64),
            const Radius.circular(7),
          ),
          Paint()..color = const Color(0xffced7de),
        );
        canvas.save();
        canvas.translate(x * 2, 0);
        canvas.scale(-1, 1);
        text(letters[i], Offset(x, 55), 32);
        canvas.restore();
        text(letters[i], Offset(x, 125), 25);
        arrow(Offset(x, 90), Offset(x, 105));
      }
    } else if (kind == 'deu-rhythm') {
      for (var i = 0; i < 4; i++) {
        final p = Offset(42 + i * 82, 75);
        canvas.drawCircle(
          p,
          27,
          Paint()..color = step == i + 1 ? AtlasPalette.orange : Colors.white,
        );
        text('${i + 1}', p, 24);
      }
    } else if (kind == 'deu-deadwood') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 65, 80, 32),
          const Radius.circular(14),
        ),
        Paint()..color = brown,
      );
      for (final y in [73.0, 84.0, 92.0]) {
        line(Offset(14, y), Offset(70, y - 2), const Color(0xffc49b70), 2);
      }
      line(const Offset(166, 60), const Offset(166, 100), brown, 7);
      canvas.drawArc(
        const Rect.fromLTWH(137, 35, 58, 48),
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xffc48252),
      );
      canvas.drawOval(
        const Rect.fromLTWH(187, 94, 17, 10),
        Paint()..color = brown,
      );
      line(const Offset(240, 110), const Offset(326, 110), brown, 10);
      line(const Offset(280, 105), const Offset(280, 52), green, 5);
      canvas.drawOval(
        const Rect.fromLTWH(255, 59, 25, 14),
        Paint()..color = green,
      );
      canvas.drawOval(
        const Rect.fromLTWH(281, 42, 25, 14),
        Paint()..color = green,
      );
      arrow(const Offset(96, 78), const Offset(128, 78));
      arrow(const Offset(208, 78), const Offset(239, 78));
    } else if (kind == 'deu-food-flow') {
      for (final (i, label) in ['田间', '运输', '餐桌'].indexed) {
        final x = 53.0 + i * 112;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 73), width: 80, height: 75),
            const Radius.circular(15),
          ),
          Paint()..color = Colors.white,
        );
        text(label, Offset(x, 73), 19);
        if (i < 2) arrow(Offset(x + 44, 73), Offset(x + 66, 73));
      }
    } else {
      final land = Path()
        ..moveTo(0, 35)
        ..lineTo(90, 85)
        ..lineTo(220, 110)
        ..lineTo(330, 120)
        ..lineTo(330, 150)
        ..lineTo(0, 150)
        ..close();
      canvas.drawPath(land, Paint()..color = const Color(0xffcbb697));
      final y = step == 0 ? 110.0 : 62.0;
      canvas.drawRect(
        Rect.fromLTRB(0, y, 330, 150),
        Paint()..color = blue.withValues(alpha: .55),
      );
      line(Offset(0, y), Offset(330, y), blue, 3);
      text(step == 0 ? '露出的潮滩' : '被水覆盖的滩面', const Offset(210, 30), 17);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DeuPainter old) => kind != old.kind || step != old.step;
}
