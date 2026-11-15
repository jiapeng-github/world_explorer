import '../features/regions/antarctica/antarctica_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../design/atlas_theme.dart';
import '../design/components.dart';
import '../features/discover/discover_screen.dart';
import '../features/atlas/atlas_screen.dart';
import '../features/encyclopedia/encyclopedia_screens.dart';
import '../features/encyclopedia/country_experience.dart';
import '../features/landmarks/place_screens.dart';
import '../features/topics/topic_screens.dart';
import '../features/search/search_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/exercises/exercise_screen.dart';
import '../features/journal/journal_screens.dart';
import '../features/family/family_screens.dart';
import 'services.dart';
import '../features/encyclopedia/zaf_preview.dart';

class WorldAtlasApp extends StatefulWidget {
  const WorldAtlasApp({
    super.key,
    required this.services,
    this.initialLocation,
  });
  final AtlasServices services;
  final String? initialLocation;
  @override
  State<WorldAtlasApp> createState() => _WorldAtlasAppState();
}

class _WorldAtlasAppState extends State<WorldAtlasApp>
    with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  late final GoRouter router = GoRouter(
    navigatorKey: navigator,
    initialLocation: widget.initialLocation,
    redirect: (context, state) {
      if (state.uri.path == '/') {
        return widget.services.preferences.onboarded ? '/discover' : '/welcome';
      }
      return null;
    },
    errorBuilder: (context, state) => AtlasPage(
      title: '继续探索',
      child: AtlasEmpty(
        title: '没有找到这个页面',
        message: '从国家百科重新出发吧。',
        action: '打开百科',
        onAction: () => context.go('/encyclopedia'),
      ),
    ),
    routes: [
      GoRoute(
        path: '/regions/antarctica',
        builder: (_, _) => const AntarcticaScreen(),
      ),
      GoRoute(
        path: '/regions/antarctica/map',
        builder: (_, s) => AntarcticaScreen(
          page: 'map',
          id: s.uri.queryParameters['place'],
          mapView: s.uri.queryParameters['view'],
        ),
      ),
      GoRoute(
        path: '/regions/antarctica/contents',
        builder: (_, _) => const AntarcticaScreen(page: 'contents'),
      ),
      GoRoute(
        path: '/regions/antarctica/sections/:section',
        builder: (_, s) =>
            AntarcticaScreen(page: 'section', id: s.pathParameters['section']),
      ),
      GoRoute(
        path: '/regions/antarctica/timeline',
        builder: (_, _) => const AntarcticaScreen(page: 'timeline'),
      ),
      GoRoute(
        path: '/regions/antarctica/explore',
        builder: (_, _) => const AntarcticaScreen(page: 'explore'),
      ),
      GoRoute(
        path: '/regions/antarctica/journeys/:journey',
        builder: (_, s) =>
            AntarcticaScreen(page: 'journey', id: s.pathParameters['journey']),
      ),
      GoRoute(
        path: '/regions/antarctica/observe/:entity',
        builder: (_, s) => AntarcticaScreen(
          page: 'observe',
          id:
              widget.services.content
                  .region('antarctica')!
                  .observations
                  .where((o) => o['id'] == s.pathParameters['entity'])
                  .firstOrNull?['articleId'] ??
              s.pathParameters['entity'],
        ),
      ),
      GoRoute(
        path: '/regions/antarctica/tasks/:task',
        builder: (_, s) =>
            AntarcticaScreen(page: 'task', id: s.pathParameters['task']),
      ),
      GoRoute(
        path: '/me/regions/antarctica',
        builder: (_, _) => const AntarcticaScreen(page: 'discoveries'),
      ),

      GoRoute(
        path: '/preview/zaf',
        builder: (_, s) =>
            SouthAfricaPreview(page: s.uri.queryParameters['page'] ?? 'home'),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AtlasShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
          GoRoute(
            path: '/atlas',
            builder: (_, s) => AtlasScreen(
              countryId: s.uri.queryParameters['country'],
              placeId: s.uri.queryParameters['place'],
              layer: s.uri.queryParameters['layer'],
              featureId: s.uri.queryParameters['feature'],
              region:
                  s.uri.queryParameters['region'] ??
                  s.uri.queryParameters['part'],
            ),
          ),
          GoRoute(
            path: '/encyclopedia',
            builder: (_, _) => const EncyclopediaScreen(),
          ),
          GoRoute(path: '/me', builder: (_, _) => const JournalScreen()),
        ],
      ),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/countries/:id',
        redirect: (_, s) =>
            s.pathParameters['id'] == 'twn' ? '/countries/china' : null,
        builder: (_, s) =>
            widget.services.content
                    .country(s.pathParameters['id']!)
                    ?.editorial
                    .isNotEmpty ==
                true
            ? CountryExperienceScreen(s.pathParameters['id']!)
            : CountryScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/countries/:id/sections/:sectionId',
        builder: (_, s) =>
            widget.services.content
                    .country(s.pathParameters['id']!)
                    ?.editorial
                    .isNotEmpty ==
                true
            ? EditorialSectionScreen(
                countryId: s.pathParameters['id']!,
                sectionId: s.pathParameters['sectionId']!,
              )
            : CountrySectionScreen(
                countryId: s.pathParameters['id']!,
                sectionId: s.pathParameters['sectionId']!,
              ),
      ),
      GoRoute(
        path: '/countries/:id/contents',
        builder: (_, s) => CountryContentsScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/countries/:id/journeys/:journeyId',
        builder: (_, s) => CountryJourneyScreen(
          countryId: s.pathParameters['id']!,
          journeyId: s.pathParameters['journeyId']!,
        ),
      ),
      GoRoute(
        path: '/countries/:id/timeline',
        builder: (_, s) => CountryTimelineScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/countries/:id/explore',
        builder: (_, s) => CountryExploreScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/countries/:id/observe/:articleId',
        builder: (_, s) =>
            CountryObservationScreen(s.pathParameters['articleId']!),
      ),
      GoRoute(
        path: '/countries/:id/observe/place/:placeId',
        builder: (_, s) => CountryObservationScreen.place(
          s.pathParameters['placeId']!,
          mediaId: s.uri.queryParameters['media'],
        ),
      ),
      GoRoute(
        path: '/me/countries/:id',
        builder: (_, s) => CountryDiscoveriesScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/articles/:id',
        builder: (_, s) => ReaderScreen(
          s.pathParameters['id']!,
          block: s.uri.queryParameters['block'],
        ),
      ),
      GoRoute(
        path: '/places/:id',
        builder: (_, s) =>
            widget.services.content.place(s.pathParameters['id']!)?.regionId ==
                'antarctica'
            ? AntarcticaScreen(page: 'place', id: s.pathParameters['id'])
            : PlaceScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/places/:id/gallery',
        builder: (_, s) => GalleryScreen(
          id: s.pathParameters['id']!,
          initial: int.tryParse(s.uri.queryParameters['image'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/topics', builder: (_, _) => const TopicsScreen()),
      GoRoute(
        path: '/topics/:id',
        builder: (_, s) => TopicScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/search',
        builder: (_, s) => SearchScreen(
          query: s.uri.queryParameters['q'] ?? '',
          type: s.uri.queryParameters['type'] ?? '全部',
        ),
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (_, s) =>
            widget.services.content
                    .exercise(s.pathParameters['id']!)
                    ?.regionId ==
                'antarctica'
            ? AntarcticaScreen(page: 'task', id: s.pathParameters['id'])
            : ExerciseScreen(s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/me/bookmarks',
        builder: (_, _) => const JournalListScreen('bookmarks'),
      ),
      GoRoute(
        path: '/me/history',
        builder: (_, _) => const JournalListScreen('history'),
      ),
      GoRoute(
        path: '/me/notes',
        builder: (_, _) => const JournalListScreen('notes'),
      ),
      GoRoute(
        path: '/me/notes/new',
        builder: (_, s) => NoteEditorScreen(
          entityId: s.uri.queryParameters['entity'] ?? '',
          kind: s.uri.queryParameters['kind'] ?? 'article',
        ),
      ),
      GoRoute(
        path: '/me/notes/:id/edit',
        builder: (_, s) => NoteEditorScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings/reading',
        builder: (_, _) => const ReadingSettingsScreen(),
      ),
      GoRoute(
        path: '/parent-gate',
        builder: (_, _) => const ParentGateScreen(),
      ),
      GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
      GoRoute(path: '/packs', builder: (_, _) => const PacksScreen()),
      GoRoute(
        path: '/packs/:id',
        builder: (_, s) => PackDetailScreen(s.pathParameters['id']!),
      ),
      GoRoute(path: '/parent/backup', builder: (_, _) => const BackupScreen()),
      GoRoute(
        path: '/credits',
        builder: (_, s) =>
            CreditsScreen(entity: s.uri.queryParameters['entity']),
      ),
      GoRoute(path: '/rest', builder: (_, _) => const RestScreen()),
    ],
  );
  Timer? timer;
  int activeSeconds = 0;
  bool foreground = true, showing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!foreground || showing || !widget.services.preferences.breakEnabled) {
        return;
      }
      activeSeconds += 10;
      if (activeSeconds >= widget.services.preferences.breakMinutes * 60) {
        activeSeconds = 0;
        showing = true;
        router.push('/rest').whenComplete(() => showing = false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) unawaited(widget.services.speech.pause());
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AtlasScope(
    services: widget.services,
    child: MaterialApp.router(
      title: '世界大百科',
      debugShowCheckedModeBanner: false,
      theme: atlasTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}

class AtlasShell extends StatelessWidget {
  const AtlasShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  static const destinations = [
    ('/discover', '发现', Icons.explore_outlined, Icons.explore),
    ('/atlas', '地图', Icons.map_outlined, Icons.map),
    ('/encyclopedia', '百科', Icons.menu_book_outlined, Icons.menu_book),
    ('/me', '我的', Icons.person_outline_rounded, Icons.person),
  ];
  @override
  Widget build(BuildContext context) {
    final index = destinations.indexWhere((d) => d.$1 == location).clamp(0, 3);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        Widget destination(int i) => InkWell(
          onTap: () => context.go(destinations[i].$1),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i == index ? destinations[i].$4 : destinations[i].$3,
                  size: 27,
                  color: wide && i == index
                      ? Colors.white
                      : i == index
                      ? AtlasPalette.navy
                      : AtlasPalette.muted,
                ),
                const SizedBox(height: 4),
                Text(
                  destinations[i].$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                    color: wide && i == index
                        ? Colors.white
                        : i == index
                        ? AtlasPalette.navy
                        : AtlasPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        );
        return Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              if (wide)
                SafeArea(
                  child: Container(
                    width: 110,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: AtlasPalette.line),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Image.asset(
                            'assets/images/world-atlas-logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            semanticLabel: '世界大百科',
                          ),
                        ),
                        for (var i = 0; i < destinations.length; i++)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                            child: Material(
                              color: i == index
                                  ? AtlasPalette.navy
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(width: 90, child: destination(i)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AtlasPalette.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Expanded(
                            child: Semantics(
                              selected: i == index,
                              button: true,
                              label: destinations[i].$2,
                              child: destination(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
