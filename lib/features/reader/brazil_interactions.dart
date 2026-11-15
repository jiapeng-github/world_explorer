import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Original teaching models; neither geographic boundaries nor measured data.
class BrazilInteraction extends StatefulWidget {
  const BrazilInteraction(this.kind, {super.key, this.interactive = true});
  final String kind;
  final bool interactive;

  @override
  State<BrazilInteraction> createState() => _BrazilInteractionState();
}

class _BrazilInteractionState extends State<BrazilInteraction> {
  int selected = 0;
  int responses = 0;
  Timer? timer;
  bool playing = false;

  void stop() {
    timer?.cancel();
    timer = null;
    playing = false;
  }

  @override
  void didUpdateWidget(BrazilInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind || !widget.interactive) {
      stop();
      selected = 0;
      responses = 0;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void play() {
    stop();
    setState(() {
      selected = 0;
      responses = 0;
      playing = true;
    });
    timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      setState(() {
        if (selected == 3) {
          stop();
        } else {
          selected++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final rhythm = widget.kind == 'brazil-rhythm';
    final wetland = widget.kind == 'brazil-wetland';
    final steps = switch (widget.kind) {
      'brazil-wetland' => const [
        ('较湿时期', Icons.water, '水位较高，低处更多地面被水覆盖；动物可以使用的水面与陆地空间随之改变。'),
        ('较干时期', Icons.grass, '水位较低，更多地面露出；水域、取食植物与陆地休息空间仍然相互联系。'),
      ],
      'brazil-forest-layers' => const [
        ('树冠', Icons.forest, '树木上部的枝叶形成树冠，通常能接收到更多阳光。实际森林有高低与空隙。'),
        ('林下', Icons.park_outlined, '树冠下方也有植物。枝叶遮挡部分光线，不同高度的环境条件不同。'),
        ('地面', Icons.grass, '林地有落叶、植物与动物活动。这里不是与上层隔绝的房间。'),
      ],
      'brazil-market-labels' => const [
        ('名称', Icons.local_grocery_store_outlined, '名称：可可豆。回答“它是什么商品”。'),
        ('单位', Icons.scale_outlined, '单位：千克。回答“用什么单位计量”。'),
        ('产地', Icons.place_outlined, '产地：巴西·巴伊亚州。回答“原料来自哪里”。'),
      ],
      'brazil-cacao' => const [
        ('果实与种子', Icons.eco_outlined, '可可果实内部有种子，也就是可可豆。巧克力不是直接由整块果皮制成。'),
        ('发酵与干燥', Icons.wb_sunny_outlined, '取出的种子经过发酵、干燥等处理，材料的状态发生变化。'),
        ('烘焙与研磨', Icons.settings_outlined, '可可豆进一步加工为制作巧克力的原料。这里是关系示意，不是操作配方。'),
        ('巧克力', Icons.grid_view_rounded, '原料与其他配料组合，成为不同产品；配方与生产方式并不完全相同。'),
      ],
      'brazil-place-names' => const [
        ('中文', Icons.translate, '巴西利亚：这个地方的中文名称。'),
        ('葡萄牙语', Icons.language, 'Brasília：同一座城市的葡萄牙语名称。'),
        ('位置', Icons.location_on_outlined, '巴西内陆的首都。不同写法需要通过地点与资料相互核对。'),
      ],
      'brazil-rhythm' => const [
        ('第1拍', Icons.circle_outlined, '四个拍点依次出现，演示间隔相等。'),
        ('第2拍', Icons.circle_outlined, '注意拍点之间的间隔，再观察下一拍。'),
        ('第3拍', Icons.circle_outlined, '次数和间隔是两个不同的线索。'),
        ('第4拍', Icons.circle_outlined, '一轮四拍结束后，可以轻点回应；这不是音乐能力评分。'),
      ],
      _ => const <(String, IconData, String)>[],
    };
    if (steps.isEmpty) return const SizedBox.shrink();
    final title = switch (widget.kind) {
      'brazil-wetland' => '水位改变，空间也改变',
      'brazil-forest-layers' => '从树冠到地面',
      'brazil-market-labels' => '一张标签，三种信息',
      'brazil-cacao' => '从可可果到巧克力',
      'brazil-place-names' => '两个名字，同一个地方',
      _ => '看一轮四拍，再试着回应',
    };
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff0f6f2),
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
          Text(
            rhythm
                ? '原创视觉节拍练习 · 不是弗雷沃或卡波耶拉乐曲'
                : wetland
                ? '同一地形的水位示意 · 非实测水深或季节照片'
                : '原创教学示意 · 不表示真实比例或完整生产记录',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AtlasPalette.muted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, step) in steps.indexed)
                ChoiceChip(
                  label: Text(step.$1),
                  avatar: Icon(step.$2, size: 18),
                  selected: selected == i,
                  onSelected: widget.interactive
                      ? (_) => setState(() {
                          stop();
                          selected = i;
                        })
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (wetland || widget.kind == 'brazil-forest-layers')
            Semantics(
              image: true,
              label: wetland
                  ? selected == 0
                        ? '较高水位覆盖更多低地，同一地形保持不变'
                        : '较低水位露出更多地面，同一地形保持不变'
                  : '树冠在上、林下在中、地面在下；光线从上方照入森林',
              child: SizedBox(
                height: 170,
                child: CustomPaint(
                  painter: BrazilHabitatPainter(
                    wetland: wetland,
                    selected: selected,
                  ),
                ),
              ),
            ),
          if (widget.kind == 'brazil-market-labels' ||
              widget.kind == 'brazil-place-names')
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.kind == 'brazil-market-labels'
                    ? const ['名称：可可豆', '单位：千克', '产地：巴西·巴伊亚州'][selected]
                    : const ['巴西利亚', 'Brasília', '巴西内陆 · 首都'][selected],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AtlasPalette.navy,
                ),
              ),
            ),
          if (widget.kind == 'brazil-cacao')
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 12,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  CircleAvatar(
                    radius: selected == i ? 28 : 23,
                    backgroundColor: selected == i
                        ? AtlasPalette.orange
                        : Colors.white,
                    child: Icon(steps[i].$2, color: AtlasPalette.navy),
                  ),
                  if (i < steps.length - 1)
                    const Icon(Icons.arrow_forward, size: 18),
                ],
              ],
            ),
          if (rhythm) ...[
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Semantics(
                      label: '第${i + 1}拍',
                      selected: selected == i,
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected == i
                              ? AtlasPalette.orange
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.interactive) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: reducedMotion
                        ? () => setState(() {
                            stop();
                            selected = (selected + 1) % 4;
                          })
                        : playing
                        ? () => setState(stop)
                        : play,
                    icon: Icon(
                      reducedMotion
                          ? Icons.skip_next
                          : playing
                          ? Icons.stop
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      reducedMotion
                          ? '下一拍'
                          : playing
                          ? '停止'
                          : '播放四拍',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: playing
                        ? null
                        : () => setState(() => responses = (responses % 4) + 1),
                    child: const Text('轻点回应'),
                  ),
                ],
              ),
              Text(
                '本轮已回应 $responses / 4 拍',
                style: const TextStyle(height: 1.8),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Semantics(
            liveRegion: !rhythm || !playing,
            child: Text(
              steps[selected].$3,
              style: const TextStyle(fontSize: 16, height: 1.65),
            ),
          ),
          if (wetland) ...[
            const Divider(height: 24),
            Text(
              selected == 0
                  ? '水：覆盖更多低地\n植物：部分地面植物被水包围\n动物：使用水域，也需要合适的陆地空间'
                  : '水：更多集中在低处\n植物：更多陆地空间显露\n动物：活动范围随可用环境改变',
              style: const TextStyle(height: 1.8),
            ),
          ],
        ],
      ),
    );
  }
}

