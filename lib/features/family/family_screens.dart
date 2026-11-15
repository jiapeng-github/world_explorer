import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/services.dart';
import '../../data/database/user_repositories.dart';
import '../../data/downloads/pack_repository.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';

class ReadingSettingsScreen extends StatefulWidget {
  const ReadingSettingsScreen({super.key});
  @override
  State<ReadingSettingsScreen> createState() => _ReadingSettingsScreenState();
}

class _ReadingSettingsScreenState extends State<ReadingSettingsScreen> {
  AtlasServices? services;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    services = context.atlas;
  }

  @override
  void dispose() {
    unawaited(services?.speech.pause() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atlas.preferences;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => AtlasPage(
        title: '阅读设置',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialHeading('把文字调到舒服的大小'),
            Text(
              '字号 · ${(p.textScale * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              semanticFormatterCallback: (v) => '字号 ${(v * 100).round()}%',
              value: p.textScale,
              min: 1,
              max: 1.6,
              divisions: 6,
              label: '${(p.textScale * 100).round()}%',
              onChanged: (v) =>
                  atlasAction(context, () => p.set('textScale', v)),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: p.readingBackground == 'warm'
                    ? const Color(0xFFFFF8E9)
                    : p.readingBackground == 'green'
                    ? const Color(0xFFF0F7F0)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AtlasPalette.line),
              ),
              child: Text(
                '河流带来水，也把不同地方的生活连接起来。\n每一个好奇的问题，都是认识世界的开始。',
                style: TextStyle(fontSize: 18 * p.textScale, height: 1.7),
              ),
            ),
            const EditorialHeading('阅读背景'),
            Wrap(
              spacing: 10,
              children: [
                for (final item in [
                  ('white', '清爽白'),
                  ('warm', '柔和米色'),
                  ('green', '浅绿'),
                ])
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: p.readingBackground == item.$1,
                    onSelected: (_) => atlasAction(
                      context,
                      () => p.set('readingBackground', item.$1),
                    ),
                  ),
              ],
            ),
            const EditorialHeading('朗读语速'),
            const Text(
              '慢一些，听清楚每一个新发现。',
              style: TextStyle(color: AtlasPalette.muted),
            ),
            Slider(
              semanticFormatterCallback: (v) =>
                  '语速 ${v <= .35
                      ? '较慢'
                      : v >= .55
                      ? '较快'
                      : '标准'}',
              value: p.speechRate,
              min: .25,
              max: .65,
              divisions: 8,
              label: p.speechRate <= .35
                  ? '较慢'
                  : p.speechRate >= .55
                  ? '较快'
                  : '标准',
              onChanged: (v) =>
                  atlasAction(context, () => p.set('speechRate', v)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final preset in [('较慢', .3), ('标准', .45), ('较快', .6)])
                  TextButton(
                    onPressed: () => atlasAction(
                      context,
                      () => p.set('speechRate', preset.$2),
                    ),
                    child: Text(preset.$1),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => context.atlas.speech.play(
                context.atlas.content.articles.first,
                rate: p.speechRate,
              ),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('听听这个语速'),
            ),
            ListenableBuilder(
              listenable: context.atlas.speech,
              builder: (context, _) => context.atlas.speech.error == null
                  ? const SizedBox.shrink()
                  : Text(
                      context.atlas.speech.error!,
                      style: const TextStyle(color: AtlasPalette.muted),
                    ),
            ),
            const SizedBox(height: 18),
            const Text(
              '设置会保存在这台设备，并应用到文章阅读。',
              style: TextStyle(color: AtlasPalette.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});
  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  Timer? timer;
  bool holding = false;
  void start() {
    timer?.cancel();
    setState(() => holding = true);
    timer = Timer(const Duration(seconds: 2), () {
      if (mounted) context.replace('/parent');
    });
  }

  void stop() {
    timer?.cancel();
    if (mounted) setState(() => holding = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AtlasPage(
    title: '家长入口',
    child: Column(
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.supervisor_account_outlined,
          size: 70,
          color: AtlasPalette.navy,
        ),
        const SizedBox(height: 24),
        Text('请家长来帮忙', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        const Text(
          '这里可以设置休息提醒、管理离线内容，\n以及备份这台设备上的探索记录。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AtlasPalette.muted),
        ),
        const SizedBox(height: 36),
        Semantics(
          label: '家长入口，长按两秒进入',
          button: true,
          onLongPress: () => context.replace('/parent'),
          child: GestureDetector(
            onTapDown: (_) => start(),
            onTapUp: (_) => stop(),
            onTapCancel: stop,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: holding ? AtlasPalette.blue : AtlasPalette.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                holding ? '再按住一会儿…' : '长按 2 秒进入',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '这是防误触步骤，不是身份认证。',
          style: TextStyle(color: AtlasPalette.muted, fontSize: 13),
        ),
      ],
    ),
  );
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.atlas.preferences;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => AtlasPage(
        title: '家长中心',
        actions: [
          TextButton(
            onPressed: () => context.push('/packs'),
            child: const Text('内容包'),
          ),
        ],
        background: AtlasPalette.canvas,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).width < 360
                    ? 225 * MediaQuery.textScalerOf(context).scale(1)
                    : 215,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const MediaPhoto(
                      'mount-fuji',
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Color(0xDDFFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0, .35, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '让探索更适合孩子',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '合理设置，陪伴孩子在广阔的世界中快乐成长。',
                            style: TextStyle(
                              color: AtlasPalette.muted,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _box(context, Icons.menu_book_outlined, '阅读设置', [
              _row(
                context,
                '默认字号',
                '${(p.textScale * 100).round()}%',
                () => context.push('/settings/reading'),
              ),
              _row(
                context,
                '朗读语速',
                p.speechRate <= .35
                    ? '较慢'
                    : p.speechRate >= .55
                    ? '较快'
                    : '标准',
                () => context.push('/settings/reading'),
              ),
            ]),
            _box(context, Icons.schedule_rounded, '休息提醒', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('休息提醒'),
                value: p.breakEnabled,
                onChanged: (v) =>
                    atlasAction(context, () => p.set('breakEnabled', v)),
              ),
              _row(context, '提醒间隔', '${p.breakMinutes} 分钟', () async {
                final value = await showModalBottomSheet<int>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final minutes in [10, 15, 20, 30, 45, 60])
                          ListTile(
                            title: Text('$minutes 分钟'),
                            trailing: p.breakMinutes == minutes
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.pop(ctx, minutes),
                          ),
                      ],
                    ),
                  ),
                );
                if (value != null && context.mounted) {
                  await atlasAction(
                    context,
                    () => p.set('breakMinutes', value),
                  );
                }
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '提醒可以稍后处理。后台时间不会计入。',
                  style: TextStyle(fontSize: 13, color: AtlasPalette.muted),
                ),
              ),
            ]),
            _box(context, Icons.description_outlined, '内容与记录', [
              _row(context, '离线内容包', '', () => context.push('/packs')),
              _row(context, '备份与恢复', '', () => context.push('/parent/backup')),
              _row(context, '内容来源与许可', '', () => context.push('/credits')),
            ]),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AtlasPalette.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '记录保存在这台设备，无需注册账号。',
                    style: TextStyle(color: AtlasPalette.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(
    BuildContext context,
    IconData icon,
    String title,
    List<Widget> children,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AtlasPalette.line.withValues(alpha: .6)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        Material(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    ),
  );
  Widget _row(
    BuildContext context,
    String title,
    String trailing,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          trailing,
          style: const TextStyle(fontSize: 15, color: AtlasPalette.muted),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
    onTap: onTap,
  );
}

