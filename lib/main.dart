/*
  Strawberry, a music player
  Copyright (C) 2024  Bob

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";
import "package:strawberry/l10n/generated/app_localizations.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/pages/artist_albums.dart";
import "package:strawberry/src/pages/home.dart";
import "package:strawberry/src/pages/queue.dart";
import "package:strawberry/src/pages/search_page.dart";
import "package:strawberry/src/platform/generated/platform_api.g.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:strawberry/theme.dart";

late final Uint8List placeholder_light;
late final Uint8List placeholder_dark;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final stateManager = createStateManager();

  final restoredData = await DataLoader().restore();
  stateManager.restore(restoredData);

  final refresh = await _requestPermissions();
  if (refresh) {
    stateManager.playerManager.data.notifyAlbums();
    stateManager.playerManager.data.notifyArtists();
    stateManager.playerManager.data.notifyTracks();
  }

  placeholder_light = Uint8List.sublistView(
    await rootBundle.load("assets/strawberry_placeholder_light.png"),
  );
  placeholder_dark = Uint8List.sublistView(
    await rootBundle.load("assets/strawberry_placeholder_dark.png"),
  );

  ThemeData buildTheme(Brightness brightness) {
    final colorScheme = switch (brightness) {
      Brightness.dark => MaterialTheme.darkScheme(),
      Brightness.light => MaterialTheme.lightScheme(),
    };

    return ThemeData.from(
      useMaterial3: true,
      colorScheme: colorScheme,
    ).copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
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
        routes: [
          GoRoute(
            path: "search",
            name: "Search",
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: "artist_albums",
            name: "ArtistAlbums",
            onExit: (context, state) {
              (state.extra! as CombinedLiveTracksBucket).dispose();
              return true;
            },
            pageBuilder: (context, state) {
              final liveAlbums = state.extra! as CombinedLiveTracksBucket;

              return BottomSheetPage(
                key: ValueKey(state.matchedLocation),
                child: liveAlbums.inject(
                  const ArtistAlbumsPage(),
                ),
              );
            },
          ),
          GoRoute(
            path: "queue",
            name: "QueueModal",
            pageBuilder: (context, state) => const BottomSheetPage(
              child: QueueModalPage(),
            ),
          ),
          GoRoute(
            path: "album_tracks",
            name: "AlbumTracks",
            onExit: (context, state) {
              (state.extra! as LiveTracksBucket).dispose();
              return true;
            },
            pageBuilder: (context, state) {
              final liveTracks = state.extra! as LiveTracksBucket;

              return BottomSheetPage(
                key: ValueKey(state.matchedLocation),
                child: liveTracks.inject(
                  const AlbumTracksPage(),
                ),
              );
            },
          ),
        ],
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
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        routerConfig: routes,
      ),
    ),
  );
}

Future<bool> _requestPermissions() async {
  final audio = await Permission.audio.status;
  if (!audio.isGranted) {
    final resp = await Permission.audio.request();
    if (!resp.isGranted) {
      return false;
    }
  }
  await Permission.photos.request();
  await Permission.notification.request();

  return true;
}

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
        isScrollControlled: true,
        showDragHandle: true,
        settings: this,
        useSafeArea: true,
        clipBehavior: Clip.antiAlias,
        builder: (context) => DraggableScrollableSheet(
          maxChildSize: 0.8,
          expand: false,
          snap: true,
          snapSizes: const [
            0.5,
            0.8,
          ],
          builder: (context, scrollController) => PrimaryScrollController(
            controller: scrollController,
            child: child,
          ),
        ),
      );
}
