import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../design/atlas_theme.dart';
import '../../design/components.dart';
import '../../design/photo_points.dart';
import '../../map_engine/atlas_map.dart';
import '../../map_engine/country_learning_map.dart';
import '../reader/learning_diagrams.dart';
import 'usa_exercise_map.dart';
import 'gbr_exercise_map.dart';
import 'fra_exercise_map.dart';
import 'deu_exercise_map.dart';
import 'kenya_exercise_map.dart';
import 'norway_exercise_map.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen(this.id, {super.key});
  final String id;
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  String? selection;
  bool submitted = false, busy = false;
  String? restoredId;
  @override
  void didUpdateWidget(ExerciseScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      selection = null;
      submitted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = context.atlas.content.exercise(widget.id);
    if (e == null) {
      return const AtlasPage(
        title: '想一想',
        child: AtlasEmpty(title: '暂时没有这道题', message: '你可以继续阅读文章。'),
      );
    }
    if (e.countryId == 'norway' && restoredId != e.id) {
      restoredId = e.id;
      final attempt = context.atlas.journal.attempts[e.id];
      selection = attempt?['answer_id'] as String?;
      submitted = selection != null;
    }
    final group = context.atlas.content.exercises
            .where((x) => x.countryId == e.countryId)
            .toList(),
        article = context.atlas.content.article(e.articleId);
    final position = group.indexOf(e), correct = selection == e.answerId;
    final profile = countryMapProfile(e.countryId);
    final world = e.type == 'location' && e.mapScope == 'world';
    final local =
        e.type == 'location' &&
        profile != null &&
        (e.mapScope == 'country' ||
            e.options.any((o) => o['featureId'] != null));
    final norwayLocal =
        e.countryId == 'norway' &&
        e.type == 'location' &&
        e.mapScope == 'country';
    final kenyaLocal =
        e.countryId == 'kenya' &&
        e.type == 'location' &&
        e.mapScope == 'country';
    final deuLocal =
        e.countryId == 'deu' && e.type == 'location' && e.mapScope == 'country';
    final fraLocal =
        e.countryId == 'fra' && e.type == 'location' && e.mapScope == 'country';
    final gbrLocal =
        e.countryId == 'gbr' && e.type == 'location' && e.mapScope == 'country';
    final usaLocal =
        e.countryId == 'usa' && e.type == 'location' && e.mapScope == 'country';
    final ids = e.options
        .map((o) => (o['featureId'] ?? o['id']) as String)
        .toList();
    final optionIndex = e.options.indexWhere((o) => o['id'] == selection);
    final selectedMapId = optionIndex < 0 ? null : ids[optionIndex];
    void selectMapOption(String id) {
      final index = ids.indexOf(id);
      if (index >= 0) setState(() => selection = e.options[index]['id']);
    }

    final photoQuestion =
        e.mediaIds.length == 1 &&
        e.options.every((o) => o['x'] is num && o['y'] is num);
    final mapHeight = MediaQuery.sizeOf(context).width < 600 ? 300.0 : 390.0;
    return AtlasPage(
      title: '想一想 · ${position + 1}/${group.length}',
      width: 720,
      bottom: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: !submitted
                ? PrimaryAction(
                    busy
                        ? '正在保存…'
                        : const {
                            'egypt',
                            'usa',
                            'gbr',
                            'fra',
                            'deu',
                            'kenya',
                            'norway',
                            'aus',
                          }.contains(e.countryId)
                        ? '确认'
                        : '看看我的想法',
                    onPressed: selection == null || busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            await atlasAction(context, () async {
                              await context.atlas.journal.answer(
                                e.id,
                                selection!,
                                correct,
                              );
                              if (mounted) setState(() => submitted = true);
                            });
                            if (mounted) setState(() => busy = false);
                          },
                  )
                : PrimaryAction(
                    position + 1 < group.length ? '下一个小问题' : '结束，继续探索',
                    orange: correct,
                    onPressed: () => position + 1 < group.length
                        ? context.replace(
                            '/exercises/${group[position + 1].id}',
                          )
                        : context.go('/countries/${e.countryId}'),
                  ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => backOrHome(context, '/articles/${e.articleId}'),
          child: const Text('跳过'),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (position + 1) / group.length,
            color: AtlasPalette.orange,
            backgroundColor: AtlasPalette.line,
            minHeight: 4,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 18),
          Text(e.question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (world) ...[
            const Text('点选地图上的数字，也可以用下面的选项。'),
            const SizedBox(height: 8),
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AtlasMap(
                  countries: context.atlas.content.countries,
                  candidateIds: e.options
                      .map((o) => o['id'] as String)
                      .toList(),
                  selectedId: selection,
                  onCountry: submitted
                      ? null
                      : (id) => setState(() => selection = id),
                ),
              ),
            ),
          ] else if (norwayLocal)
            SizedBox(
              height: mapHeight,
              child: NorwayExerciseMap(
                key: ValueKey(e.id),
                candidates: ids,
                selected: selectedMapId,
                onSelect: submitted ? null : selectMapOption,
              ),
            )
          else if (kenyaLocal)
            SizedBox(
              height: mapHeight,
              child: KenyaExerciseMap(
                key: ValueKey(e.id),
                candidates: ids,
                selected: selectedMapId,
                onSelect: submitted ? null : selectMapOption,
              ),
            )
          else if (deuLocal)
            SizedBox(
              height: mapHeight,
              child: DeuExerciseMap(
                key: ValueKey(e.id),
                candidates: ids,
                selected: selectedMapId,
                onSelect: submitted ? null : selectMapOption,
              ),
            )
          else if (fraLocal)
            SizedBox(
              height: mapHeight,
              child: FraExerciseMap(
                key: ValueKey(e.id),
                candidates: ids,
                selected: selectedMapId,
                onSelect: submitted ? null : selectMapOption,
              ),
            )
          else if (gbrLocal)
            SizedBox(
              height: mapHeight,
              child: GbrExerciseMap(
                key: ValueKey(e.id),
                candidates: ids,
                selected: selectedMapId,
                onSelect: submitted ? null : selectMapOption,
              ),
            )
          else if (usaLocal)
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: UsaExerciseMap(
                  key: ValueKey(e.id),
                  candidates: ids,
                  selected: selectedMapId,
                  onSelect: submitted ? null : selectMapOption,
                ),
              ),
            )
          else if (local)
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CountryLearningMap(
                  profile: profile,
                  countries: context.atlas.content.countries,
                  places: context.atlas.content.placesIn(e.countryId),
                  selectedId: e.options
                      .where((o) => o['id'] == selection)
                      .map((o) => (o['featureId'] ?? o['id']) as String)
                      .firstOrNull,
                  layer: '河流',
                  allowedIds: e.options
                      .map((o) => o['featureId'] ?? o['id'])
                      .whereType<String>()
                      .toSet(),
                  fitCandidates: e.mapScope == 'country',
                  showLegend: false,
                  onSelect: submitted
                      ? null
                      : (id) {
                          final option = e.options
                              .where((o) => (o['featureId'] ?? o['id']) == id)
                              .firstOrNull;
                          if (option != null) {
                            setState(() => selection = option['id']);
                          }
                        },
                ),
              ),
            )
          else if (e.diagram.isNotEmpty)
            LearningDiagram(
              e.diagram,
              interactive: false,
              initialStep: e.diagramStep,
            )
          else if (photoQuestion)
            PhotoPoints(
              mediaId: e.mediaIds.single,
              points: e.options,
              selected: selection == null
                  ? null
                  : e.options.indexWhere((o) => o['id'] == selection),
              onSelect: submitted
                  ? null
                  : (i) => setState(() => selection = e.options[i]['id']),
              maxHeight: 295,
            )
          else if (e.mediaIds.isNotEmpty)
            LessonPhotos(e.mediaIds, hotspots: e.photoHotspots)
          else
            MediaPhoto(
              e.mediaId.isEmpty ? article?.mediaId ?? '' : e.mediaId,
              fit:
                  e.countryId == 'kenya' &&
                      context
                              .atlas
                              .content
                              .media[e.mediaId.isEmpty
                                  ? article?.mediaId
                                  : e.mediaId]
                              ?.kind ==
                          'diagram'
                  ? BoxFit.contain
                  : BoxFit.cover,
              width: double.infinity,
              height: MediaQuery.sizeOf(context).width < 600 ? 170 : 240,
              radius: 14,
              showCredit: true,
            ),
          const SizedBox(height: 16),
          if (!submitted) ...[
            RadioGroup<String>(
              groupValue: selection,
              onChanged: (v) => setState(() => selection = v),
              child: Column(
                children: [
                  for (final (i, option) in e.options.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RadioListTile<String>(
                        value: option['id'],
                        title: Text(
                          world ||
                                  usaLocal ||
                                  gbrLocal ||
                                  fraLocal ||
                                  deuLocal ||
                                  kenyaLocal ||
                                  norwayLocal
                              ? '${i + 1} · ${option['text']}'
                              : option['text'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selection == option['id']
                                ? AtlasPalette.navy
                                : AtlasPalette.line,
                            width: selection == option['id'] ? 2 : 1,
                          ),
                        ),
                        tileColor: selection == option['id']
                            ? const Color(0xFFEAF2F9)
                            : Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => showMessage(context, e.hint),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('给我一个提示'),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  correct
                      ? Icons.check_circle_outline
                      : Icons.lightbulb_outline,
                  color: correct ? AtlasPalette.success : AtlasPalette.blue,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    correct ? '你找到了关键线索！' : '换一个角度想想',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(e.explanation, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AtlasPalette.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '回到文章找证据',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(article?.title ?? '继续阅读'),
                  TextButton(
                    onPressed: () => context.push(
                      Uri(
                        path: '/articles/${e.articleId}',
                        queryParameters: {
                          if (e.evidenceBlockIds.isNotEmpty)
                            'block': e.evidenceBlockIds.first,
                        },
                      ).toString(),
                    ),
                    child: const Text('回读相关内容  →'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (!correct) ...[
              PrimaryAction(
                '再试一次',
                onPressed: () => setState(() {
                  submitted = false;
                  selection = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}
