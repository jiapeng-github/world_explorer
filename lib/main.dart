import 'package:flutter/material.dart';

import 'app/atlas_app.dart';
import 'app/services.dart';
import 'design/atlas_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtlasBootstrap());
}

class AtlasBootstrap extends StatefulWidget {
  const AtlasBootstrap({super.key, this.loadServices});
  final Future<AtlasServices> Function()? loadServices;
  @override
  State<AtlasBootstrap> createState() => _AtlasBootstrapState();
}

class _AtlasBootstrapState extends State<AtlasBootstrap> {
  late final String initialLocation =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  late Future<AtlasServices> future =
      (widget.loadServices ?? AtlasServices.load)();
  @override
  Widget build(BuildContext context) => FutureBuilder<AtlasServices>(
    future: future,
    builder: (context, snapshot) {
      // Resolve the original deep link before the temporary loading navigator
      // reports its own root route to the web platform.
      final location = initialLocation;
      if (snapshot.hasData) {
        return WorldAtlasApp(
          services: snapshot.data!,
          initialLocation: location,
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: atlasTheme(),
        builder: (context, child) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 70, color: AtlasPalette.navy),
                  const SizedBox(height: 22),
                  const Text(
                    '世界大百科',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.hasError) ...[
                    const Text(
                      '本机内容暂时没有载入成功，请重试。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(
                        () => future =
                            (widget.loadServices ?? AtlasServices.load)(),
                      ),
                      child: const Text('重新载入'),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '正在打开世界图鉴…',
                      style: TextStyle(color: AtlasPalette.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
