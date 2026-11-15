import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../domain/atlas_content.dart';
import '../discover/discover_screen.dart';

String entityRoute(String kind, String id) => switch (kind) {
  'region' => '/regions/$id',
  'country' => '/countries/$id',
  'article' => '/articles/$id',
  'place' => '/places/$id',
  'topic' => '/topics/$id',
  _ => '/encyclopedia',
};
String entityMedia(AtlasServices s, String kind, String id) => switch (kind) {
  'region' => 'antarctica-m15',
  'country' => s.content.country(id)?.mediaId ?? '',
  'article' => s.content.article(id)?.mediaId ?? '',
  'place' => s.content.place(id)?.mediaIds.firstOrNull ?? '',
  'topic' => s.content.topic(id)?.mediaId ?? '',
  _ => '',
};

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListenableBuilder(
      listenable: context.atlas.journal,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AtlasPalette.orangeSoft,
                        child: Icon(
                          Icons.explore_outlined,
                          size: 35,
                          color: AtlasPalette.navy,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的探索',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Text(
                              '把好奇心留下来',
                              style: TextStyle(
                                color: AtlasPalette.muted,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '家长入口',
                        onPressed: () => context.push('/parent-gate'),
                        icon: const Icon(Icons.supervisor_account_outlined),
                      ),
                      IconButton(
                        tooltip: '阅读设置',
                        onPressed: () => context.push('/settings/reading'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        const MediaPhoto(
                          'nile-aswan',
                          width: double.infinity,
                          height: 160,
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                          child: const ContinueReading(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final item in [
                    ('我的收藏', Icons.star_outline_rounded, '/me/bookmarks'),
                    ('阅读足迹', Icons.schedule_rounded, '/me/history'),
                    ('探索笔记', Icons.edit_note_rounded, '/me/notes'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ContentRow(
                        title: item.$1,
                        subtitle: '',
                        leading: Icon(
                          item.$2,
                          size: 32,
                          color: item.$1 == '阅读足迹'
                              ? AtlasPalette.blue
                              : const Color(0xFFD9781E),
                        ),
                        outlined: true,
                        onTap: () => context.push(item.$3),
                      ),
                    ),
                  EditorialHeading(
                    '最近收藏',
                    onAction: () => context.push('/me/bookmarks'),
                  ),
                  if (context.atlas.journal.bookmarks.isEmpty)
                    ContentRow(
                      title: '给喜欢的内容做个记号',
                      subtitle: '读文章、看风景时，点一下收藏。',
                      leading: const Icon(Icons.bookmark_outline, size: 30),
                      outlined: true,
                      onTap: () => context.go('/encyclopedia'),
                    )
                  else
                    Row(
                      children: [
                        for (final b in context.atlas.journal.bookmarks.take(2))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: QuestionTile(
                                title: b['title'],
                                mediaId: entityMedia(
                                  context.atlas,
                                  b['kind'],
                                  b['entity_id'],
                                ),
                                route: entityRoute(b['kind'], b['entity_id']),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Material(
                    color: const Color(0xFFEAF1F8),
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(Icons.supervisor_account_outlined),
                      title: const Text(
                        '家长入口',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/parent-gate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class JournalListScreen extends StatefulWidget {
  const JournalListScreen(this.kind, {super.key});
  final String kind;
  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  String filter = '全部', query = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.atlas.journal,
    builder: (context, _) {
      final j = context.atlas.journal,
          isNotes = widget.kind == 'notes',
          isBookmarks = widget.kind == 'bookmarks';
      final rows = isNotes
          ? j.notes
          : isBookmarks
          ? j.bookmarks
          : j.history;
      final labels = {
        'country': '国家',
        'article': '文章',
        'place': '地点',
        'topic': '专题',
        'region': '专题',
      };
      final filtered = rows
          .where(
            (r) =>
                (filter == '全部' || labels[r['kind']] == filter) &&
                (query.isEmpty ||
                    '${r['title']} ${r['text']} ${r['question']}'.contains(
                      query,
                    )),
          )
          .toList();
      return AtlasPage(
        title: isNotes
            ? '探索笔记'
            : isBookmarks
            ? '我的收藏'
            : '阅读足迹',
        actions: [
          if (isNotes)
            IconButton(
              tooltip: '新建笔记',
              onPressed: () => context.push('/me/notes/new'),
              icon: const Icon(Icons.add),
            ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNotes)
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '找找我的发现或问题',
                ),
                onChanged: (v) => setState(() => query = v),
              )
            else
              FilterStrip(
                values: const ['全部', '国家', '文章', '地点', '专题'],
                selected: filter,
                onSelected: (v) => setState(() => filter = v),
              ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              AtlasEmpty(
                title: isNotes
                    ? '还没有写下发现'
                    : isBookmarks
                    ? '把喜欢的世界收藏起来'
                    : '从第一次探索开始',
                message: isNotes
                    ? '一个新发现，或者一个还想知道的问题，都可以记下来。'
                    : '去读一篇文章，或看看地图上的国家。',
                action: isNotes ? '写一条笔记' : '去探索',
                onAction: () => isNotes
                    ? context.push('/me/notes/new')
                    : context.go('/encyclopedia'),
              ),
            for (final r in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: isNotes
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AtlasPalette.line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            (r['text'] as String).isNotEmpty
                                ? r['text']
                                : r['question'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${(r['title'] as String).isNotEmpty ? r['title'] : '自由笔记'} · ${(r['updated_at'] as String).split('T').first}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AtlasPalette.muted,
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/me/notes/${r['id']}/edit'),
                        ),
                      )
                    : ContentRow(
                        title: r['kind'] == 'country' && r['entity_id'] == 'twn'
                            ? '中国'
                            : r['title'],
                        subtitle:
                            '${labels[r['kind']] ?? '探索'}${r['kind'] == 'article' && j.progress[r['entity_id']] != null ? ' · ${j.progress[r['entity_id']]?['completed'] == 1 ? '已读过' : '继续阅读'}' : ''}',
                        mediaId: entityMedia(
                          context.atlas,
                          r['kind'],
                          r['entity_id'],
                        ),
                        outlined: true,
                        onTap: () => context.push(
                          entityRoute(r['kind'], r['entity_id']),
                        ),
                        trailing: isBookmarks
                            ? IconButton(
                                tooltip: '取消收藏',
                                onPressed: () => atlasAction(
                                  context,
                                  () => j.toggle(
                                    r['kind'],
                                    r['entity_id'],
                                    r['title'],
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.bookmark,
                                  color: AtlasPalette.navy,
                                ),
                              )
                            : null,
                      ),
              ),
          ],
        ),
      );
    },
  );
}

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.id = 'new',
    this.entityId = '',
    this.kind = 'article',
  });
  final String id, entityId, kind;
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final text = TextEditingController(), question = TextEditingController();
  late String id = widget.id == 'new'
      ? 'note-${DateTime.now().microsecondsSinceEpoch}'
      : widget.id;
  String kind = 'discovery',
      entityKind = 'article',
      entity = '',
      title = '',
      status = '写下你自己的发现';
  Timer? timer;
  AtlasServices? services;
  bool initialized = false, dirty = false, deleting = false;
  int revision = 0;
  Future<bool>? saving;
  String get draftKey =>
      'note-draft-${widget.id == 'new' && widget.entityId.isNotEmpty ? 'new-${widget.entityId}' : widget.id}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    services = context.atlas;
    final row = services!.journal.notes
        .where((n) => n['id'] == widget.id)
        .firstOrNull;
    entity = row?['entity_id'] ?? widget.entityId;
    entityKind = services!.content.place(entity) != null
        ? 'place'
        : services!.content.country(entity) != null
        ? 'country'
        : services!.content.topic(entity) != null
        ? 'topic'
        : widget.kind;
    kind = row?['kind'] ?? 'discovery';
    title =
        row?['title'] ??
        services!.content.article(entity)?.title ??
        services!.content.place(entity)?.name ??
        services!.content.country(entity)?.name ??
        '';
    text.text = row?['text'] ?? '';
    question.text = row?['question'] ?? '';
    final draft = services!.preferences.values[draftKey];
    if (draft is Json) {
      id = draft['id'];
      text.text = draft['text'];
      question.text = draft['question'];
      kind = draft['kind'];
      entity = draft['entity'];
      entityKind = draft['entityKind'] ?? entityKind;
      title = draft['title'];
      dirty = true;
      status = '已恢复上次的草稿';
    }
    text.addListener(changed);
    question.addListener(changed);
  }

  void changed() {
    if (deleting) return;
    revision++;
    dirty = true;
    setState(() => status = '正在保存…');
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 650), save);
  }

  Future<bool> save() {
    if (deleting) return Future.value(false);
    return saving ??= drainSaves().whenComplete(() => saving = null);
  }

  Json snapshot() => {
    'id': id,
    'text': text.text,
    'question': question.text,
    'kind': kind,
    'entity': entity,
    'entityKind': entityKind,
    'title': title,
  };

  Future<bool> drainSaves() async {
    while (dirty && mounted && !deleting) {
      if (!await saveSnapshot()) return false;
    }
    return !dirty && !deleting;
  }

  Future<bool> saveSnapshot() async {
    if (text.text.trim().isEmpty && question.text.trim().isEmpty) {
      if (mounted) setState(() => status = '先写下一个发现或问题吧');
      return false;
    }
    final draft = snapshot(), savedRevision = revision;
    try {
      await services!.preferences.set(draftKey, draft);
      await services!.journal.saveNote(
        id: id,
        kind: draft['kind'],
        text: draft['text'],
        question: draft['question'],
        entityId: draft['entity'],
        title: draft['title'],
      );
      dirty = savedRevision != revision;
      if (!dirty) await services!.preferences.set(draftKey, null);
      if (mounted) setState(() => status = dirty ? '正在保存…' : '已保存到这台设备');
      return true;
    } catch (_) {
      if (mounted) setState(() => status = '保存失败，请再试一次');
      return false;
    }
  }

  Future<void> finish() async {
    timer?.cancel();
    if (await save() && mounted) backOrHome(context, '/me/notes');
  }

  @override
  void dispose() {
    timer?.cancel();
    if (dirty && !deleting) {
      final draft = snapshot();
      final pending = saving ?? Future.value(true);
      unawaited(
        pending
            .then((_) => services!.preferences.set(draftKey, draft))
            .catchError((Object _) {}),
      );
    }
    text.dispose();
    question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AtlasPage(
    title: '记下一个发现',
    liftBottomForKeyboard: true,
    bottom: Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
      child: PrimaryAction(
        '保存笔记',
        onPressed: () async {
          if (await save() && mounted) {
            showMessage(this.context, '笔记已经保存在这台设备');
          }
        },
      ),
    ),
    actions: [
      TextButton(onPressed: finish, child: const Text('完成')),
      if (widget.id != 'new')
        IconButton(
          tooltip: '删除笔记',
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除这条笔记？'),
                content: const Text('删除后可以立即撤销。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('保留'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('删除笔记'),
                  ),
                ],
              ),
            );
            if (yes == true && context.mounted) {
              final messenger = ScaffoldMessenger.of(context);
              timer?.cancel();
              deleting = true;
              try {
                await saving;
                final original = services!.journal.notes
                    .where((n) => n['id'] == id)
                    .firstOrNull;
                await services!.journal.deleteNote(id, draftKey: draftKey);
                await services!.preferences.load();
                dirty = false;
                if (context.mounted) backOrHome(context, '/me/notes');
                if (original != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('笔记已删除'),
                      duration: const Duration(seconds: 8),
                      action: SnackBarAction(
                        label: '撤销',
                        onPressed: () async {
                          try {
                            await services!.journal.saveNote(
                              id: original['id'],
                              kind: original['kind'],
                              text: original['text'],
                              question: original['question'],
                              entityId: original['entity_id'],
                              title: original['title'],
                            );
                          } catch (_) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('恢复没有完成，请再试一次。')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }
              } catch (_) {
                deleting = false;
                if (context.mounted) showMessage(context, '删除没有完成，请再试一次');
              }
            }
          },
          icon: const Icon(Icons.delete_outline),
        ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'discovery', label: Text('我的发现')),
              ButtonSegment(value: 'question', label: Text('还想知道')),
            ],
            selected: {kind},
            showSelectedIcon: false,
            onSelectionChanged: (v) {
              setState(() => kind = v.first);
              changed();
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AtlasPalette.navy,
              selectedForegroundColor: Colors.white,
              backgroundColor: AtlasPalette.canvas,
              side: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: text,
          minLines: 8,
          maxLines: null,
          maxLength: 5000,
          style: const TextStyle(
            fontSize: 21,
            height: 1.9,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: kind == 'question' ? '我还想知道……' : '我发现……',
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        if (entity.isNotEmpty) ...[
          const SizedBox(height: 14),
          ContentRow(
            title: title,
            subtitle: '关联内容',
            mediaId: entityMedia(context.atlas, entityKind, entity),
            outlined: true,
            onTap: () => context.push(entityRoute(entityKind, entity)),
          ),
        ],
        const EditorialHeading('还想问一句'),
        TextField(
          controller: question,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: '你还有什么想知道的？',
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              status.startsWith('已保存')
                  ? Icons.check_circle_outline
                  : Icons.edit_outlined,
              color: AtlasPalette.muted,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                status,
                style: const TextStyle(color: AtlasPalette.muted, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