class BrazilHabitatPainter extends CustomPainter {
  const BrazilHabitatPainter({required this.wetland, required this.selected});
  final bool wetland;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 170);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 320, 170),
      Paint()..color = const Color(0xffe6f0f4),
    );
    if (wetland) {
      final terrain = Path()
        ..moveTo(0, 60)
        ..cubicTo(40, 65, 70, 145, 140, 142)
        ..cubicTo(200, 140, 245, 80, 320, 50)
        ..lineTo(320, 170)
        ..lineTo(0, 170)
        ..close();
      final air = Path.combine(
        PathOperation.difference,
        Path()..addRect(const Rect.fromLTWH(0, 0, 320, 170)),
        terrain,
      );
      canvas.drawPath(terrain, Paint()..color = const Color(0xff7ca467));
      canvas.save();
      canvas.clipPath(air);
      final y = selected == 0 ? 85.0 : 125.0;
      canvas.drawRect(
        Rect.fromLTRB(0, y, 320, 170),
        Paint()..color = const Color(0xff629fc0),
      );
      for (var i = 0; i < 8; i++) {
        canvas.drawLine(
          Offset(i * 45.0, y + 12),
          Offset(i * 45.0 + 20, y + 12),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2,
        );
      }
      canvas.restore();
      for (final x in [22.0, 292.0]) {
        canvas.drawLine(
          Offset(x, 70),
          Offset(x, 36),
          Paint()
            ..color = const Color(0xff397852)
            ..strokeWidth = 3,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 33), width: 20, height: 18),
          Paint()..color = const Color(0xff397852),
        );
      }
    } else {
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(0, 10 + i * 50.0, 320, 50),
          Paint()
            ..color = [
              const Color(0xffa8cdb1),
              const Color(0xff78ab8a),
              const Color(0xff527d62),
            ][i].withValues(alpha: selected == i ? 1 : .4),
        );
      }
      for (final (x, h) in [
        (45.0, 50.0),
        (120.0, 22.0),
        (190.0, 48.0),
        (270.0, 32.0),
      ]) {
        canvas.drawLine(
          Offset(x, 155),
          Offset(x, h),
          Paint()
            ..color = const Color(0xff84694a)
            ..strokeWidth = 8,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, h + 10), width: 65, height: 48),
          Paint()..color = const Color(0xff397852),
        );
      }
      canvas.drawCircle(
        const Offset(300, 18),
        12,
        Paint()..color = const Color(0xffffbd45),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrazilHabitatPainter old) =>
      old.selected != selected || old.wetland != wetland;
}
