import 'package:flutter/material.dart';

import '../../design/atlas_theme.dart';

/// Separates directly visible detail from interpretations needing sources.
class NorwayEvidenceCard extends StatelessWidget {
  const NorwayEvidenceCard({super.key});
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
              '木板、窗框与狭窄通道。\n可以观察材料和接缝。',
              const Color(0xfffff1df),
            ),
            (
              Icons.help_outline,
              '需要资料核对',
              '建造年代、修复记录。\n建筑过去的用途。',
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
