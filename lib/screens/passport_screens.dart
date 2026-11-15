import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/explorer_store.dart';
import '../core/palette.dart';
import '../models/catalog.dart';
import '../widgets/atlas_widgets.dart';
import 'learning_screens.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});
  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final stamped = store.catalog.countries
        .where((c) => store.completed.contains(c.id))
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final profile = AtlasCard(
                color: AtlasColors.forest,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AtlasColors.sand,
                      child: Text(
                        store.avatar,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '每一次好奇，都值得留下来。',
                            style: TextStyle(color: Color(0xFFD5E8DB)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '编辑探险名片',
                      onPressed: () => _editProfile(context, store),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
              final stats = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Stat('${store.visited.length}', '探索过的国家', Icons.public),
                  _Stat(
                    '${store.completed.length}',
                    '旅行印章',
                    Icons.auto_awesome,
                  ),
                  _Stat(
                    '${store.questions.length}',
                    '好奇问题',
                    Icons.lightbulb_outline,
                  ),
                ],
              );
              if (box.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [profile, const SizedBox(height: 16), stats],
                );
              }
              return Row(
                children: [
                  Expanded(child: profile),
                  const SizedBox(width: 20),
                  stats,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in [
                (0, '旅行印章', Icons.auto_awesome_outlined),
                (1, '我的收藏', Icons.bookmark_outline),
                (2, '好奇问题', Icons.help_outline),
              ])
                ChoiceChip(
                  selected: selected == item.$1,
                  onSelected: (_) => setState(() => selected = item.$1),
                  avatar: Icon(item.$3, size: 20),
                  label: Text(item.$2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (selected == 0) ...[
            const SectionHeading('我的世界足迹', subtitle: '完成一个国家的探索任务，就能收下一枚旅行印章。'),
            if (stamped.isEmpty)
              EmptyState(
                icon: Icons.auto_awesome_outlined,
                title: '第一枚印章，等你发现',
                message: '先读一个故事，再做三个小任务。\n每一次尝试都算数，不需要比谁更快。',
                action: FilledButton.icon(
                  onPressed: () => openScreen(
                    context,
                    StoryScreen(country: store.catalog.country('egypt')),
                  ),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('从埃及出发'),
                ),
              )
            else
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final country in stamped)
                    SizedBox(width: 254, child: _StampCard(country: country)),
                ],
              ),
          ],
          if (selected == 1) _FavoriteList(store: store),
          if (selected == 2) ...[
            SectionHeading(
              '好奇心笔记',
              trailing: IconButton.filledTonal(
                tooltip: '记录一个问题',
                onPressed: () => _addCuriosity(context, store),
                icon: const Icon(Icons.add),
              ),
            ),
            _QuestionList(store: store),
          ],
          const SizedBox(height: 28),
          const Text(
            '护照记录的是在 App 中的探索，不代表实地到访。',
            style: TextStyle(color: AtlasColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: AtlasCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AtlasColors.forest, size: 24),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: AtlasColors.forest,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AtlasColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _StampCard extends StatelessWidget {
  const _StampCard({required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) => AtlasCard(
    onTap: () => openScreen(context, StampScreen(country: country)),
    child: Column(
      children: [
        AtlasTag(country.continent),
        const SizedBox(height: 22),
        Transform.rotate(
          angle: -.06,
          child: Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: AtlasColors.mint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AtlasColors.forest, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(country.flagEmoji, style: const TextStyle(fontSize: 42)),
                Text(
                  country.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(country.subtitle, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text(
          '查看我的发现  →',
          style: TextStyle(
            color: AtlasColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class StampScreen extends StatelessWidget {
  const StampScreen({super.key, required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final earned = store.completed.contains(country.id);
    return ExplorerPage(
      title: '${country.name} · 旅行印章',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasCard(
              color: AtlasColors.mint,
              child: Column(
                children: [
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 70)),
                  const SizedBox(height: 12),
                  Text(
                    earned ? '我在${country.name}有了新发现' : '${country.name}，等你探索',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(earned ? '你已经完成这个国家的三个探索任务。' : '读故事，完成小任务，再把印章收进护照。'),
                ],
              ),
            ),
            const SectionHeading('带走的发现'),
            for (final question in country.quiz)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AtlasCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AtlasColors.forest,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(question.explanation)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      openScreen(context, StoryScreen(country: country)),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('再读一次故事'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openScreen(
                    context,
                    CuriosityScreen(countryId: country.id),
                  ),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('记下我的问题'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '我的收藏',
    subtitle: '喜欢的地方，可以再看一次',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _FavoriteList(store: ExplorerScope.of(context)),
    ),
  );
}

class _FavoriteList extends StatelessWidget {
  const _FavoriteList({required this.store});
  final ExplorerStore store;
  @override
  Widget build(BuildContext context) {
    final countries = store.catalog.countries
        .where((c) => store.favorites.contains(c.id))
        .toList();
    if (countries.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_outline,
        title: '把喜欢的地方留在这里',
        message: '在国家或故事页面点击收藏，\n下次就能从这里继续探索。',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('想再看一次'),
        for (final country in countries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AtlasCard(
              onTap: () => openScreen(context, StoryScreen(country: country)),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          country.story.title,
                          style: const TextStyle(color: AtlasColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '取消收藏${country.name}',
                    onPressed: () => store.toggleFavorite(country.id),
                    icon: const Icon(Icons.bookmark, color: AtlasColors.forest),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CuriosityScreen extends StatelessWidget {
  const CuriosityScreen({super.key, this.countryId});
  final String? countryId;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ExplorerPage(
      title: '我的好奇问题',
      subtitle: '先记下来，再和家人一起找答案',
      actions: [
        IconButton.filledTonal(
          tooltip: '记录一个问题',
          onPressed: () => _addCuriosity(context, store, countryId: countryId),
          icon: const Icon(Icons.add),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasCard(
              color: AtlasColors.sand.withValues(alpha: .5),
              child: const Text('“为什么”是探索的起点。这里是你的问题笔记本，不会自动生成答案。'),
            ),
            const SizedBox(height: 20),
            _QuestionList(store: store),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () =>
                    _addCuriosity(context, store, countryId: countryId),
                icon: const Icon(Icons.edit_note),
                label: const Text('记下一个新问题'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({required this.store});
  final ExplorerStore store;
  @override
  Widget build(BuildContext context) {
    if (store.questions.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline,
        title: '你的第一个“为什么”',
        message: '河流为什么弯弯曲曲？\n世界另一边的小朋友吃什么早餐？',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final question in store.questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_countryName(store, question.countryId)} · ${_dateLabel(question.createdAt)}',
                          style: const TextStyle(
                            color: AtlasColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '删除这个问题',
                        icon: const Icon(Icons.delete_outline, size: 21),
                        onPressed: () async {
                          final confirmed = await _confirm(
                            context,
                            title: '删除这个问题？',
                            message: '这条问题会从当前设备的笔记中移除。',
                            confirmLabel: '删除问题',
                          );
                          if (confirmed) {
                            await store.deleteQuestion(question.id);
                            if (context.mounted && store.storageError != null) {
                              showNotice(context, store.storageError!);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  const AtlasTag('留给下一次一起讨论', icon: Icons.people_outline),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _countryName(ExplorerStore store, String id) {
  for (final country in store.catalog.countries) {
    if (country.id == id) return country.name;
  }
  return '世界';
}

String _dateLabel(String value) {
  final time = DateTime.tryParse(value);
  return time == null ? '' : '${time.month}月${time.day}日';
}

Future<void> _addCuriosity(
  BuildContext context,
  ExplorerStore store, {
  String? countryId,
}) async {
  final controller = TextEditingController();
  final preferredCountry = countryId ?? store.lastCountryId;
  var country = store.catalog.countries.any((c) => c.id == preferredCountry)
      ? preferredCountry!
      : store.catalog.countries.first.id;
  String? error;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('我还想知道……'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: country,
                    decoration: const InputDecoration(labelText: '关于哪个地方'),
                    items: [
                      for (final c in store.catalog.countries)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.flagEmoji} ${c.name}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) country = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 200,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: '我的问题',
                      hintText: '把你的“为什么”写下来',
                      errorText: error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('下次再写'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setDialogState(() => error = '先写下一个问题吧');
                } else {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('收进笔记'),
            ),
          ],
        );
      },
    ),
  );
  if (result == true) {
    await store.addQuestion(controller.text, countryId: country);
    if (context.mounted) showNotice(context, store.storageError ?? '好奇问题已收进笔记');
  }
  controller.dispose();
}

Future<void> _editProfile(BuildContext context, ExplorerStore store) async {
  final controller = TextEditingController(text: store.nickname);
  var avatar = store.avatar;
  final save = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('我的探险名片'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: '探险昵称',
                      hintText: '不用填写真实姓名',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emoji in ['🦊', '🐼', '🐬', '🦉'])
                        ChoiceChip(
                          label: Text(
                            emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          selected: avatar == emoji,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setDialogState(() => avatar = emoji),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('保存名片'),
            ),
          ],
        );
      },
    ),
  );
  if (save == true) {
    await store.saveProfile(name: controller.text, selectedAvatar: avatar);
    if (context.mounted && store.storageError != null) {
      showNotice(context, store.storageError!);
    }
  }
  controller.dispose();
}

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key, this.onVerified});
  final VoidCallback? onVerified;
  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final answer = TextEditingController();
  late final int first = 13 + Random().nextInt(9);
  late final int second = 17 + Random().nextInt(8);
  Timer? holdTimer;
  bool holding = false, ready = false;
  String? error;

  void _startHold() {
    if (ready) return;
    setState(() => holding = true);
    holdTimer?.cancel();
    holdTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          ready = true;
          holding = false;
        });
      }
    });
  }

  void _endHold() {
    holdTimer?.cancel();
    if (mounted && holding) setState(() => holding = false);
  }

  @override
  void dispose() {
    holdTimer?.cancel();
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '请家长来帮忙',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: AtlasCard(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AtlasColors.mint,
                  child: Icon(
                    Icons.family_restroom,
                    size: 40,
                    color: AtlasColors.forest,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '这里留给大人',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  '阅读偏好、休息提醒和本地记录，\n由家长一起设置。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!ready)
                  Semantics(
                    label: '请家长按住两秒，然后完成计算',
                    button: true,
                    onLongPress: _startHold,
                    child: GestureDetector(
                      onLongPressStart: (_) => _startHold(),
                      onLongPressEnd: (_) => _endHold(),
                      onLongPressCancel: _endHold,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: holding
                              ? AtlasColors.ocean
                              : AtlasColors.forest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          holding ? '保持按住，马上就好…' : '我是家长 · 长按 2 秒',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    '请算一算：$first + $second = ?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: answer,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: '计算结果',
                      errorText: error,
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _verify,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('进入家长设置'),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  '此步骤用于减少误触，不验证成人身份。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AtlasColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  void _verify() {
    if (int.tryParse(answer.text) != first + second) {
      setState(() => error = '结果还不对，请再算一次');
      return;
    }
    if (widget.onVerified != null) {
      Navigator.pop(context);
      widget.onVerified!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ParentCenterScreen()),
      );
    }
  }
}

class ParentCenterScreen extends StatelessWidget {
  const ParentCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ExplorerPage(
      title: '家长中心',
      subtitle: '一起看见孩子的好奇心',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasCard(
              color: AtlasColors.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${store.nickname}的探索',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    store.visited.isEmpty
                        ? '还没有开始第一段旅行。可以一起选择一个感兴趣的地方。'
                        : '已经打开 ${store.visited.length} 个国家，完成 ${store.completed.length} 次国家探索，留下 ${store.questions.length} 个问题。',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '以孩子的兴趣为线索，聊聊“你发现了什么”，不用追赶进度。',
                    style: TextStyle(color: AtlasColors.muted),
                  ),
                ],
              ),
            ),
            const SectionHeading('适合孩子的阅读方式'),
            _SettingsLink(
              icon: Icons.text_fields,
              title: '阅读与声音',
              subtitle: '字号、系统朗读和语速',
              onTap: () => openScreen(context, const ReadingSettingsScreen()),
            ),
            const SizedBox(height: 14),
            _SettingsLink(
              icon: Icons.tune,
              title: '使用与内容',
              subtitle: '休息提醒、知识来源与本地记录',
              onTap: () => openScreen(context, const UsageSettingsScreen()),
            ),
            const SectionHeading('可以一起聊聊'),
            if (store.questions.isEmpty)
              const AtlasCard(
                child: Text('今天最想去哪个国家？为什么？\n如果你住在河边，生活可能会有什么不同？'),
              )
            else
              AtlasCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AtlasTag('孩子最近的问题', icon: Icons.lightbulb_outline),
                    const SizedBox(height: 14),
                    Text(
                      store.questions.first.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () =>
                          openScreen(context, const CuriosityScreen()),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('查看好奇笔记'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              '探索记录保存在当前设备。清理应用数据或卸载应用可能移除这些记录。',
              style: TextStyle(color: AtlasColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AtlasCard(
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AtlasColors.mint,
          child: Icon(icon, color: AtlasColors.forest),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                subtitle,
                style: const TextStyle(color: AtlasColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class ReadingSettingsScreen extends StatelessWidget {
  const ReadingSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ExplorerPage(
      title: '阅读与声音',
      subtitle: '设置会自动保存在当前设备',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('文字大小', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Slider(
                    value: store.textScale,
                    min: .9,
                    max: 1.35,
                    divisions: 9,
                    label: '${(store.textScale * 100).round()}%',
                    onChanged: (value) =>
                        store.updateSettings(textScale: value),
                  ),
                  Text(
                    '当前字号：${(store.textScale * 100).round()}%',
                    style: const TextStyle(color: AtlasColors.muted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AtlasColors.mint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '阅读效果示例',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text('河流流过不同的地方，也连接着人们的生活。带上好奇心，一起去看看吧。'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示故事朗读功能'),
                    subtitle: const Text('使用设备的中文语音，点击后才会播放'),
                    value: store.voiceEnabled,
                    onChanged: (value) =>
                        store.updateSettings(voiceEnabled: value),
                  ),
                  const Divider(height: 32),
                  Text('朗读速度', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: store.speechRate,
                    min: .25,
                    max: .65,
                    divisions: 8,
                    onChanged: store.voiceEnabled
                        ? (value) => store.updateSettings(speechRate: value)
                        : null,
                    semanticFormatterCallback: (value) => value < .4
                        ? '慢一些'
                        : value > .5
                        ? '快一些'
                        : '适中',
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('慢一些'), Text('适中'), Text('快一些')],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '实际声音由设备提供。若无法朗读，请先在系统中安装中文语音；部分语音需要联网。',
                    style: TextStyle(color: AtlasColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (store.storageError != null) ...[
              const SizedBox(height: 16),
              _StorageWarning(store: store),
            ],
          ],
        ),
      ),
    );
  }
}

class UsageSettingsScreen extends StatelessWidget {
  const UsageSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ExplorerPage(
      title: '使用与内容',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('休息提醒', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('到时间后，提醒孩子暂停探索、活动一下。'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final minutes in [5, 10, 20, 30])
                        ChoiceChip(
                          label: Text('$minutes 分钟'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          selected: store.breakMinutes == minutes,
                          onSelected: (_) =>
                              store.updateSettings(breakMinutes: minutes),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '当前：每 ${store.breakMinutes} 分钟提醒一次。',
                    style: const TextStyle(
                      color: AtlasColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SettingsLink(
              icon: Icons.fact_check_outlined,
              title: '内容与资料来源',
              subtitle: '查看每个国家使用的资料链接与核验日期',
              onTap: () => _showSources(context, store),
            ),
            const SizedBox(height: 18),
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前设备的记录',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('昵称、收藏、阅读进度、印章和好奇问题仅保存在本机。尚未提供云端同步。'),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('复制记录备份'),
                        onPressed: () async {
                          try {
                            await Clipboard.setData(
                              ClipboardData(
                                text: const JsonEncoder.withIndent('  ')
                                    .convert(store.toJson()),
                              ),
                            );
                            if (context.mounted) {
                              showNotice(context, 'JSON 记录已复制，可以粘贴到文件中保存。');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showNotice(context, '无法访问剪贴板，请检查系统权限。');
                            }
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('清除探索记录'),
                        onPressed: () async {
                          final confirmed = await _confirm(
                            context,
                            title: '清除这台设备的探索记录？',
                            message:
                                '阅读进度、收藏、印章和好奇问题将被移除。昵称与阅读设置会保留。建议先复制记录备份。',
                            confirmLabel: '确认清除',
                          );
                          if (!confirmed) return;
                          await store.resetProgress();
                          if (context.mounted) {
                            showNotice(
                              context,
                              store.storageError ?? '探索记录已清除，昵称和设置已保留。',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (store.storageError != null) ...[
              const SizedBox(height: 18),
              _StorageWarning(store: store),
            ],
            const SizedBox(height: 24),
            const Text(
              '世界小探险家 · 首版\n百科图文和地图已随应用提供；系统朗读的可用性取决于设备语音。',
              style: TextStyle(color: AtlasColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageWarning extends StatelessWidget {
  const _StorageWarning({required this.store});
  final ExplorerStore store;
  @override
  Widget build(BuildContext context) => AtlasCard(
    color: AtlasColors.sand.withValues(alpha: .45),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(store.storageError ?? '正在保存'),
        TextButton.icon(
          onPressed: store.retrySave,
          icon: const Icon(Icons.refresh),
          label: const Text('重新保存'),
        ),
      ],
    ),
  );
}

Future<void> _showSources(
  BuildContext context,
  ExplorerStore store,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('内容与资料来源'),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('内容按儿童阅读方式改写。地图来自 Natural Earth；探索主题插画为 AI 生成，不是实景照片。'),
            const SizedBox(height: 16),
            for (final country in store.catalog.countries) ...[
              Text(country.name, style: Theme.of(context).textTheme.titleLarge),
              for (final source in country.sources)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '核验：${source.checkedAt}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AtlasColors.muted,
                        ),
                      ),
                      SelectableText(
                        source.url,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AtlasColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
            ],
            const SelectableText(
              '地图：Natural Earth\nhttps://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-land/',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('知道了'),
      ),
    ],
  ),
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

class RestScreen extends StatelessWidget {
  const RestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return ExplorerPage(
      title: '在这里，休息一下',
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const Illustration(
                  asset: 'assets/images/discovery-finish.png',
                  height: 240,
                ),
                const SizedBox(height: 28),
                Text(
                  '世界很大，明天继续看',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  '伸伸懒腰，喝口水，\n也和身边的人聊聊今天的新发现吧。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  store.storageError == null
                      ? '已完成的探索可以在护照里找到。'
                      : '本地记录暂未保存，请家长帮助检查存储。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AtlasColors.muted),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        store.restartSession();
                        goHome(context);
                      },
                      icon: const Icon(Icons.done),
                      label: const Text('结束本次探索'),
                    ),
                    OutlinedButton(
                      onPressed: () => openScreen(
                        context,
                        ParentGateScreen(
                          onVerified: () {
                            store.restartSession();
                            if (context.mounted) goHome(context);
                          },
                        ),
                      ),
                      child: const Text('请家长延长时间'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
