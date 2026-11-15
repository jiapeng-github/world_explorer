import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/services.dart';
import '../../../design/components.dart';
import '../../../domain/atlas_content.dart';
import 'antarctica_screen.dart';

/// WGS84 Antarctic polar stereographic, standard parallel 71 degrees south.
/// Geometry stays continuous at +/-180 degrees; the pole is explicitly finite.
Offset antarcticProject(double latitude, double longitude) {
  if (latitude <= -90) return Offset.zero;
  const a = 6378137.0, e = 0.08181919084262149;
  final phi = -latitude * math.pi / 180,
      lambda = longitude * math.pi / 180,
      phiC = 71 * math.pi / 180;
  double t(double p) =>
      math.tan(math.pi / 4 - p / 2) /
      math.pow((1 - e * math.sin(p)) / (1 + e * math.sin(p)), e / 2);
  final m = math.cos(phiC) / math.sqrt(1 - e * e * math.pow(math.sin(phiC), 2));
  final rho = a * m * t(phi) / t(phiC);
  return Offset(rho * math.sin(lambda), -rho * math.cos(lambda));
}

class AntarcticaMapScreen extends StatefulWidget {
  const AntarcticaMapScreen({
    super.key,
    this.placeId,
    this.onPicked,
    this.initialView,
  });
  final String? placeId;
  final String? initialView;
  final ValueChanged<AtlasPlace>? onPicked;
  @override
  State<AntarcticaMapScreen> createState() => _AntarcticaMapScreenState();
}

class _AntarcticaMapScreenState extends State<AntarcticaMapScreen> {
  final transform = TransformationController();
  final search = TextEditingController();
  double mapEdge = 390;
  bool initialCameraApplied = false;
  String view = '全洲';
  AtlasPlace? selected;
  bool land = true, places = true, shelves = true;
  final sheet = DraggableScrollableController();
  late Future<List<AntCoast>> geometry;
  @override
  void initState() {
    super.initState();
    geometry = loadGeometry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selected ??= context.atlas.content.place(widget.placeId ?? '');
  }

