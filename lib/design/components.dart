import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/services.dart';
import '../domain/atlas_content.dart';
import 'atlas_theme.dart';

Future<void> atlasAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) showMessage(context, success);
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        e is FormatException
            ? e.message
            : '操作没有完成，请重试。${e is StateError ? e.message : ''}',
      );
    }
  }
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );

void backOrHome(BuildContext context, [String fallback = '/discover']) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

class AtlasPage extends StatelessWidget {
  const AtlasPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(22, 16, 22, 28),
    this.scroll = true,
    this.width = 1080,
    this.background,
    this.darkBar = false,
    this.appBar,
    this.liftBottomForKeyboard = false,
  });
  final String title;
  final PreferredSizeWidget? appBar;
  final Widget child;
  final List<Widget> actions;
  final Widget? bottom;
  final EdgeInsets padding;
  final bool scroll, darkBar, liftBottomForKeyboard;
  final double width;
  final Color? background;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background ?? Colors.white,
    appBar:
        appBar ??
        AppBar(
          backgroundColor: darkBar ? AtlasPalette.navy : null,
          foregroundColor: darkBar ? Colors.white : null,
          titleTextStyle: darkBar
              ? Theme.of(context).appBarTheme.titleTextStyle
                    ?.copyWith(color: Colors.white)
              : null,
          leading: IconButton(
            color: darkBar ? Colors.white : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: '返回',
            onPressed: () => backOrHome(context),
          ),
          title: Text(title),
          actions: actions,
        ),
    bottomNavigationBar: bottom == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: liftBottomForKeyboard
                  ? MediaQuery.viewInsetsOf(context).bottom
                  : 0,
            ),
            child: SafeArea(top: false, child: bottom!),
          ),
    body: scroll
        ? SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Padding(padding: padding, child: child),
              ),
            ),
          )
        : child,
  );
}

class EditorialHeading extends StatelessWidget {
  const EditorialHeading(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.large = false,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool large;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: large
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel ?? '查看更多'),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
      ],
    ),
  );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.orange = false,
    this.arrow = true,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool orange, arrow;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: orange
          ? FilledButton.styleFrom(
              backgroundColor: AtlasPalette.orange,
              foregroundColor: AtlasPalette.ink,
            )
          : null,
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          if (arrow) ...[
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: orange ? AtlasPalette.navy : AtlasPalette.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 23,
                color: orange ? Colors.white : AtlasPalette.navy,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class MediaPhoto extends StatelessWidget {
  const MediaPhoto(
    this.id, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.radius = 0,
    this.onTap,
    this.showCredit = false,
  });
  final String id;
  final double? width, height;
  final BoxFit fit;
  final Alignment alignment;
  final double radius;
  final VoidCallback? onTap;
  final bool showCredit;
  @override
  Widget build(BuildContext context) {
    final media = context.atlas.content.media[id];
    final bytes = context.atlas.content.memoryMedia[id];
    final picture = media == null
        ? _fallback()
        : bytes != null
        ? Image.memory(
            bytes,
            width: width,
            height: height,
            fit: id == 'tree-frog' ? BoxFit.contain : fit,
            alignment: alignment,
            semanticLabel: media.caption,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : Image.asset(
            media.asset,
            width: width,
            height: height,
            fit: id == 'tree-frog' ? BoxFit.contain : fit,
            alignment: alignment,
            semanticLabel: media.caption,
            errorBuilder: (_, _, _) => _fallback(),
            filterQuality: FilterQuality.medium,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: width == null && height == null ? StackFit.expand : StackFit.loose,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(width: width, height: height, child: picture),
          ),
          if (showCredit && media != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: IconButton.filledTonal(
                tooltip: '图片说明与来源',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .9),
                ),
                onPressed: () => showMediaCredit(context, media),
                icon: const Icon(Icons.info_outline_rounded, size: 19),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: AtlasPalette.sea,
    alignment: Alignment.center,
    child: const Icon(Icons.public, color: AtlasPalette.blue, size: 46),
  );
}

Future<void> showMediaCredit(
  BuildContext context,
  MediaItem media,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(media.caption, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('摄影 / 制作：${media.credit}'),
            Text('许可：${media.license}'),
            const SizedBox(height: 12),
            SelectableText(
              media.sourceUrl,
              style: const TextStyle(fontSize: 14, color: AtlasPalette.blue),
            ),
            const SizedBox(height: 8),
            SelectableText(
              media.licenseUrl,
              style: const TextStyle(fontSize: 14, color: AtlasPalette.muted),
            ),
            const SizedBox(height: 18),
            PrimaryAction(
              '复制来源链接',
              arrow: false,
              onPressed: () => atlasAction(
                context,
                () => Clipboard.setData(ClipboardData(text: media.sourceUrl)),
                success: '已复制来源链接',
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

class SavedButton extends StatelessWidget {
  const SavedButton({
    super.key,
    required this.kind,
    required this.id,
    required this.title,
    this.light = false,
  });
  final String kind, id, title;
  final bool light;
  @override
  Widget build(BuildContext context) {
    final journal = context.atlas.journal;
    return ListenableBuilder(
      listenable: journal,
      builder: (context, _) {
        final selected = journal.saved(kind, id);
        return IconButton(
          tooltip: selected ? '取消收藏' : '收藏',
          onPressed: () =>
              atlasAction(context, () => journal.toggle(kind, id, title)),
          icon: Icon(
            selected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: light ? Colors.white : AtlasPalette.navy,
          ),
        );
      },
    );
  }
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.text, {super.key, this.orange = false});
  final String text;
  final bool orange;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: orange ? AtlasPalette.orangeSoft : AtlasPalette.canvas,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: orange ? const Color(0xFF8A4A12) : AtlasPalette.navy,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class FilterStrip extends StatelessWidget {
  const FilterStrip({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
  });
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) => ChoiceChip(
        label: Text(values[i]),
        selected: values[i] == selected,
        showCheckmark: false,
        selectedColor: AtlasPalette.orange,
        backgroundColor: AtlasPalette.canvas,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: AtlasPalette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        onSelected: (_) => onSelected(values[i]),
      ),
    ),
  );
}

class ContentRow extends StatelessWidget {
  const ContentRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.mediaId = '',
    this.leading,
    this.trailing,
    this.outlined = false,
  });
  final String title, subtitle, mediaId;
  final VoidCallback onTap;
  final Widget? leading, trailing;
  final bool outlined;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: outlined ? Border.all(color: AtlasPalette.line) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ] else if (mediaId.isNotEmpty) ...[
              MediaPhoto(mediaId, width: 92, height: 78, radius: 12),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AtlasPalette.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AtlasPalette.navy,
                ),
          ],
        ),
      ),
    ),
  );
}

class AtlasEmpty extends StatelessWidget {
  const AtlasEmpty({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.icon = Icons.travel_explore_rounded,
  });
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AtlasPalette.blue),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AtlasPalette.muted),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 22),
            FilledButton(onPressed: onAction, child: Text(action ?? '去探索')),
          ],
        ],
      ),
    ),
  );
}

IconData sectionIcon(String id) => switch (id) {
  'geography' => Icons.landscape_outlined,
  'people' => Icons.people_outline_rounded,
  'daily' => Icons.home_outlined,
  'food' => Icons.restaurant_rounded,
  'culture' => Icons.account_balance_outlined,
  'landmarks' => Icons.location_city_rounded,
  'nature' => Icons.pets_outlined,
  'history' => Icons.history_edu_rounded,
  'questions' => Icons.help_outline_rounded,
  _ => Icons.badge_outlined,
};
