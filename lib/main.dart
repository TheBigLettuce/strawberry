import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:go_router/go_router.dart";
import "package:strawberry/src/pages/home.dart";
import "package:strawberry/src/platform/generated/platform_api.g.dart";
import "package:strawberry/src/platform/platform.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stateManager = createStateManager();

  final restoredData = await DataLoader().restore();
  stateManager.restore(restoredData);

  stateManager.playerManager.data.notifyAlbums();
  stateManager.playerManager.data.notifyArtists();
  stateManager.playerManager.data.notifyTracks();

  ThemeData buildTheme(Brightness brightness, Color accentColor) {
    return ThemeData.from(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: accentColor,
      ),
    ).copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }

  final routes = GoRouter(
    routes: [
      GoRoute(
        name: "Home",
        path: "/",
        builder: (context, state) => const HomePage(),
      ),
    ],
  );

  runApp(
    stateManager.inject(
      MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
        themeAnimationCurve: Easing.standard,
        themeAnimationDuration: const Duration(milliseconds: 300),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildTheme(Brightness.light, Colors.purpleAccent),
        darkTheme: buildTheme(Brightness.dark, Colors.purpleAccent),
        routerConfig: routes,
      ),
    ),
  );
}
