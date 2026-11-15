import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original teaching relationships; geometry is intentionally not a map.
class KenyaDiagram extends StatefulWidget {
  const KenyaDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<KenyaDiagram> createState() => _KenyaDiagramState();
}

class _KenyaDiagramState extends State<KenyaDiagram> {
  int step = 0;
  Timer? timer;
  @override
  void didUpdateWidget(covariant KenyaDiagram oldWidget) {
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
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => step = step % 4 + 1);
      return;
    }
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
      'kenya-altitude' => (
        '海拔升高，环境也会改变',
        ['山麓', '山坡', '高处岩峰'],
        '原创剖面示意 · 不是温度实测或精确植被分界。',
      ),
      'kenya-rift' => (
        '地壳伸展与裂谷',
        ['两侧伸展', '断裂', '相对低陷'],
        '原创过程示意 · 地质变化经历很长时间，不按比例。',
      ),
      'kenya-water' => (
        '雨水的不同去向',
        ['地表径流', '下渗', '蒸发'],
        '原创水循环示意 · 并非所有湖泊都有流向海洋的出口。',
      ),
      'kenya-transfer' => (
        '在共同站点换乘',
        ['甲站', '乙站 · 换乘', '丙站'],
        '原创虚构线路 · 蓝线甲—乙，橙线乙—丙。',
      ),
      'kenya-maize' => (
        '从玉米到餐桌',
        ['玉米粒', '研磨成粉', '加水烹调'],
        '原创流程示意 · ugali是烹调成品，不是生玉米粒。',
      ),
      'kenya-rhythm' => (
        '一起回应四拍',
        ['1', '2', '3', '4'],
        '原创等间隔节拍练习 · 不是Isukuti传统音乐的转录。',
      ),
      'kenya-habitat' => (
        '生活空间需要连接',
        ['食物', '连通空间', '水源'],
        '原创关系示意 · 不表示动物每天必走的固定路线。',
      ),
      _ => ('潮水与红树林根系', ['低潮', '高潮'], '原创同一剖面示意 · 根系形态因树种而异，不提供现场潮时。'),
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
              child: CustomPaint(painter: _KenyaPainter(k, step)),
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
                    color: k == 'kenya-rhythm' && step == i + 1
                        ? AtlasPalette.orange
                        : AtlasPalette.navy,
                  ),
                ),
            ],
          ),
          if (widget.interactive && k == 'kenya-rhythm')
            TextButton.icon(
              onPressed: play,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('播放四拍'),
            ),
          if (widget.interactive && k == 'kenya-mangrove')
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 2; i++)
                  ChoiceChip(
                    label: Text(['低潮', '高潮'][i]),
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

class _KenyaPainter extends CustomPainter {
  _KenyaPainter(this.kind, this.step);
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

    if (kind == 'kenya-altitude') {
      final mountain = Path()
        ..moveTo(10, 135)
        ..lineTo(155, 10)
        ..lineTo(175, 40)
        ..lineTo(200, 20)
        ..lineTo(320, 135)
        ..close();
      canvas.drawPath(mountain, Paint()..color = green);
      canvas.save();
      canvas.clipPath(mountain);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 330, 55),
        Paint()..color = const Color(0xff9b9b96),
      );
      canvas.drawRect(
        const Rect.fromLTWH(0, 55, 330, 35),
        Paint()..color = const Color(0xffa6b488),
      );
      canvas.restore();
      arrow(const Offset(300, 110), const Offset(300, 25));
      text('海拔', const Offset(300, 12), 14);
    } else if (kind == 'kenya-rift') {
      for (final r in [
        const Rect.fromLTWH(10, 50, 95, 85),
        const Rect.fromLTWH(115, 85, 100, 50),
        const Rect.fromLTWH(225, 50, 95, 85),
      ]) {
        canvas.drawRect(r, Paint()..color = brown);
        canvas.drawRect(
          Rect.fromLTWH(r.left, r.top, r.width, 12),
          Paint()..color = green,
        );
      }
      arrow(const Offset(95, 25), const Offset(35, 25));
      arrow(const Offset(235, 25), const Offset(295, 25));
      arrow(const Offset(165, 40), const Offset(165, 70));
    } else if (kind == 'kenya-water') {
      final land = Path()
        ..moveTo(0, 60)
        ..lineTo(90, 55)
        ..lineTo(160, 110)
        ..lineTo(330, 110)
        ..lineTo(330, 150)
        ..lineTo(0, 150)
        ..close();
      canvas.drawPath(land, Paint()..color = green);
      canvas.drawOval(
        const Rect.fromLTWH(195, 100, 120, 24),
        Paint()..color = blue,
      );
      arrow(const Offset(65, 70), const Offset(145, 99));
      arrow(const Offset(115, 107), const Offset(115, 140));
      arrow(const Offset(250, 92), const Offset(250, 35));
      for (double x = 25; x < 90; x += 18) {
        line(Offset(x, 18), Offset(x - 5, 35), blue, 3);
      }
    } else if (kind == 'kenya-transfer') {
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
    } else if (kind == 'kenya-rhythm') {
      for (var i = 0; i < 4; i++) {
        final p = Offset(42 + i * 82, 75);
        canvas.drawCircle(
          p,
          27,
          Paint()..color = step == i + 1 ? AtlasPalette.orange : Colors.white,
        );
        text('${i + 1}', p, 24);
      }
    } else if (kind == 'kenya-habitat') {
      canvas.drawOval(
        const Rect.fromLTWH(5, 35, 110, 95),
        Paint()..color = green.withValues(alpha: .6),
      );
      canvas.drawOval(
        const Rect.fromLTWH(220, 45, 105, 80),
        Paint()..color = blue.withValues(alpha: .6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(90, 65, 150, 35),
          const Radius.circular(12),
        ),
        Paint()..color = green.withValues(alpha: .35),
      );
      text('食物', const Offset(55, 80), 18);
      text('水', const Offset(278, 80), 18);
      line(
        const Offset(120, 82),
        const Offset(210, 82),
        AtlasPalette.orange,
        3,
      );
    } else if (kind == 'kenya-maize') {
      for (final (i, label) in ['玉米粒', '玉米粉', 'ugali'].indexed) {
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
      line(const Offset(120, 85), const Offset(120, 20), brown, 9);
      for (final x in [85.0, 105.0, 140.0, 160.0]) {
        line(const Offset(120, 60), Offset(x, 118), brown, 4);
      }
      canvas.drawOval(
        const Rect.fromLTWH(70, 0, 105, 48),
        Paint()..color = green,
      );
      final y = step == 0 ? 110.0 : 78.0;
      canvas.drawRect(
        Rect.fromLTRB(0, y, 330, 150),
        Paint()..color = blue.withValues(alpha: .55),
      );
      line(Offset(0, y), Offset(330, y), blue, 3);
      text(step == 0 ? '部分根系露出' : '水位升高', const Offset(255, 30), 15);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KenyaPainter old) => kind != old.kind || step != old.step;
}