String byteLabel(int count) => count < 1024
    ? '$count B'
    : count < 1024 * 1024
    ? '${(count / 1024).toStringAsFixed(0)} KB'
    : '${(count / (1024 * 1024)).toStringAsFixed(1)} MB';

class PacksScreen extends StatelessWidget {
  const PacksScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.atlas.packs,
    builder: (context, _) => AtlasPage(
      title: '离线内容包',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '下载后，没网络也能探索。',
            style: TextStyle(fontSize: 18, color: AtlasPalette.muted),
          ),
          const SizedBox(height: 18),
          for (final c in context.atlas.content.countries.where(
            (c) => c.hasArticles || ['japan', 'kenya', 'norway'].contains(c.id),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PackCard(c),
            ),
          const Text(
            '移除下载内容会保留收藏与笔记。内置内容随应用提供。',
            style: TextStyle(fontSize: 13, color: AtlasPalette.muted),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 10),
            const Text(
              '网页版本首次打开需要联网；原生安装包内置的内容无需网络。浏览器清理站点数据会移除本地记录，请及时备份。',
              style: TextStyle(fontSize: 13, color: AtlasPalette.muted),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PackCard extends StatelessWidget {
  const _PackCard(this.c, {this.showDetails = true});
  final bool showDetails;
  final AtlasCountry c;
  @override
  Widget build(BuildContext context) {
    final packs = context.atlas.packs, state = packs.states[c.id];
    final installed = packs.installed(c.id),
        busy =
            state?.phase == PackPhase.downloading ||
            state?.phase == PackPhase.verifying;
    final size =
        (context.atlas.content.raw['packSizes'] as Json?)?[c.id] as int?;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AtlasPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaPhoto(c.mediaId, width: double.infinity, height: 170),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (!busy && showDetails)
                      OutlinedButton(
                        onPressed: () => context.push('/packs/${c.id}'),
                        child: Text(installed ? '查看' : '详情'),
                      )
                    else if (busy)
                      IconButton(
                        tooltip: '取消下载',
                        onPressed: () => packs.cancel(c.id),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      installed
                          ? Icons.check_circle
                          : busy
                          ? Icons.downloading
                          : Icons.download_for_offline_outlined,
                      color: installed
                          ? AtlasPalette.success
                          : AtlasPalette.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      installed
                          ? '已安装'
                          : busy
                          ? '正在下载'
                          : state?.phase == PackPhase.failed
                          ? '下载未完成'
                          : c.hasArticles
                          ? '随应用提供'
                          : '深度内容正在编辑',
                      style: TextStyle(
                        color: installed
                            ? AtlasPalette.success
                            : AtlasPalette.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (busy) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (state?.total ?? 0) > 0
                        ? state!.received / state.total
                        : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${byteLabel(state?.received ?? 0)} / ${byteLabel(state?.total ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AtlasPalette.muted,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    '${context.atlas.content.articlesIn(c.id).length} 篇文章 · ${context.atlas.content.placesIn(c.id).length} 处地点${size != null ? ' · ${byteLabel(size)}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AtlasPalette.muted,
                    ),
                  ),
                ],
                if (state?.error != null)
                  Text(
                    state!.error!,
                    style: const TextStyle(
                      color: AtlasPalette.error,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PackDetailScreen extends StatelessWidget {
  const PackDetailScreen(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.atlas.packs,
    builder: (context, _) {
      final c = context.atlas.content.country(id), packs = context.atlas.packs;
      if (c == null) {
        return const AtlasPage(
          title: '内容包',
          child: AtlasEmpty(title: '没有找到这个内容包', message: '请返回离线内容列表。'),
        );
      }
      return AtlasPage(
        title: '${c.name}内容包',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PackCard(c, showDetails: false),
            const SizedBox(height: 18),
            if (packs.installed(id))
              PrimaryAction(
                '开始探索${c.name}',
                onPressed: () => context.push('/countries/$id'),
              ),
            const EditorialHeading('这个内容包里有什么'),
            for (final a in context.atlas.content.articlesIn(id))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: Text(a.title),
                onTap: () => context.push('/articles/${a.id}'),
              ),
            const SizedBox(height: 18),
            if (!packs.installed(id) && packs.baseUrl != null)
              PrimaryAction(
                '下载内容包',
                onPressed: () => atlasAction(context, () => packs.install(id)),
              )
            else if (!packs.installed(id))
              const Text(
                '深度内容正在编辑。当前基础资料已经保存在本机，可以先从地图认识这个地方。',
                style: TextStyle(color: AtlasPalette.muted),
              ),
            if (packs.installed(id) && !packs.bundled.contains(id))
              TextButton.icon(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('移除${c.name}下载内容？'),
                      content: const Text('收藏、足迹与个人笔记会保留。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('保留'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('移除内容包'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true && context.mounted) {
                    await atlasAction(
                      context,
                      () => packs.remove(id),
                      success: '已移除下载内容，个人记录已保留',
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('移除下载内容'),
              ),
          ],
        ),
      );
    },
  );
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  Json? preview;
  String fileName = '';
  bool busy = false;
  Future<void> export() async {
    await atlasAction(context, () async {
      final backup = await context.atlas.journal.backup();
      final name =
          'world-atlas-${DateTime.now().toIso8601String().substring(0, 10)}.json';
      final file = XFile.fromData(
        Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)),
        ),
        mimeType: 'application/json',
        name: name,
      );
      if (kIsWeb) {
        await file.saveTo(name);
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [file],
            fileNameOverrides: [name],
            title: '保存世界大百科备份',
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
        if (result.status == ShareResultStatus.dismissed) return;
        if (mounted) showMessage(context, '备份已交给系统，请在所选位置完成保存');
        return;
      } else {
        final location = await getSaveLocation(suggestedName: name);
        if (location == null) return;
        await file.saveTo(location.path);
      }
      if (mounted) showMessage(context, '备份文件已导出');
    });
  }

  Future<void> choose() async {
    await atlasAction(context, () async {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '世界大百科备份',
            extensions: ['json'],
            uniformTypeIdentifiers: ['public.json'],
            mimeTypes: ['application/json'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 10000000) throw const FormatException('备份文件过大');
      final data = JournalRepository.validateBackup(await file.readAsString());
      if (mounted) {
        setState(() {
          preview = data;
          fileName = file.name;
        });
      }
    });
  }

  Future<void> restore(bool replace) async {
    if (preview == null) return;
    if (replace) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('用这份备份替换本机记录？'),
          content: const Text('当前收藏、足迹和笔记将被替换。应用会保留恢复前的快照。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('替换本机记录'),
            ),
          ],
        ),
      );
      if (yes != true) return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    await atlasAction(context, () async {
      await context.atlas.journal.restore(preview!, replace: replace);
      if (!mounted) return;
      await context.atlas.preferences.load();
      if (mounted) setState(() => preview = null);
    }, success: '探索记录已经恢复');
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => AtlasPage(
    title: '备份与恢复',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('把好奇心，好好保存', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        const Text(
          '备份包括收藏、阅读进度、探索笔记和阅读设置。照片与百科内容不包含在备份里。',
          style: TextStyle(color: AtlasPalette.muted),
        ),
        const SizedBox(height: 24),
        PrimaryAction(
          '导出本机记录',
          icon: Icons.file_download_outlined,
          arrow: false,
          onPressed: busy ? null : export,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : choose,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('选择备份文件'),
          ),
        ),
        if (preview != null) ...[
          const EditorialHeading('先看看这份备份'),
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            '${(preview!['bookmarks'] as List).length} 条收藏 · ${(preview!['notes'] as List).length} 条笔记\n${(preview!['readingProgress'] as List).length} 篇阅读进度 · ${(preview!['history'] as List).length} 条足迹',
          ),
          const SizedBox(height: 16),
          const Text(
            '合并会保留本机记录，内容不同的同名笔记会另存一份。',
            style: TextStyle(color: AtlasPalette.muted),
          ),
          const SizedBox(height: 18),
          PrimaryAction(
            busy ? '正在恢复…' : '合并到本机',
            onPressed: busy ? null : () => restore(false),
          ),
          TextButton(
            onPressed: busy ? null : () => restore(true),
            child: const Text('替换本机记录'),
          ),
        ],
        if (context.atlas.preferences.values['backup-before-import']
            is Json) ...[
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: busy
                ? null
                : () {
                    setState(() {
                      preview =
                          context
                                  .atlas
                                  .preferences
                                  .values['backup-before-import']
                              as Json;
                      fileName = '上一次恢复之前的本机快照';
                    });
                  },
            child: const Text('查看恢复前的快照'),
          ),
        ],
      ],
    ),
  );
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key, this.entity});
  final String? entity;

  Iterable<String> _mediaIn(Object? data) sync* {
    if (data is List) {
      for (final child in data) {
        yield* _mediaIn(child);
      }
    } else if (data is Map) {
      for (final entry in data.entries) {
        final value = entry.value;
        if (entry.key == 'mediaId' && value is String && value.isNotEmpty) {
          yield value;
        } else if (entry.key == 'mediaIds' && value is List) {
          yield* value.whereType<String>();
        } else {
          yield* _mediaIn(value);
        }
      }
    }
  }

  Iterable<String> _articleMedia(AtlasArticle article) sync* {
    yield article.mediaId;
    yield* article.blocks.map((b) => b.mediaId).whereType<String>();
    yield* _mediaIn(article.activity);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.atlas.content;
    final a = data.article(entity ?? ''), p = data.place(entity ?? '');
    final c = data.country(a?.countryId ?? p?.countryId ?? entity ?? '');
    final allSources = data.featured.expand((c) => c.sources).toList();
    final sources = a != null
        ? [
            for (final url in a.sourceUrls)
              allSources.where((s) => s['url'] == url).firstOrNull ??
                  {'title': '文章参考资料', 'url': url, 'checkedAt': '2026-11-06'},
          ]
        : p != null
        ? [
            allSources.where((s) => s['url'] == p.sourceUrl).firstOrNull ??
                {
                  'title': '${p.name}资料',
                  'url': p.sourceUrl,
                  'checkedAt': '2026-11-06',
                },
          ]
        : c?.sources ?? allSources;
    final ids = entity == null
        ? data.media.keys.toSet()
        : a != null
        ? {
            ..._articleMedia(a),
            for (final e in data.exercises.where(
              (e) => e.articleId == a.id,
            )) ...[e.mediaId, ...e.mediaIds],
          }
        : p != null
        ? p.mediaIds.toSet()
        : c != null
        ? {
            c.mediaId,
            ..._mediaIn(c.editorial),
            ...data.articlesIn(c.id).expand(_articleMedia),
            ...data.placesIn(c.id).expand((place) => place.mediaIds),
            for (final e in data.exercises.where(
              (e) => e.countryId == c.id,
            )) ...[e.mediaId, ...e.mediaIds],
          }
        : <String>{};
    final rows = <WidgetBuilder>[
      (context) =>
          Text('每一个发现，都有来处', style: Theme.of(context).textTheme.headlineMedium),
      (context) => const SizedBox(height: 12),
      (context) => const Text(
        '文章为面向儿童的中文编写与整理。照片保留摄影署名和许可。数字、地图与历史材料均注明来源；不同年代的资料需要结合背景阅读。',
        style: TextStyle(color: AtlasPalette.muted),
      ),
      (context) => const EditorialHeading('文字资料'),
      for (final s in sources)
        (context) => _source(
          context,
          s['title'] ?? '参考资料',
          s['url'] ?? '',
          '核验日期：${s['checkedAt'] ?? '2026-11-01'}',
        ),
      (context) => const EditorialHeading('摄影与图片'),
      for (final id in ids)
        if (data.media[id] != null)
          (context) => _source(
            context,
            data.media[id]!.caption,
            data.media[id]!.sourceUrl,
            '${data.media[id]!.credit} · ${data.media[id]!.license}',
          ),
      (context) => const EditorialHeading('地图资料'),
      (context) => _source(
        context,
        'Natural Earth',
        'https://www.naturalearthdata.com/',
        '公共领域数据 · 1:110m 国家、海岸与水系。用于概览，不用于精确测距。',
      ),
      (context) => _source(
        context,
        'NASA Blue Marble Next Generation',
        'https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/base-topography-bathymetry/',
        'NASA Earth Observatory / Reto Stöckli · 2004 年影像合成；地形可视化，不是实时天气。',
      ),
      if (c?.id == 'egypt' || entity == null) ...[
        (context) => _source(
          context,
          'Natural Earth · 埃及水道',
          'https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-rivers-lake-centerlines/',
          '公共领域 1:10m · 尼罗河、三角洲两条主要入海水道及苏伊士运河。',
        ),
        (context) => _source(
          context,
          'NASA GIBS · 埃及区域底图',
          'https://nasa-gibs.github.io/gibs-api-docs/access-basics/',
          'NASA Earthdata GIBS · Blue Marble 地形图层 · WGS84 区域影像。',
        ),
      ],
      if (c?.id == 'usa' || entity == null) ...[
        (context) => _source(
          context,
          '美国人口普查局 · 2025 年州界与特区',
          'https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.2025.html',
          '公共领域 1:20m 制图边界 · 相连 48 州、阿拉斯加和夏威夷分别投影。',
        ),
        (context) => _source(
          context,
          'Natural Earth · 美国水系',
          'https://www.naturalearthdata.com/downloads/10m-physical-vectors/',
          '公共领域 1:10m · 科罗拉多河、密西西比河和五大湖。',
        ),
      ],
      (context) => const Text(
        '地图依数据源呈现地理实体与边界。部分小岛在当前比例尺下不可见，可通过百科搜索名称。',
        style: TextStyle(color: AtlasPalette.muted, fontSize: 14),
      ),
      (context) => const SizedBox(height: 18),
      (context) => TextButton(
        onPressed: () => atlasAction(context, () async {
          final info = await PackageInfo.fromPlatform();
          if (!context.mounted) return;
          showLicensePage(
            context: context,
            applicationName: '世界大百科',
            applicationVersion: '${info.version}+${info.buildNumber}',
          );
        }),
        child: const Text('开源软件许可'),
      ),
    ];
    return AtlasPage(
      title: '来源与许可',
      scroll: false,
      child: ListView.builder(
        key: const ValueKey('credits-list'),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        itemCount: rows.length,
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1036),
            child: SizedBox(
              width: double.infinity,
              child: rows[index](context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _source(
    BuildContext context,
    String title,
    String url,
    String subtitle,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AtlasPalette.muted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        SelectableText(
          url,
          style: const TextStyle(color: AtlasPalette.blue, fontSize: 13),
        ),
        TextButton.icon(
          onPressed: () => atlasAction(
            context,
            () => Clipboard.setData(ClipboardData(text: url)),
            success: '已复制来源链接',
          ),
          icon: const Icon(Icons.copy_outlined, size: 16),
          label: const Text('复制链接'),
        ),
      ],
    ),
  );
}

class RestScreen extends StatelessWidget {
  const RestScreen({super.key});
  @override
  Widget build(BuildContext context) => AtlasPage(
    title: '休息一下',
    child: Column(
      children: [
        const SizedBox(height: 35),
        const Icon(
          Icons.wb_sunny_outlined,
          size: 76,
          color: AtlasPalette.orange,
        ),
        const SizedBox(height: 24),
        Text('让眼睛也去旅行', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const Text(
          '放下屏幕，看看远处。\n伸伸胳膊，再把一个新发现讲给家人听。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AtlasPalette.muted,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 32),
        PrimaryAction('休息好了，继续探索', onPressed: () => backOrHome(context)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => backOrHome(context),
          child: const Text('稍后提醒我'),
        ),
      ],
    ),
  );
}
