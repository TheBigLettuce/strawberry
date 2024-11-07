import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:go_router/go_router.dart";
import "package:strawberry/src/pages/home.dart";
import "package:strawberry/src/platform/platform.dart";

void main() {
  final eventsImpl = PlaybackEventsImpl();

  PlaybackEvents.setUp(eventsImpl);
  Queue.setUp(eventsImpl.queue);

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
  );
}
