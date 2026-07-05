import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/push/push_service.dart';
import 'core/storage/token_store.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional — the app runs fine without a Firebase project.
  await PushService.init();

  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  await tokens.load();

  runApp(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
    ],
    child: const GyanHubApp(),
  ));
}

class GyanHubApp extends StatefulWidget {
  const GyanHubApp({super.key});

  @override
  State<GyanHubApp> createState() => _GyanHubAppState();
}

class _GyanHubAppState extends State<GyanHubApp> {
  late final router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gyan Hub',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
