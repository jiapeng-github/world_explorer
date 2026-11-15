import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.query = '', this.type = '全部'});
  final String query, type;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final controller = TextEditingController(text: widget.query);
  late String type = widget.type;
  String get query => controller.text.trim();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void search(String value) {
    controller.text = value;
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final results = context.atlas.content.search(query, kind: type);
    return AtlasPage(
      title: '搜索世界',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus:
                widget.query.isEmpty && MediaQuery.sizeOf(context).width < 600,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: '搜索',
              hintText: '国家、地点，或一个好奇的问题',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空搜索',
                      onPressed: () => setState(controller.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: search,
          ),
          const SizedBox(height: 20),
          if (query.isEmpty) ...[
            Text('你想知道什么？', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            const Text(
              '世界很大，从一个小问题开始。',
              style: TextStyle(color: AtlasPalette.muted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                for (final word in ['尼罗河', '长城', '雨林', '金字塔', '巴西', '文化'])
                  ActionChip(
                    label: Text(word),
                    onPressed: () => search(word),
                    backgroundColor: AtlasPalette.canvas,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
              ],
            ),
            const EditorialHeading('也可以从这里出发'),
            ContentRow(
              title: '尼罗河为什么重要？',
              subtitle: '一条河流，连接土地和生活',
              mediaId: 'nile-aswan',
              outlined: true,
              onTap: () => context.push('/articles/egypt-nature'),
            ),
            const SizedBox(height: 14),
            ContentRow(
              title: '世界上的不同生活',
              subtitle: '认识人们的语言、手艺与城市',
              mediaId: 'school',
              outlined: true,
              onTap: () => context.push('/topics/daily'),
            ),
            if (context.atlas.journal.history.isNotEmpty) ...[
              const EditorialHeading('最近去过'),
              for (final h in context.atlas.journal.history.take(4))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(h['title']),
                  onTap: () => search(h['title']),
                ),
            ],
          ] else ...[
            FilterStrip(
              values: const ['全部', '国家', '地点', '文章', '专题'],
              selected: type,
              onSelected: (v) => setState(() => type = v),
            ),
            const SizedBox(height: 12),
            Text(
              '找到 ${results.length} 条有关“$query”的内容',
              style: const TextStyle(color: AtlasPalette.muted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (results.isEmpty)
              AtlasEmpty(
                title: '还没找到这个内容',
                message: '试试更短的名称，或者换一个词语。',
                action: '浏览国家百科',
                onAction: () => context.go('/encyclopedia'),
              ),
            for (final r in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ContentRow(
                  title: r.title,
                  subtitle: '${r.kind} · ${r.subtitle}',
                  mediaId: r.mediaId,
                  outlined: true,
                  onTap: () => context.push(r.route),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
