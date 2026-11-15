import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/services.dart';
import '../domain/atlas_content.dart';
import 'atlas_theme.dart';
import 'components.dart';

/// Pins use coordinates relative to the full photograph, so they remain
/// attached to the same detail when the reader zooms or changes screen size.
class PhotoPoints extends StatefulWidget {
  const PhotoPoints({
    super.key,
    required this.mediaId,
    required this.points,
    required this.selected,
    required this.onSelect,
    this.maxHeight = 420,
  });

  final String mediaId;
  final List<Json> points;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final double maxHeight;

  @override
  State<PhotoPoints> createState() => _PhotoPointsState();
}

class _PhotoPointsState extends State<PhotoPoints> {
  final transform = TransformationController();

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = context.atlas.content.media[widget.mediaId];
    final ratio = media == null || media.height == 0
        ? 1.5
        : media.width / media.height;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(
              constraints.maxWidth,
              widget.maxHeight * ratio,
            );
            final height = width / ratio;
            return SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: InteractiveViewer(
                  transformationController: transform,
                  maxScale: 4,
                  child: Stack(
                    children: [
                      MediaPhoto(
                        widget.mediaId,
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                      ),
                      for (var i = 0; i < widget.points.length; i++)
                        Positioned(
                          left: ((widget.points[i]['x'] as num) * width - 24)
                              .clamp(0.0, math.max(0.0, width - 48)),
                          top: ((widget.points[i]['y'] as num) * height - 24)
                              .clamp(0.0, math.max(0.0, height - 48)),
                          child: IconButton(
                            tooltip: '照片观察点 ${i + 1}',
                            onPressed: widget.onSelect == null
                                ? null
                                : () => widget.onSelect!(i),
                            icon: CircleAvatar(
                              radius: 16,
                              backgroundColor: widget.selected == i
                                  ? AtlasPalette.navy
                                  : AtlasPalette.orange,
                              foregroundColor: widget.selected == i
                                  ? Colors.white
                                  : AtlasPalette.navy,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                '双指放大 · 下方也可选',
                style: TextStyle(fontSize: 13, color: AtlasPalette.muted),
              ),
            ),
            if (media != null)
              IconButton(
                tooltip: '图片说明与来源',
                onPressed: () => showMediaCredit(context, media),
                icon: const Icon(Icons.info_outline),
              ),
            TextButton(
              onPressed: () => transform.value = Matrix4.identity(),
              child: const Text('还原照片'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Photographs for an activity. Captions stay visible and act as an
/// equivalent source of evidence when the photographs can't be seen.
class LessonPhotos extends StatelessWidget {
  const LessonPhotos(this.ids, {super.key, this.hotspots = const []});

  final List<String> ids;
  final List<Json> hotspots;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compare =
          ids.length == 2 && constraints.maxWidth >= 300 && hotspots.isEmpty;
      final width = compare
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 14,
        children: [
          for (final (i, id) in ids.indexed)
            SizedBox(
              width: width,
              child: _LessonPhoto(
                id,
                label: ids.length > 1 ? '图 ${String.fromCharCode(65 + i)}' : '',
                height: compare ? 150 : 220,
                points: hotspots
                    .where((point) => point['mediaId'] == id)
                    .toList(),
              ),
            ),
        ],
      );
    },
  );
}

class _LessonPhoto extends StatefulWidget {
  const _LessonPhoto(
    this.id, {
    required this.label,
    required this.height,
    required this.points,
  });

  final String id, label;
  final double height;
  final List<Json> points;

  @override
  State<_LessonPhoto> createState() => _LessonPhotoState();
}

class _LessonPhotoState extends State<_LessonPhoto> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final media = context.atlas.content.media[widget.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.points.isEmpty)
          MediaPhoto(
            widget.id,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.contain,
            radius: 14,
            showCredit: true,
          )
        else ...[
          PhotoPoints(
            mediaId: widget.id,
            points: widget.points,
            selected: selected,
            onSelect: (i) => setState(() => selected = i),
            maxHeight: 300,
          ),
          for (final (i, point) in widget.points.indexed)
            TextButton(
              onPressed: () => setState(() => selected = i),
              child: Text(point['label']),
            ),
          if (selected != null) Text(widget.points[selected!]['explanation']),
        ],
        if (media != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.label.isEmpty
                  ? media.caption
                  : '${widget.label} · ${media.caption}',
              style: const TextStyle(color: AtlasPalette.muted, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
