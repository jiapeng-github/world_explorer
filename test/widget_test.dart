import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_explorer/core/explorer_store.dart';
import 'package:world_explorer/core/palette.dart';
import 'package:world_explorer/legacy_main.dart';
import 'package:world_explorer/models/catalog.dart';
import 'package:world_explorer/screens/learning_screens.dart';
import 'package:world_explorer/screens/passport_screens.dart';
import 'package:world_explorer/screens/world_screens.dart';
import 'package:world_explorer/widgets/world_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;

  setUpAll(() async {
    final font = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/images/NotoSansSC.ttf'));
    await font.load();
    catalog = await Catalog.load();
    // Large map assets decode in an isolate; finish that before fake async starts.
    await WorldMap.preload();
  });

  testWidgets('a child can create a profile and enter the world', (
    tester,
  ) async {
    final storage = MemoryProgressStorage();
    final store = ExplorerStore(catalog: catalog, storage: storage);
    await _exerciseScreen(
      tester,
      size: const Size(1024, 768),
      store: store,
      app: WorldExplorerApp(store: store),
      exercise: () async {
        await _tapVisible(tester, find.byKey(const ValueKey('welcome-start')));
        expect(find.byType(ProfileScreen), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('nickname-field')),
          '小河',
        );
        await _tapVisible(tester, find.text('完成，出发探索'));
        expect(find.byType(HomeShell), findsOneWidget);
        expect(find.byType(WelcomeScreen), findsNothing);
        expect(store.onboarded, isTrue);
        expect(store.nickname, '小河');
        expect(storage.data['nickname'], '小河');
        expect(storage.data['onboarded'], isTrue);
      },
    );
  });

  testWidgets('welcome can be skipped without entering personal details', (
    tester,
  ) async {
    final store = ExplorerStore(
      catalog: catalog,
      storage: MemoryProgressStorage(),
    );
    await _exerciseScreen(
      tester,
      size: const Size(390, 844),
      store: store,
      app: WorldExplorerApp(store: store),
      exercise: () async {
        await _tapVisible(tester, find.text('先看看世界 →'));
        expect(find.byType(HomeShell), findsOneWidget);
        expect(store.onboarded, isTrue);
        expect(store.nickname, '小小探险家');
      },
    );
  });

  testWidgets(
    'wrong answers stay on the question; three discoveries earn a stamp',
    (tester) async {
      final storage = MemoryProgressStorage();
      final store = ExplorerStore(catalog: catalog, storage: storage);
      final country = catalog.country('egypt');
      String optionLabel(QuizQuestion question, String id) {
        if (question.type == 'location') {
          final position = catalog.countries.indexWhere(
            (item) => item.id == id,
          );
          return '位置 ${String.fromCharCode(65 + position)}';
        }
        return question.options.singleWhere((option) => option.id == id).text;
      }

      await _exerciseScreen(
        tester,
        size: const Size(1024, 768),
        store: store,
        app: _pageApp(store, QuizScreen(country: country)),
        exercise: () async {
          final first = country.quiz.first;
          final wrong = first.options.firstWhere(
            (option) => option.id != first.answerId,
          );
          await _tapVisible(tester, find.text(optionLabel(first, wrong.id)));
          await _tapVisible(tester, find.text('确认选择'));
          expect(find.text('没关系，再观察一次'), findsOneWidget);
          expect(find.text('第 1 个发现 · 共 3 个'), findsOneWidget);
          expect(find.text('下一个发现'), findsNothing);
          expect(store.completed, isEmpty);

          // Repeated submission must not turn an incorrect choice into progress.
          await _tapVisible(tester, find.text('确认选择'));
          expect(find.text('第 1 个发现 · 共 3 个'), findsOneWidget);
          expect(store.quizPositions[country.id] ?? 0, 0);

          for (var index = 0; index < country.quiz.length; index++) {
            final question = country.quiz[index];
            expect(find.text('第 ${index + 1} 个发现 · 共 3 个'), findsOneWidget);
            await _tapVisible(
              tester,
              find.text(optionLabel(question, question.answerId)),
            );
            await _tapVisible(tester, find.text('确认选择'));
            expect(find.text('你找到线索了'), findsOneWidget);
            expect(store.completed, isEmpty);
            await _tapVisible(
              tester,
              find.text(index == country.quiz.length - 1 ? '看看我的新发现' : '下一个发现'),
            );
          }

          expect(find.byType(DiscoverySummaryScreen), findsOneWidget);
          expect(find.text('埃及的探索印章已收进你的护照。'), findsOneWidget);
          expect(store.completed, {'egypt'});
          expect(store.quizPositions.containsKey('egypt'), isFalse);
          final reopened = ExplorerStore(catalog: catalog, storage: storage);
          await reopened.load();
          expect(reopened.completed, {'egypt'});
          reopened.dispose();
        },
      );
    },
  );

  testWidgets('encyclopedia tabs open a complete landmark and timeline', (
    tester,
  ) async {
    final store = ExplorerStore(
      catalog: catalog,
      storage: MemoryProgressStorage(),
    );
    final c = catalog.country('egypt');
    await _exerciseScreen(
      tester,
      size: const Size(390, 844),
      store: store,
      app: _pageApp(store, CountryScreen(country: c)),
      exercise: () async {
        await _tapVisible(tester, find.byKey(const ValueKey('country-tab-3')));
        expect(find.text('开罗建城'), findsOneWidget);
        await _tapVisible(tester, find.byKey(const ValueKey('country-tab-2')));
        await _tapVisible(tester, find.text('吉萨金字塔群'));
        expect(find.byType(LandmarkScreen), findsOneWidget);
        expect(find.text(c.landmarks.first.description), findsOneWidget);
      },
    );
  });

  testWidgets('article question reveals explanation and read status persists', (
    tester,
  ) async {
    final storage = MemoryProgressStorage();
    final store = ExplorerStore(catalog: catalog, storage: storage);
    final c = catalog.country('china'),
        t = catalog.country('china').topics.first;
    await _exerciseScreen(
      tester,
      size: const Size(390, 844),
      store: store,
      app: _pageApp(store, TopicScreen(country: c, topic: t)),
      exercise: () async {
        await _tapVisible(tester, find.byKey(const ValueKey('topic-question')));
        expect(find.text(t.answer), findsOneWidget);
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('mark-topic-read')),
        );
        expect(store.readTopics, {'china/geography'});
        final restored = ExplorerStore(catalog: catalog, storage: storage);
        await restored.load();
        expect(restored.readTopics, {'china/geography'});
        restored.dispose();
      },
    );
  });

  testWidgets(
    'atlas selects a country, zooms, switches layers and opens a landmark',
    (tester) async {
      final store = ExplorerStore(
        catalog: catalog,
        storage: MemoryProgressStorage(),
      );
      await _exerciseScreen(
        tester,
        size: const Size(1024, 768),
        store: store,
        app: _pageApp(store, const MapScreen()),
        exercise: () async {
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('atlas-country-china')),
          );
          expect(
            tester.widget<WorldMap>(find.byType(WorldMap)).selectedId,
            'china',
          );
          final viewer = tester.widget<InteractiveViewer>(
            find.byType(InteractiveViewer),
          );
          expect(
            viewer.transformationController!.value.getMaxScaleOnAxis(),
            greaterThan(2),
          );
          await _tapVisible(tester, find.byKey(const ValueKey('map-reset')));
          expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
          await _tapVisible(tester, find.byKey(const ValueKey('map-zoom-in')));
          expect(
            viewer.transformationController!.value.getMaxScaleOnAxis(),
            greaterThan(1),
          );
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('map-layer-landmarks')),
          );
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('landmark-marker-jiuzhaigou')),
          );
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('map-open-detail')),
          );
          expect(
            tester
                .widget<LandmarkScreen>(find.byType(LandmarkScreen))
                .landmark
                .id,
            'jiuzhaigou',
          );
        },
      );
    },
  );

  final pages = <String, Widget Function(Catalog)>{
    'world home': (_) => const HomeShell(),
    'country overview': (catalog) =>
        CountryScreen(country: catalog.country('egypt')),
    'atlas': (_) => const MapScreen(),
    'encyclopedia article': (catalog) => TopicScreen(
      country: catalog.country('china'),
      topic: catalog.country('china').topics.first,
    ),
    'landmark detail': (catalog) => LandmarkScreen(
      country: catalog.country('brazil'),
      landmark: catalog.country('brazil').landmarks.first,
    ),
    'story': (catalog) => StoryScreen(country: catalog.country('egypt')),
    'quiz': (catalog) => QuizScreen(country: catalog.country('egypt')),
    'parent center': (_) => const ParentCenterScreen(),
    'passport with a stamp': (_) =>
        const Scaffold(body: SafeArea(child: PassportScreen())),
    'profile': (_) => const ProfileScreen(),
  };

  for (final size in [const Size(1024, 768), const Size(390, 844)]) {
    for (final entry in pages.entries) {
      testWidgets(
        '${entry.key} fits ${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
          final store = ExplorerStore(
            catalog: catalog,
            storage: MemoryProgressStorage(),
          );
          await store.saveProfile(name: '小河', selectedAvatar: '🐼');
          await store.completeCountry('egypt');
          await store.toggleFavorite('brazil');
          await store.addQuestion('河流为什么会转弯？', countryId: 'egypt');
          await _exerciseScreen(
            tester,
            size: size,
            store: store,
            app: _pageApp(store, entry.value(catalog)),
            exercise: () async {
              expect(tester.takeException(), isNull);
              final scrollable = find.byType(Scrollable).hitTestable();
              if (scrollable.evaluate().isNotEmpty) {
                await tester.drag(scrollable.first, const Offset(0, -600));
                await _settle(tester);
                expect(tester.takeException(), isNull);
              }
            },
          );
        },
      );
    }
  }
}

Widget _pageApp(ExplorerStore store, Widget page) => ExplorerScope(
  store: store,
  child: MaterialApp(theme: buildAtlasTheme(), home: page),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  // Build destinations added by a tap before flushing their asset callbacks.
  await tester.pump();
  // The cached map future was created outside the test's fake async zone.
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}

Future<void> _exerciseScreen(
  WidgetTester tester, {
  required Size size,
  required ExplorerStore store,
  required Widget app,
  required Future<void> Function() exercise,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  try {
    await tester.pumpWidget(app);
    await _settle(tester);
    await exercise();
    expect(tester.takeException(), isNull);
  } finally {
    // Unmount first so the app's break reminder timer and story narrator stop.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    store.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
