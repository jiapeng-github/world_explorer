import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../../map_engine/atlas_map.dart';
import '../../map_engine/country_map_profile.dart';
import 'country_atlas_screen.dart';
import 'usa_atlas_screen.dart';
import 'gbr_atlas_screen.dart';
import 'fra_atlas_screen.dart';
import 'deu_atlas_screen.dart';
import 'kenya_atlas_screen.dart';
import 'norway_atlas_screen.dart';
import 'japan_atlas_screen.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({
    super.key,
    this.countryId,
    this.placeId,
    this.layer,
    this.featureId,
    this.region,
  });
  final String? countryId, placeId, layer, featureId, region;
  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  final controller = AtlasMapController();
  String? selected, placeId;
  late String layer;
  bool ready = false;
  double sheetExtent = .43;
  @override
  void initState() {
    super.initState();
    selected = widget.countryId == 'twn'
        ? 'china'
        : widget.countryId ?? 'egypt';
    placeId = widget.placeId;
    layer = widget.layer ?? (widget.placeId != null ? '地标' : '国家');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ready) {
      ready = true;
      final p = context.atlas.content.place(placeId ?? '');
      if (p != null) selected = p.countryId;
    }
  }

  @override
  void didUpdateWidget(AtlasScreen old) {
    super.didUpdateWidget(old);
    if (widget.countryId != old.countryId || widget.placeId != old.placeId) {
      selected = widget.countryId == 'twn'
          ? 'china'
          : widget.countryId ?? selected;
      placeId = widget.placeId;
      final p = context.atlas.content.place(placeId ?? ''),
          c = context.atlas.content.country(selected ?? '');
      if (p != null) {
        selected = p.countryId;
        layer = '地标';
        controller.focus(p.latitude, p.longitude, zoom: 7);
      } else if (c != null) {
        controller.focus(c.latitude, c.longitude, zoom: 3.2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.atlas.content,
        c = data.country(selected ?? ''),
        p = data.place(placeId ?? '');
    final requested =
        data.place(widget.placeId ?? '')?.countryId ?? widget.countryId;
    if (requested == 'japan') {
      return JapanAtlasScreen(
        placeId: widget.placeId,
        featureId: widget.featureId,
        layer: widget.layer,
      );
    }
    if (requested == 'norway' &&
        data.country('norway')?.editorial.isNotEmpty == true) {
      return NorwayAtlasScreen(
        region: widget.region,
        layer: widget.layer,
        placeId: widget.placeId,
        featureId: widget.featureId,
      );
    }
    if (requested == 'kenya' &&
        data.country('kenya')?.editorial.isNotEmpty == true) {
      return KenyaAtlasScreen(
        region: widget.region,
        layer: widget.layer,
        placeId: widget.placeId,
        featureId: widget.featureId,
      );
    }
    if (requested == 'deu' &&
        data.country('deu')?.editorial.isNotEmpty == true) {
      return DeuAtlasScreen(
        region: widget.region,
        layer: widget.layer,
        placeId: widget.placeId,
        featureId: widget.featureId,
      );
    }
    if (requested == 'fra' &&
        data.country('fra')?.editorial.isNotEmpty == true) {
      return FraAtlasScreen(
        region: widget.region,
        placeId: widget.placeId,
        featureId: widget.featureId,
        layer: widget.layer,
      );
    }
    if (requested == 'gbr' &&
        data.country('gbr')?.editorial.isNotEmpty == true) {
      return GbrAtlasScreen(
        region: widget.region,
        placeId: widget.placeId,
        featureId: widget.featureId,
        layer: widget.layer,
      );
    }
    if (requested == 'usa' &&
        data.country('usa')?.editorial.isNotEmpty == true) {
      return UsaAtlasScreen(
        region: widget.region,
        placeId: widget.placeId,
        featureId: widget.featureId,
        layer: widget.layer,
      );
    }
    final profile = countryMapProfile(requested);
    if (profile != null &&
        data.country(profile.id)?.editorial.isNotEmpty == true) {
      return CountryAtlasScreen(
        key: ValueKey(profile.id),
        profile: profile,
        placeId: placeId,
        layer: widget.layer,
        featureId: widget.featureId,
      );
    }
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final map = AtlasMap(
            countries: data.countries,
            places: data.places,
            selectedId: selected,
            initialCountry: c,
            controller: controller,
            layer: layer,
            onCountry: (id) => setState(() {
              selected = id;
              placeId = null;
            }),
            onPlace: (id) => setState(() {
              placeId = id;
              selected = data.place(id)?.countryId;
            }),
            onOcean: () => setState(() {
              selected = null;
              placeId = null;
            }),
          );
          final header = Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
            child: Row(
              children: [
                Text('世界地图', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 16),
                if (wide)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AtlasPalette.line),
                        backgroundColor: AtlasPalette.canvas,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search),
                      label: const Text('搜索国家、地点或问题'),
                    ),
                  )
                else
                  const Spacer(),
                if (!wide)
                  IconButton(
                    onPressed: () => context.push('/search'),
                    tooltip: '搜索地图',
                    icon: const Icon(Icons.search),
                  ),
                const SizedBox(width: 10),
                if (wide)
                  ...['国家', '自然', '地标'].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: layer == s,
                        showCheckmark: false,
                        selectedColor: AtlasPalette.orange,
                        onSelected: (_) => setState(() => layer = s),
                      ),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: '地图图层',
                    initialValue: layer,
                    icon: const Icon(Icons.layers_outlined),
                    itemBuilder: (_) => [
                      for (final s in ['国家', '自然', '地标'])
                        CheckedPopupMenuItem(
                          value: s,
                          checked: layer == s,
                          child: Text(s),
                        ),
                    ],
                    onSelected: (s) => setState(() => layer = s),
                  ),
              ],
            ),
          );
          if (wide) {
            return Column(
              children: [
                header,
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: map),
                      SizedBox(
                        width: 330,
                        child: c == null
                            ? _choose()
                            : SingleChildScrollView(child: _details(c, p)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              header,
              Expanded(
                child: LayoutBuilder(
                  builder: (context, mapConstraints) =>
                      NotificationListener<DraggableScrollableNotification>(
                        onNotification: (notification) {
                          if ((sheetExtent - notification.extent).abs() >
                              .003) {
                            setState(() => sheetExtent = notification.extent);
                          }
                          return false;
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              bottom: c != null
                                  ? mapConstraints.maxHeight * sheetExtent
                                  : 0,
                              child: map,
                            ),
                            if (c != null)
                              DraggableScrollableSheet(
                                initialChildSize: .43,
                                minChildSize: .22,
                                maxChildSize: .82,
                                snap: true,
                                snapSizes: const [.43, .82],
                                builder: (context, scroll) => Material(
                                  color: Colors.white,
                                  elevation: 5,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: ListView(
                                    controller: scroll,
                                    padding: EdgeInsets.zero,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AtlasPalette.line,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _details(c, p, phone: true),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _choose() => AtlasEmpty(
    title: '点一个国家，出发吧',
    message: '拖动和缩放地图，看看不同地方的山川与海岸。',
    action: '浏览国家百科',
    onAction: () => context.go('/encyclopedia'),
  );
  Widget _details(AtlasCountry c, AtlasPlace? p, {bool phone = false}) {
    final places = context.atlas.content.placesIn(c.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        phone ? 18 : 22,
        phone ? 12 : 24,
        phone ? 18 : 22,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p?.name ?? c.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(c.flag, style: const TextStyle(fontSize: 30)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${c.continent}${c.capital.isNotEmpty ? ' · 首都${c.capital}' : ''}',
            style: const TextStyle(color: AtlasPalette.muted),
          ),
          const SizedBox(height: 12),
          if (c.mediaId.isNotEmpty || p?.mediaIds.isNotEmpty == true)
            MediaPhoto(
              p?.mediaIds.firstOrNull ?? c.mediaId,
              width: double.infinity,
              height: phone ? 115 : 185,
              radius: 12,
            ),
          const SizedBox(height: 12),
          if (!phone) ...[
            Text(
              p?.summary ?? (c.tagline.isEmpty ? '从位置认识这个国家' : c.tagline),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              p?.description ?? c.intro,
              style: const TextStyle(color: AtlasPalette.muted),
            ),
            const SizedBox(height: 18),
          ],
          PrimaryAction(
            c.id == 'ata'
                ? '探索南极洲'
                : c.hasArticles
                ? (p != null ? '查看地标详情' : '探索${c.name}')
                : '即将上线',
            arrow: c.hasArticles || c.id == 'ata',
            onPressed: c.id == 'ata'
                ? () => context.push('/regions/antarctica')
                : c.hasArticles
                ? () => context.push(
                    p != null ? '/places/${p.id}' : '/countries/${c.id}',
                  )
                : null,
          ),
          if (phone) ...[
            const SizedBox(height: 15),
            Text(
              p?.description ?? c.intro,
              style: const TextStyle(color: AtlasPalette.muted),
            ),
          ],
          if (places.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Divider(),
            const EditorialHeading('著名地标'),
            for (final place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ContentRow(
                  title: place.name,
                  subtitle: place.category,
                  mediaId: place.mediaIds.firstOrNull ?? '',
                  onTap: () {
                    setState(() {
                      placeId = place.id;
                      layer = '地标';
                    });
                    controller.focus(place.latitude, place.longitude, zoom: 6);
                  },
                  trailing: const Icon(Icons.location_on_outlined, size: 22),
                ),
              ),
          ],
          TextButton(
            onPressed: () => context.push('/credits?entity=map'),
            child: const Text('地图来源与图例'),
          ),
        ],
      ),
    );
  }
}
