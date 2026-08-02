import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

class EcoSyncApp extends StatelessWidget {
  const EcoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider()..init(),
      child: const _EcoSyncMaterialApp(),
    );
  }
}

/// Split out so `context.watch` here only rebuilds the MaterialApp (and
/// therefore its ThemeData) when the user changes the theme colour in
/// Settings, without needing the provider created in the same build call.
class _EcoSyncMaterialApp extends StatelessWidget {
  const _EcoSyncMaterialApp();

  @override
  Widget build(BuildContext context) {
    final seed = context.watch<AppStateProvider>().themeSeed;
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: seed,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
