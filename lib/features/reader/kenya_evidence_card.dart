import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Separates directly visible detail from interpretations needing sources.
class KenyaEvidenceCard extends StatelessWidget {
  const KenyaEvidenceCard({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final single =
          box.maxWidth < 320 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (icon, title, body, color) in [
            (
              Icons.visibility_outlined,
              '我看见',
              '门楣上有重复纹样。\n门框围着两扇门板。',
              const Color(0xfffff1df),
            ),
            (
              Icons.help_outline,
              '需要资料核对',
              '木门的制作年代。\n图案的含义与来源。',
              const Color(0xffedf3f9),
            ),
          ])
            Container(
              width: single ? box.maxWidth : (box.maxWidth - 10) / 2,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AtlasPalette.orange, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(body, style: const TextStyle(fontSize: 15, height: 1.7)),
                ],
              ),
            ),
        ],
      );
    },
  );
}
