import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/explorer_store.dart';
import 'core/palette.dart';
import 'models/catalog.dart';
import 'screens/world_screens.dart';
import 'screens/passport_screens.dart';
import 'widgets/atlas_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});
  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<ExplorerStore> loading = _load();
  Future<ExplorerStore> _load() async {
    final store = ExplorerStore(
      catalog: await Catalog.load(),
      storage: LocalProgressStorage(),
    );
    await store.load();
    return store;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ExplorerStore>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return WorldExplorerApp(store: snapshot.data!);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAtlasTheme(),
        home: Scaffold(
          body: snapshot.hasError
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: '探索手册暂时没有打开',
                  message: '请重试。如果问题仍在，请重新启动应用。',
                  action: FilledButton(
                    onPressed: () => setState(() => loading = _load()),
                    child: const Text('重新打开'),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 56,
                        color: AtlasColors.forest,
                      ),
                      SizedBox(height: 20),
                      Text('正在打开世界探索手册…'),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}

class WorldExplorerApp extends StatefulWidget {
  const WorldExplorerApp({super.key, required this.store});
  final ExplorerStore store;
  @override
  State<WorldExplorerApp> createState() => _WorldExplorerAppState();
}

class _WorldExplorerAppState extends State<WorldExplorerApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  Timer? timer;
  bool reminderOpen = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkBreak());
  }

  Future<void> _checkBreak() async {
    if (!mounted ||
        !widget.store.onboarded ||
        !widget.store.breakDue ||
        reminderOpen) {
      return;
    }
    final context = navigatorKey.currentContext;
    if (context == null) return;
    reminderOpen = true;
    final takeBreak = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.park_outlined,
          color: AtlasColors.forest,
          size: 40,
        ),
        title: const Text('给好奇心一个小休息'),
        content: Text('你已经探索了约 ${widget.store.breakMinutes} 分钟。站起来走走，看看窗外吧。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后休息'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('休息一下'),
          ),
        ],
      ),
    );
    widget.store.restartSession();
    reminderOpen = false;
    if (takeBreak == true && mounted && navigatorKey.currentContext != null) {
      openScreen(navigatorKey.currentContext!, const RestScreen());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExplorerScope(
    store: widget.store,
    child: AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: '世界小探险家',
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAtlasTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.store.textScale)),
          child: child!,
        ),
        home: widget.store.onboarded
            ? const HomeShell()
            : const WelcomeScreen(),
      ),
    ),
  );
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ExplorerScope.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AtlasColors.background,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AtlasColors.forest,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                '世界小探险家',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => openScreen(context, const ParentGateScreen()),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('家长'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (store.storageError != null)
              MaterialBanner(
                content: Text(store.storageError!),
                actions: [
                  TextButton(
                    onPressed: store.retrySave,
                    child: const Text('重试保存'),
                  ),
                ],
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: IndexedStack(
                    index: store.activeTab,
                    children: const [
                      WorldHome(),
                      DiscoverScreen(),
                      PassportScreen(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: AtlasColors.background,
        indicatorColor: AtlasColors.mint,
        selectedIndex: store.activeTab,
        onDestinationSelected: store.setTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: '世界',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: '护照',
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '世界小探险家',
    showBack: false,
    actions: [
      TextButton.icon(
        onPressed: () => openScreen(context, const ParentGateScreen()),
        icon: const Icon(Icons.lock_outline, size: 18),
        label: const Text('家长'),
      ),
    ],
    child: LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(c.maxWidth > 700 ? 40 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AtlasTag(
                '写给每一个好奇的孩子',
                color: AtlasColors.sand,
                icon: Icons.auto_awesome_outlined,
              ),
              const SizedBox(height: 28),
              if (c.maxWidth > 800)
                Row(
                  children: [
                    Expanded(child: _welcomeText(context)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: const Illustration(
                        asset: 'assets/images/welcome-world.png',
                        height: 390,
                      ),
                    ),
                  ],
                )
              else ...[
                _welcomeText(context),
                const SizedBox(height: 28),
                const Illustration(
                  asset: 'assets/images/welcome-world.png',
                  height: 230,
                ),
              ],
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  AtlasTag('看见世界', icon: Icons.public),
                  AtlasTag('听懂故事', icon: Icons.headphones_outlined),
                  AtlasTag('带走发现', icon: Icons.lightbulb_outline),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '无需登录 · 国家内容随应用提供 · 探索记录保存在本机',
                style: TextStyle(fontSize: 13, color: AtlasColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _welcomeText(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '出发，\n去看世界！',
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(fontSize: 46, height: 1.3),
      ),
      const SizedBox(height: 20),
      const Text(
        '每一次好奇，\n都是一段新旅行。',
        style: TextStyle(fontSize: 21, color: AtlasColors.muted, height: 1.8),
      ),
      const SizedBox(height: 28),
      FilledButton.icon(
        key: const ValueKey('welcome-start'),
        onPressed: () => openScreen(context, const ProfileScreen()),
        icon: const Icon(Icons.arrow_forward),
        label: const Text('开始探索'),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => ExplorerScope.of(context).finishOnboarding(),
        child: const Text('先看看世界 →'),
      ),
    ],
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController(text: '小小探险家');
  String avatar = '🦊';
  bool prefersVoice = true, busy = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExplorerPage(
    title: '我的探险名片',
    subtitle: '取个喜欢的名字，就可以出发',
    actions: [
      TextButton(
        onPressed: () => _finish(context, skip: true),
        child: const Text('跳过'),
      ),
    ],
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: AtlasCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择一位旅行伙伴',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: ['🦊', '🐼', '🐬', '🦉']
                        .map(
                          (emoji) => Semantics(
                            label: '选择头像 $emoji',
                            selected: avatar == emoji,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => setState(() => avatar = emoji),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: avatar == emoji
                                      ? AtlasColors.mint
                                      : AtlasColors.background,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: avatar == emoji
                                        ? AtlasColors.forest
                                        : AtlasColors.line,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const ValueKey('nickname-field'),
                    controller: name,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      labelText: '探险昵称',
                      helperText: '可以使用喜欢的昵称，不需要真实姓名',
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: prefersVoice,
                    onChanged: (v) => setState(() => prefersVoice = v ?? true),
                    title: const Text('我喜欢听故事'),
                    subtitle: const Text('使用设备的中文语音，以后可以修改'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => _finish(context),
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(busy ? '正在准备…' : '完成，出发探索'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> _finish(BuildContext context, {bool skip = false}) async {
    if (busy) return;
    setState(() => busy = true);
    final store = ExplorerScope.of(context);
    if (skip) {
      await store.finishOnboarding();
    } else {
      await store.saveProfile(
        name: name.text,
        selectedAvatar: avatar,
        prefersVoice: prefersVoice,
      );
    }
    if (context.mounted) goHome(context);
  }
}
