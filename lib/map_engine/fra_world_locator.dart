import 'package:flutter/material.dart';

import '../design/atlas_theme.dart';
import 'atlas_map.dart';

/// World position context uses the shipped Natural Earth geometry. The three
/// ocean target boxes are labelled learning areas, never maritime boundaries.
class FraWorldLocator extends StatelessWidget {
  const FraWorldLocator({
    super.key,
    this.selected,
    this.onSelect,
    this.oceanExercise = false,
  });
  final String? selected;
  final ValueChanged<String>? onSelect;
  final bool oceanExercise;
  static const oceanCenters = {
    'fra-ocean-indian': (-18.0, 80.0, '印度洋'),
    'fra-ocean-atlantic': (10.0, -35.0, '大西洋'),
    'fra-ocean-pacific': (0.0, -140.0, '太平洋'),
  };
  @override
  Widget build(BuildContext context) => FutureBuilder<AtlasGeometry>(
    future: AtlasGeometry.load(),
    builder: (context, snapshot) => Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, limits) {
              final size = Size(limits.maxWidth, limits.maxHeight);
              Offset pixel(double lat, double lon) => Offset(
                (lon + 180) / 360 * size.width,
                (90 - lat) / 180 * size.height,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LocatorPainter(snapshot.data, selected),
                    ),
                  ),
                  if (oceanExercise)
                    for (final item in oceanCenters.entries)
                      Positioned(
                        left: pixel(item.value.$1, item.value.$2).dx - 34,
                        top: pixel(item.value.$1, item.value.$2).dy - 24,
                        child: Semantics(
                          button: true,
                          selected: selected == item.key,
                          label: item.value.$3,
                          child: Material(
                            color: selected == item.key
                                ? AtlasPalette.orange
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: onSelect == null
                                  ? null
                                  : () => onSelect!(item.key),
                              child: SizedBox(
                                width: 68,
                                height: 48,
                                child: Center(
                                  child: Text(
                                    item.value.$3,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        const Text(
          '世界位置示意 · Natural Earth。海域按钮是教学定位范围，并非海洋边界。',
          style: TextStyle(fontSize: 11, color: AtlasPalette.muted),
        ),
        const Text(
          '留尼汪在马达加斯加以东 · 各地区地图使用独立比例尺',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class _LocatorPainter extends CustomPainter {
  const _LocatorPainter(this.geometry, this.selected);
  final AtlasGeometry? geometry;
  final String? selected;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xffd9edf6));
    c.save();
    c.scale(s.width / 1800, s.height / 900);
    if (geometry != null) {
      c.drawPath(geometry!.land, Paint()..color = const Color(0xffbdcbbb));
    }
    c.restore();
    for (final (lat, lon, label) in [
      (46.5, 3.0, '欧洲'),
      (16.2, -61.5, '加勒比海'),
      (4.0, -53.2, '法属圭亚那'),
      (-21.1, 55.5, '留尼汪'),
      (-12.8, 45.15, '马约特'),
    ]) {
      final p = Offset(
        (lon + 180) / 360 * s.width,
        (90 - lat) / 180 * s.height,
      );
      c.drawCircle(p, 4, Paint()..color = AtlasPalette.orange);
      if (selected != null) continue;
      final t = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 10,
            color: AtlasPalette.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, p + Offset(5, label == '马约特' ? -15 : 2));
    }
  }

  @override
  bool shouldRepaint(_LocatorPainter old) =>
      old.geometry != geometry || old.selected != selected;
}
