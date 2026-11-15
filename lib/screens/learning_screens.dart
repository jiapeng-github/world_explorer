import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/explorer_store.dart';
import '../core/narration.dart';
import '../core/palette.dart';
import '../models/catalog.dart';
import '../widgets/atlas_widgets.dart';
import '../widgets/world_map.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.country});
  final Country country;
  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final Narration _narration = Narration();
  int _paragraph = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _paragraph =
          (ExplorerScope.of(context).readingPositions[widget.country.id] ?? 0)
              .clamp(0, widget.country.story.paragraphs.length - 1);
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  void _move(int value) {
    unawaited(_narration.stop());
    setState(() => _paragraph = value);
    unawaited(ExplorerScope.of(context).saveReading(widget.country.id, value));
  }

  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final country = widget.country;
    final paragraphs = country.story.paragraphs;
    return ExplorerPage(
      title: '${country.name}的故事',
      subtitle: '慢慢看，世界里藏着很多线索',
      actions: [
        IconButton(
          tooltip: store.favorites.contains(country.id) ? '取消收藏' : '收藏这个故事',
          onPressed: () => store.toggleFavorite(country.id),
          icon: Icon(
            store.favorites.contains(country.id)
                ? Icons.bookmark
                : Icons.bookmark_outline,
          ),
        ),
        IconButton(
          tooltip: '阅读设置',
          onPressed: () => _showReadingSettings(context),
          icon: const Icon(Icons.text_fields),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AtlasTag(country.continent, icon: Icons.public),
                AtlasTag(
                  '发现 ${_paragraph + 1} / ${paragraphs.length}',
                  color: AtlasColors.sand,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              country.story.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final visual = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Illustration(
                      asset: country.heroAsset,
                      height: constraints.maxWidth >= 820 ? 320 : 220,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '插画帮助想象主题，不能用来判断真实地形。',
                      style: TextStyle(fontSize: 13, color: AtlasColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        unawaited(_narration.stop());
                        openScreen(
                          context,
                          ObservationScreen(country: country),
                        );
                      },
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('打开观察手记'),
                    ),
                  ],
                );
                final reading = AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book,
                            color: AtlasColors.forest,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '第 ${_paragraph + 1} 段',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          paragraphs[_paragraph],
                          key: ValueKey(_paragraph),
                          style: const TextStyle(fontSize: 22, height: 1.85),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListenableBuilder(
                        listenable: _narration,
                        builder: (context, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: !store.voiceEnabled
                                  ? null
                                  : () {
                                      if (_narration.speaking ||
                                          _narration.preparing) {
                                        unawaited(_narration.stop());
                                      } else {
                                        unawaited(
                                          _narration.speak(
                                            paragraphs[_paragraph],
                                            rate: store.speechRate,
                                          ),
                                        );
                                      }
                                    },
                              icon: Icon(
                                _narration.speaking
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_outlined,
                              ),
                              label: Text(
                                !store.voiceEnabled
                                    ? '朗读已关闭'
                                    : _narration.preparing
                                    ? '正在准备语音…'
                                    : _narration.speaking
                                    ? '停止朗读'
                                    : '听这一段',
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '设备中文语音 · 点按后朗读',
                              style: TextStyle(
                                fontSize: 12,
                                color: AtlasColors.muted,
                              ),
                            ),
                            if (_narration.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  _narration.error!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AtlasColors.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth >= 820) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: visual),
                      const SizedBox(width: 24),
                      Expanded(child: reading),
                    ],
                  );
                }
                return Column(
                  children: [visual, const SizedBox(height: 20), reading],
                );
              },
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_paragraph > 0)
                  OutlinedButton.icon(
                    onPressed: () => _move(_paragraph - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('上一段'),
                  ),
                FilledButton.icon(
                  onPressed: () {
                    if (_paragraph < paragraphs.length - 1) {
                      _move(_paragraph + 1);
                    } else {
                      unawaited(_narration.stop());
                      openScreen(
                        context,
                        ExplorationIntroScreen(country: country),
                      );
                    }
                  },
                  icon: Icon(
                    _paragraph < paragraphs.length - 1
                        ? Icons.arrow_forward
                        : Icons.explore_outlined,
                  ),
                  label: Text(
                    _paragraph < paragraphs.length - 1 ? '下一段' : '动手做个发现',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSources(context, country),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('知识从哪里来'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ObservationScreen extends StatelessWidget {
  const ObservationScreen({super.key, required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '${country.name}观察手记',
    subtitle: '观察地图，也把自己的问题留下来',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorldMap(
            countries: ExplorerScope.of(context).catalog.countries,
            selectedId: country.id,
            height: 300,
          ),
          const SizedBox(height: 20),
          AtlasCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AtlasTag('先观察，再想一想', icon: Icons.visibility_outlined),
                const SizedBox(height: 18),
                Text(
                  country.story.observation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Text(
                  country.story.prompt,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _addCuriosity(context, country),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('记下我的问题'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('回到故事'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Illustration(asset: country.heroAsset, height: 260),
          const SizedBox(height: 10),
          const Text(
            '主题插画用于想象与讨论；地理位置请以地图和知识资料为准。',
            style: TextStyle(fontSize: 13, color: AtlasColors.muted),
          ),
        ],
      ),
    ),
  );
}

class ExplorationIntroScreen extends StatelessWidget {
  const ExplorationIntroScreen({super.key, required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final hasProgress = (store.quizPositions[country.id] ?? 0) > 0;
    return ExplorerPage(
      title: '${country.name}小探索',
      subtitle: '不计时，也不用一次答对',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Illustration(
              asset: 'assets/images/discovery-finish.png',
              height: 220,
            ),
            const SizedBox(height: 24),
            Text(
              '把刚才的故事，变成自己的发现',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('找一个地方，观察一个线索，再想一想原因。遇到不确定的答案，可以看提示，也可以回去读故事。'),
            const SizedBox(height: 24),
            for (var i = 0; i < country.quiz.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AtlasCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: AtlasColors.mint,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AtlasColors.forest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i == 0
                                  ? '在地图上找一找'
                                  : i == 1
                                  ? '把线索连起来'
                                  : '说说你的新发现',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              country.quiz[i].question,
                              style: const TextStyle(color: AtlasColors.muted),
                            ),
                          ],
                        ),
                      ),
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
                      openScreen(context, QuizScreen(country: country)),
                  icon: const Icon(Icons.explore),
                  label: Text(hasProgress ? '继续上次的探索' : '开始探索'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      openScreen(context, StoryScreen(country: country)),
                  child: const Text('再读一读故事'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.country});
  final Country country;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  String? _selection;
  bool _loaded = false,
      _showHint = false,
      _wrong = false,
      _correct = false,
      _canPop = false,
      _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _index = (ExplorerScope.of(context).quizPositions[widget.country.id] ?? 0)
          .clamp(0, widget.country.quiz.length - 1);
      _loaded = true;
    }
  }

  Future<void> _leave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('先把发现存起来？'),
        content: const Text('已完成的步骤会留在这里。下次可以接着探索。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续探索'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存并离开'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      await ExplorerScope.of(context).saveQuiz(widget.country.id, _index);
      if (!mounted) return;
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _submit() async {
    if (_busy || _selection == null) return;
    final store = ExplorerScope.of(context);
    final question = widget.country.quiz[_index];
    if (!_correct) {
      setState(() {
        _correct = _selection == question.answerId;
        _wrong = !_correct;
        _showHint = _wrong;
      });
      return;
    }
    setState(() => _busy = true);
    if (_index + 1 < widget.country.quiz.length) {
      await store.saveQuiz(widget.country.id, _index + 1);
      if (!mounted) return;
      setState(() {
        _index++;
        _selection = null;
        _correct = false;
        _wrong = false;
        _showHint = false;
        _busy = false;
      });
    } else {
      await store.completeCountry(widget.country.id);
      if (!mounted) return;
      setState(() => _canPop = true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DiscoverySummaryScreen(country: widget.country),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final question = widget.country.quiz[_index];
    final countries = store.catalog.countries;
    final labels = {
      for (var i = 0; i < countries.length; i++)
        countries[i].id: String.fromCharCode(65 + i),
    };
    final location = question.type == 'location';
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: ExplorerPage(
        title: '${widget.country.name}小探索',
        subtitle: '第 ${_index + 1} 个发现 · 共 ${widget.country.quiz.length} 个',
        actions: [TextButton(onPressed: _leave, child: const Text('稍后继续'))],
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  widget.country.quiz.length,
                  (i) => Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? AtlasColors.forest
                            : AtlasColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                location ? '看看地图上的字母，再选择一个位置。' : '选一个你认为合适的答案，再看看为什么。',
                style: const TextStyle(color: AtlasColors.muted),
              ),
              const SizedBox(height: 24),
              if (location) ...[
                WorldMap(
                  countries: countries,
                  selectedId: _selection,
                  showLabels: false,
                  markerLabels: labels,
                  height: 300,
                  onSelect: _correct
                      ? null
                      : (id) {
                          setState(() {
                            _selection = id;
                            _wrong = false;
                          });
                        },
                ),
                const SizedBox(height: 20),
              ] else ...[
                AtlasCard(
                  color: AtlasColors.mint,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        color: AtlasColors.forest,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '想一想我们刚读过的${widget.country.name}故事。',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              for (final option in question.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerTile(
                    selected: _selection == option.id,
                    correct: _correct && _selection == option.id,
                    label: location
                        ? '位置 ${labels[option.id] ?? option.text}'
                        : option.text,
                    onTap: _correct
                        ? null
                        : () => setState(() {
                            _selection = option.id;
                            _wrong = false;
                          }),
                  ),
                ),
              if (_wrong)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: AtlasCard(
                    color: const Color(0xFFFFF1D7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '没关系，再观察一次',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(question.hint),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _wrong = false;
                            _selection = null;
                          }),
                          child: const Text('再选一次'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_correct)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: AtlasCard(
                    color: AtlasColors.mint,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AtlasColors.forest,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '你找到线索了',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.explanation,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showHint && !_wrong && !_correct)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AtlasCard(
                    color: AtlasColors.sand.withValues(alpha: .35),
                    child: Text(question.hint),
                  ),
                ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _selection == null || _busy ? null : _submit,
                    icon: Icon(_correct ? Icons.arrow_forward : Icons.check),
                    label: Text(
                      _busy
                          ? '正在收好发现…'
                          : !_correct
                          ? '确认选择'
                          : _index + 1 == widget.country.quiz.length
                          ? '看看我的新发现'
                          : '下一个发现',
                    ),
                  ),
                  if (!_correct)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showHint = !_showHint),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(_showHint ? '收起线索' : '给我一个线索'),
                    ),
                  TextButton(
                    onPressed: () => openScreen(
                      context,
                      StoryScreen(country: widget.country),
                    ),
                    child: const Text('回顾故事'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
  });
  final String label;
  final bool selected, correct;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: AtlasCard(
      padding: const EdgeInsets.all(20),
      color: selected ? AtlasColors.mint : Colors.white,
      borderColor: selected ? AtlasColors.forest : AtlasColors.line,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            correct
                ? Icons.check_circle
                : selected
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: selected ? AtlasColors.forest : AtlasColors.muted,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    ),
  );
}

class DiscoverySummaryScreen extends StatelessWidget {
  const DiscoverySummaryScreen({super.key, required this.country});
  final Country country;
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    final earned = store.completed.contains(country.id);
    return ExplorerPage(
      title: '收好这次新发现',
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Illustration(
              asset: 'assets/images/discovery-finish.png',
              height: 230,
            ),
            const SizedBox(height: 24),
            Text(
              '世界，又熟悉了一点点',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              earned ? '${country.name}的探索印章已收进你的护照。' : '回到小探索，完成观察后就能留下这枚印章。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AtlasColors.mint,
                        child: Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${country.name} · 我的新发现',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (earned)
                        const Icon(
                          Icons.verified_outlined,
                          color: AtlasColors.forest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final question in country.quiz)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check,
                              size: 20,
                              color: AtlasColors.forest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(question.explanation)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => goHome(context),
                  icon: const Icon(Icons.public),
                  label: const Text('继续探索世界'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addCuriosity(context, country),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('记下一个新问题'),
                ),
                TextButton.icon(
                  onPressed: () => _showRest(context),
                  icon: const Icon(Icons.park_outlined),
                  label: const Text('休息一下'),
                ),
              ],
            ),
            if (store.storageError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  store.storageError!,
                  style: const TextStyle(color: AtlasColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addCuriosity(BuildContext context, Country country) async {
  final value = await showDialog<String>(
    context: context,
    builder: (_) => _CuriosityDialog(prompt: country.story.prompt),
  );
  if (value != null && context.mounted) {
    final store = ExplorerScope.of(context);
    await store.addQuestion(value, countryId: country.id);
    if (context.mounted) {
      showNotice(context, store.storageError ?? '问题已记下，和家人一起寻找答案吧。');
    }
  }
}

class _CuriosityDialog extends StatefulWidget {
  const _CuriosityDialog({required this.prompt});
  final String prompt;
  @override
  State<_CuriosityDialog> createState() => _CuriosityDialogState();
}

class _CuriosityDialogState extends State<_CuriosityDialog> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('你还想知道什么？'),
    content: SizedBox(
      width: 480,
      child: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: widget.prompt,
          labelText: '我的好奇问题',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('稍后再写'),
      ),
      FilledButton(
        onPressed: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.pop(context, controller.text.trim());
          }
        },
        child: const Text('收进护照'),
      ),
    ],
  );
}

void _showSources(BuildContext context, Country country) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('知识从哪里来'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('故事根据以下资料编写，插画不作为知识依据。'),
              const SizedBox(height: 16),
              for (final source in country.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '核验日期：${source.checkedAt}',
                        style: const TextStyle(
                          fontSize: 13,
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
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: source.url),
                          );
                          if (context.mounted) showNotice(context, '来源链接已复制。');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制链接'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('继续阅读'),
        ),
      ],
    ),
  );
}

void _showReadingSettings(BuildContext context) {
  final store = ExplorerScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('读得舒服，听得清楚', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              const Text('文字大小'),
              Slider(
                value: store.textScale,
                min: .9,
                max: 1.35,
                divisions: 9,
                label: '${(store.textScale * 100).round()}%',
                onChanged: (value) => store.updateSettings(textScale: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('允许点按朗读'),
                value: store.voiceEnabled,
                onChanged: (value) => store.updateSettings(voiceEnabled: value),
              ),
              const Text('朗读语速'),
              Slider(
                value: store.speechRate,
                min: .25,
                max: .65,
                divisions: 8,
                label: store.speechRate < .4
                    ? '慢一点'
                    : store.speechRate > .5
                    ? '快一点'
                    : '适中',
                onChanged: (value) => store.updateSettings(speechRate: value),
              ),
              const Text(
                '语音由设备提供，中文声音是否可用取决于系统设置。',
                style: TextStyle(fontSize: 13, color: AtlasColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showRest(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.park_outlined,
        size: 48,
        color: AtlasColors.forest,
      ),
      title: const Text('让好奇心休息一会儿'),
      content: const Text('发现已经收好了。放下平板，伸伸懒腰，去看看窗外的世界吧。'),
      actions: [
        FilledButton(
          onPressed: () {
            ExplorerScope.of(context).restartSession();
            goHome(context);
          },
          child: const Text('收好平板，结束这次探索'),
        ),
      ],
    ),
  );
}