  static Future<List<AntCoast>> loadGeometry() async {
    final bytes = await rootBundle.load('assets/atlas/antarctica-coast.json');
    final j = jsonDecode(
      utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
    return [
      for (final f in j['features'])
        AntCoast(f['attributes']['surface'], [
          for (final ring in f['geometry']['rings'])
            [
              for (final p in ring)
                Offset((p[0] as num).toDouble(), -(p[1] as num).toDouble()),
            ],
        ]),
    ];
  }

  @override
  void dispose() {
    sheet.dispose();
    transform.dispose();
    search.dispose();
    super.dispose();
  }

  List<AtlasPlace> get points => context.atlas.content.places
      .where((p) => p.regionId == 'antarctica')
      .toList();
  void choose(AtlasPlace p) {
    setState(() => selected = p);
    final q = antarcticProject(p.latitude, p.longitude);
    focus(q, 2.0);
    if (sheet.isAttached) {
      sheet.animateTo(
        .5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void preset(String v) {
    setState(() => view = v);
    final p = v == '南极半岛'
        ? antarcticProject(-66, -64)
        : v == '罗斯海'
        ? antarcticProject(-77, 175)
        : Offset.zero;
    final zoom = v == '全洲' ? 1.0 : 2.2;
    focus(p, zoom);
  }

  void focus(Offset p, double zoom) {
    final point = Offset(mapEdge / 2, mapEdge / 2) + p * (mapEdge / 8000000);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        mapEdge / 2 - point.dx * zoom,
        mapEdge / 2 - point.dy * zoom,
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  Widget detail(BuildContext c, [ScrollController? scroll]) {
    final p = selected;
    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scroll != null)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xffc6d4df),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索地点或科考站',
            ),
          ),
          if (search.text.isNotEmpty)
            for (final x in points.where(
              (p) => ('${p.name} ${p.aliases.join(' ')}')
                  .toLowerCase()
                  .contains(search.text.toLowerCase()),
            ))
              ListTile(title: Text(x.name), onTap: () => choose(x)),
          if (search.text.isNotEmpty &&
              !points.any(
                (p) => ('${p.name} ${p.aliases.join(' ')}')
                    .toLowerCase()
                    .contains(search.text.toLowerCase()),
              ))
            const Text('没有找到地点，试试“中山站”。'),
          if (p != null) ...[
            heading(p.name),
            if (p.mediaIds.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MediaPhoto(
                  p.mediaIds.first,
                  height: 160,
                  width: double.infinity,
                ),
              ),
            const SizedBox(height: 12),
            Text(p.description, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            if (widget.onPicked != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onPicked!(p),
                  child: Text('选择：${p.name}'),
                ),
              )
            else
              action(c, '查看地点', '/places/${p.id}'),
          ] else ...[
            heading('从地图开始探索'),
            const Text('点选地点，或从列表中选择。'),
            for (final p in points)
              ListTile(
                title: Text(p.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => choose(p),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('南极地图')),
    body: LayoutBuilder(
      builder: (c, b) {
        final wide = b.maxWidth >= 850;
        final map = Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final v in ['全洲', '南极半岛', '罗斯海'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(v),
                        selected: view == v,
                        onSelected: (_) => preset(v),
                      ),
                    ),
                  FilterChip(
                    label: const Text('陆地'),
                    selected: land,
                    onSelected: (v) => setState(() => land = v),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('冰架'),
                    selected: shelves,
                    onSelected: (v) => setState(() => shelves = v),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('地点'),
                    selected: places,
                    onSelected: (v) => setState(() => places = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AntCoast>>(
                future: geometry,
                builder: (c, s) {
                  if (s.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => geometry = loadGeometry()),
                        child: const Text('地图暂不可用 · 重试（地点列表仍可使用）'),
                      ),
                    );
                  }
                  if (!s.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return LayoutBuilder(
                    builder: (c, b) {
                      final edge = math.min(b.maxWidth, b.maxHeight);
                      mapEdge = edge;
                      if (!initialCameraApplied) {
                        initialCameraApplied = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (widget.initialView == 'ross') {
                            preset('罗斯海');
                          } else if (widget.initialView == 'peninsula') {
                            preset('南极半岛');
                          } else if (selected != null) {
                            focus(
                              antarcticProject(
                                selected!.latitude,
                                selected!.longitude,
                              ),
                              1.6,
                            );
                          }
                        });
                      }

                      return Center(
                        child: SizedBox(
                          width: edge,
                          height: edge,
                          child: InteractiveViewer(
                            transformationController: transform,
                            minScale: 1,
                            maxScale: 5,
                            child: GestureDetector(
                              onTapUp: (d) {
                                if (!places) return;
                                final at = d.localPosition;
                                AtlasPlace? near;
                                final hits = <AtlasPlace>[];
                                var distance = 28.0;
                                for (final p in points) {
                                  final q =
                                      Offset(edge / 2, edge / 2) +
                                      antarcticProject(
                                            p.latitude,
                                            p.longitude,
                                          ) *
                                          (edge / 8000000);
                                  final dist = (at - q).distance;
                                  if (dist < 20) hits.add(p);
                                  if (dist < distance) {
                                    distance = dist;
                                    near = p;
                                  }
                                }
                                if (hits.length > 1) {
                                  showModalBottomSheet<void>(
                                    context: c,
                                    builder: (ctx) => SafeArea(
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: [
                                          const ListTile(
                                            title: Text('这些地点靠得很近'),
                                          ),
                                          for (final p in hits)
                                            ListTile(
                                              title: Text(p.name),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                choose(p);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (near != null) {
                                  choose(near);
                                }
                              },
                              child: CustomPaint(
                                size: Size.square(edge),
                                painter: _PolarPainter(
                                  s.data!,
                                  points,
                                  selected,
                                  land,
                                  places,
                                  shelves,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 12,
                children: [
                  ValueListenableBuilder<Matrix4>(
                    valueListenable: transform,
                    builder: (c, m, _) => SizedBox(
                      width: 120,
                      child: Column(
                        children: [
                          Text(
                            '约 ${(8000000 / mapEdge * 80 / m.getMaxScaleOnAxis() / 1000).round()} km',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Divider(color: antNavy, thickness: 2),
                          ),
                          const Text('投影距离', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: c,
                      builder: (_) => AlertDialog(
                        title: const Text('地图来源与范围'),
                        content: const Text(
                          'Data from the SCAR Antarctic Digital Database, 2026. v7.13 · CC BY 4.0。白色为陆地，浅蓝为冰架／冰舌，点表示地点代表位置。EPSG:3031 极地立体投影；数据为2026年下载快照，经1公里概化，不是实时海冰或导航地图。比例尺为投影近似距离，各地比例略有差异。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('知道了'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('来源与图例'),
                  ),
                  IconButton(
                    tooltip: '重置地图',
                    onPressed: () {
                      transform.value = Matrix4.identity();
                      setState(() => view = '全洲');
                    },
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),
          ],
        );
        return wide
            ? Row(
                children: [
                  SizedBox(width: 330, child: detail(c)),
                  Expanded(child: map),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: b.maxHeight * .24),
                      child: map,
                    ),
                  ),
                  DraggableScrollableSheet(
                    controller: sheet,
                    initialChildSize: widget.placeId != null ? .5 : .25,
                    minChildSize: .25,
                    maxChildSize: .85,
                    snap: true,
                    snapSizes: const [.25, .5, .85],
                    builder: (c, scroll) => Material(
                      color: Colors.white,
                      elevation: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: detail(c, scroll),
                    ),
                  ),
                ],
              );
      },
    ),
  );
}

class AntCoast {
  AntCoast(this.surface, this.rings);
  final String surface;
  final List<List<Offset>> rings;
}

class _PolarPainter extends CustomPainter {
  _PolarPainter(
    this.rings,
    this.points,
    this.selected,
    this.land,
    this.places,
    this.shelves,
  );
  final List<AntCoast> rings;
  final List<AtlasPlace> points;
  final AtlasPlace? selected;
  final bool land, places, shelves;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 8000000;
    Offset xy(Offset p) => size.center(Offset.zero) + p * scale;
    canvas.drawRect(Offset.zero & size, Paint()..color = antIce);
    for (final feature in rings) {
      final ice =
          feature.surface == 'ice shelf' || feature.surface == 'ice tongue';
      if (ice ? !shelves : !land) continue;
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final ring in feature.rings) {
        if (ring.isEmpty) continue;
        path.moveTo(xy(ring.first).dx, xy(ring.first).dy);
        for (final p in ring.skip(1)) {
          final q = xy(p);
          path.lineTo(q.dx, q.dy);
        }
        path.close();
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ice ? const Color(0xffb9e2f3) : const Color(0xfffafcfe),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff6fabc2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }
    final radius = antarcticProject(-66.56, 0).distance * scale;
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..color = const Color(0xff7da9be)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    for (final lon in [0, 90, 180, -90]) {
      final p = xy(antarcticProject(-60, lon.toDouble()));
      canvas.drawLine(
        size.center(Offset.zero),
        p,
        Paint()
          ..color = const Color(0xffc2d7e2)
          ..strokeWidth = .6,
      );
    }
    label(canvas, '南极点', size.center(Offset.zero) + const Offset(5, 5), 12);
    label(canvas, '0°', Offset(size.width / 2, 8), 12);
    label(canvas, '南极圈', Offset(12, size.height / 2), 10);
    if (places) {
      for (final p in points) {
        final q = xy(antarcticProject(p.latitude, p.longitude));
        canvas.drawCircle(
          q,
          p.id == selected?.id ? 7 : 4,
          Paint()..color = p.id == selected?.id ? antOrange : antNavy,
        );
        if (p.id == selected?.id) {
          label(canvas, p.name, q + const Offset(8, -20), 13);
        }
      }
    }
  }

  void label(Canvas c, String s, Offset at, double font) {
    final t = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: font,
          color: antNavy,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, Offset(at.dx.clamp(0, 500).toDouble(), at.dy));
  }

  @override
  bool shouldRepaint(covariant _PolarPainter old) => true;
}

/// A second, factual visual for each place, including sites without a licensed photo.
class AntLocator extends StatelessWidget {
  const AntLocator(this.place, {super.key});
  final AtlasPlace place;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: antIce,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('在南极洲的哪里？', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(
          height: 190,
          child: FutureBuilder<List<AntCoast>>(
            future: _AntarcticaMapScreenState.loadGeometry(),
            builder: (c, s) => s.hasData
                ? Center(
                    child: CustomPaint(
                      size: const Size.square(190),
                      painter: _PolarPainter(
                        s.data!,
                        [place],
                        place,
                        true,
                        true,
                        true,
                      ),
                    ),
                  )
                : const Center(child: Text('正在读取地理位置…')),
          ),
        ),
        Text(
          '${place.latitude.abs().toStringAsFixed(2)}°S · ${place.longitude.abs().toStringAsFixed(2)}°${place.longitude < 0 ? 'W' : 'E'} · 代表位置',
          style: const TextStyle(fontSize: 12),
        ),
        const Text('SCAR ADD 2026 · CC BY 4.0', style: TextStyle(fontSize: 10)),
      ],
    ),
  );
}
