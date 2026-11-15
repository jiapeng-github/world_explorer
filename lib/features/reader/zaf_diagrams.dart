import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Authored concept models, deliberately distinct from documentary photos and
/// the Natural Earth map. No fictional geometry is used for map hit testing.
class ZafDiagram extends StatefulWidget {
  const ZafDiagram(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;
  @override
  State<ZafDiagram> createState() => _ZafDiagramState();
}

class _ZafDiagramState extends State<ZafDiagram> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final (title, labels, explanations, caption) = switch (widget.kind) {
      'zaf-coast-plateau' => (
        '从海岸走向高原',
        ['海岸', '山地与陡崖', '内陆高原'],
        ['陆地与海相接；不同海岸宽度不同。', '地势升高，山坡与谷地影响水流方向。', '海拔较高，也有山丘与河谷。'],
        '地形关系示意 · 不是某条公路的精确剖面',
      ),
      'zaf-two-capes' => (
        '两个海角，谁更靠南？',
        ['好望角 · 南纬34.36°', '厄加勒斯角 · 南纬34.83°'],
        ['好望角在西侧；它不是非洲大陆最南端。', '同在南半球，34.83°比34.36°更靠南。厄加勒斯角是非洲大陆最南端。'],
        '位置比较示意 · 海岸形状请看专属地图',
      ),
      'zaf-penguin-home' => (
        '海里和岸上，都是企鹅的家',
        ['海中觅食', '岸上活动', '减少干扰'],
        ['在海里游泳，寻找鱼类等食物。', '在适合的陆地休息、换羽和繁殖。', '沿步道观察，不触碰、不投喂，不阻挡通道。'],
        '栖息地关系示意 · 不显示具体巢穴',
      ),
      'zaf-food-web' => (
        '食物的联系',
        ['草', '食草动物', '捕食者'],
        ['植物通过光合作用生长。', '一些动物以植物为食。', '一些动物捕食其他动物；真实食物网有更多连接。'],
        '箭头表示食物与能量传递 · 不是动物行走路线',
      ),
      'zaf-wetland' => (
        '追踪湿地里的水',
        ['降雨', '河流与来水', '湿地与海岸'],
        [
          '降雨提供一部分水，变化需要长期记录。',
          '河流和地下水等可参与补给；具体地点情况不同。',
          '水位、盐度和岸边环境会变化，联系着不同生物。',
        ],
        '关系示意 · 不表示实测流量或固定盐度',
      ),
      'zaf-transfer' => (
        '找到共同的车站',
        ['甲站', '乙站 · 换乘', '丙站'],
        ['蓝线从甲站到乙站。', '蓝线与橙线共有乙站，在这里换乘。', '从乙站沿橙线到丙站。'],
        '原创虚构线路 · 不是南非实际交通图',
      ),
      'zaf-languages' => (
        '不同文字，同样欢迎',
        ['Welcome · 英语', 'Welkom · 南非荷兰语'],
        ['Welcome 在此表达“欢迎”。', 'Welkom 在此也表达“欢迎”。语言卡不是实拍路牌。'],
        '原创语言卡 · 南非有12种官方语言，含南非手语',
      ),
      'zaf-market' => (
        '读懂一张标签',
        ['①名称：苹果', '②单位：千克', '③产地：南非'],
        ['说明商品是什么。', '说明按什么方式计量。', '这个字段声明产地；不能只看售卖地点猜来源。'],
        '原创练习标签 · 不代表实拍商品或实时价格',
      ),
      'zaf-recipe' => (
        '配方能告诉我们什么？',
        ['名称：玉米粉粥', '原料：玉米粉、水', '一种练习配方'],
        ['名字帮助认识这份例子。', '这份卡明确写出了两种原料。', '这张卡不代表全国每个家庭的做法。'],
        '原创配方字段练习 · 非全国统一食谱',
      ),
      'zaf-patterns' => (
        '发现重复的规则',
        ['蓝色', '橙色', '蓝色', '橙色'],
        ['蓝、橙是这里的重复单元。', '蓝色之后接橙色。', '新的一组从蓝色开始。', '继续同一规则，下一颗应为蓝色。'],
        '原创排列练习 · 不冒充传统珠饰符号或某种音乐',
      ),
      _ => (
        '把故事放在时间里',
        ['约900—1300年', '20世纪后半叶', '1994年4月', '2023年'],
        [
          '马蓬古布韦的聚落与交流线索。',
          '许多人反对种族隔离，争取自由与权利。',
          '首次不分种族的民主全国选举。',
          '南非手语成为第12种官方语言。',
        ],
        '事件顺序示意 · 节点间距不代表相同年数',
      ),
    };
    final index = selected.clamp(0, labels.length - 1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffeef4f8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AtlasPalette.orange,
                size: 22,
              ),
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
            ],
          ),
          const SizedBox(height: 14),
          if (const {
            'zaf-coast-plateau',
            'zaf-two-capes',
            'zaf-transfer',
            'zaf-food-web',
            'zaf-wetland',
            'zaf-penguin-home',
            'zaf-patterns',
          }.contains(widget.kind)) ...[
            Semantics(
              label: '$title。$caption。${explanations.join(' ')}',
              child: SizedBox(
                height: 138,
                child: CustomPaint(
                  painter: _ZafConceptPainter(widget.kind, index),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final (i, label) in labels.indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: i == index,
                  onSelected: widget.interactive
                      ? (_) => setState(() => selected = i)
                      : null,
                  selectedColor: const Color(0xffffddba),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            explanations[index],
            style: const TextStyle(height: 1.6, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(
              color: AtlasPalette.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZafConceptPainter extends CustomPainter {
  const _ZafConceptPainter(this.kind, this.selected);
  final String kind;
  final int selected;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 138);
    const navy = AtlasPalette.navy, orange = AtlasPalette.orange;
    final line = Paint()
      ..color = navy
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void text(
      String value,
      double x,
      double y, {
      Color color = navy,
      double width = 95,
    }) {
      final p = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'NotoSansSC',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: width);
      p.paint(canvas, Offset(x - p.width / 2, y));
    }

    void dot(double x, double y, int i) {
      canvas.drawCircle(
        Offset(x, y),
        selected == i ? 10 : 7,
        Paint()..color = selected == i ? orange : navy,
      );
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
    }

    void arrow(double x1, double y1, double x2, double y2) {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), line);
      final delta = Offset(x2 - x1, y2 - y1);
      final unit = delta / delta.distance;
      final end = Offset(x2, y2);
      final side = Offset(-unit.dy, unit.dx);
      canvas.drawLine(end, end - unit * 9 + side * 5, line);
      canvas.drawLine(end, end - unit * 9 - side * 5, line);
    }

    if (kind == 'zaf-coast-plateau') {
      canvas.drawRect(
        const Rect.fromLTWH(0, 94, 95, 44),
        Paint()..color = const Color(0xff9bd1e3),
      );
      final land = Path()
        ..moveTo(45, 138)
        ..lineTo(67, 104)
        ..lineTo(96, 100)
        ..lineTo(132, 77)
        ..lineTo(161, 28)
        ..lineTo(184, 48)
        ..lineTo(215, 42)
        ..lineTo(249, 47)
        ..lineTo(300, 36)
        ..lineTo(300, 138)
        ..close();
      canvas.drawPath(land, Paint()..color = const Color(0xffb6c7a0));
      canvas.drawPath(
        land,
        line
          ..color = const Color(0xff58735b)
          ..strokeWidth = 2,
      );
      text('海岸', 55, 67);
      text('山地与陡崖', 155, 3);
      text('内陆高原', 250, 65);
      dot(
        [75.0, 161.0, 250.0][selected],
        [102.0, 28.0, 46.0][selected],
        selected,
      );
    } else if (kind == 'zaf-two-capes') {
      arrow(20, 105, 20, 25);
      text('北', 20, 3);
      dot(85, 50, 0);
      dot(220, 100, 1);
      text('好望角', 85, 12);
      text('34.36°S', 85, 67);
      text('厄加勒斯角', 220, 56);
      text('34.83°S', 220, 114);
      text('更靠南 ↓', 205, 4);
    } else if (kind == 'zaf-transfer') {
      canvas.drawLine(
        const Offset(40, 82),
        const Offset(150, 82),
        line
          ..color = navy
          ..strokeWidth = 6,
      );
      canvas.drawLine(
        const Offset(150, 82),
        const Offset(255, 35),
        line..color = orange,
      );
      dot(40, 82, 0);
      dot(150, 82, 1);
      dot(255, 35, 2);
      text('甲站', 40, 102);
      text('乙站 · 换乘', 150, 102);
      text('丙站', 255, 52);
      text('蓝线', 85, 49);
      text('橙线', 204, 10, color: orange);
    } else if (kind == 'zaf-patterns') {
      for (var i = 0; i < 4; i++) {
        final x = 40.0 + i * 70;
        canvas.drawCircle(
          Offset(x, 55),
          selected == i ? 23 : 19,
          Paint()..color = i.isEven ? navy : orange,
        );
        canvas.drawCircle(Offset(x, 55), 5, Paint()..color = Colors.white);
        text('${i + 1}', x, 88);
      }
      text('重复单元：蓝 → 橙', 150, 112, width: 240);
    } else {
      final labels = switch (kind) {
        'zaf-food-web' => ['草', '食草动物', '捕食者'],
        'zaf-wetland' => ['降雨', '河流', '湿地'],
        _ => ['海中觅食', '岸上活动', '减少干扰'],
      };
      for (var i = 0; i < 3; i++) {
        final x = 45.0 + i * 105;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 60), width: 80, height: 70),
            const Radius.circular(16),
          ),
          Paint()
            ..color = selected == i ? const Color(0xffffddba) : Colors.white,
        );
        dot(x, 47, i);
        text(labels[i], x, 70, width: 80);
        if (i < 2) arrow(x + 43, 60, x + 61, 60);
      }
      text(
        kind == 'zaf-food-web' ? '食物与能量传递方向' : '从一处线索，想到另一处联系',
        150,
        112,
        width: 280,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ZafConceptPainter old) =>
      old.kind != kind || old.selected != selected;
}
