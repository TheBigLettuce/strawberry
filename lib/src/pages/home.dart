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

import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/pages/artist_albums.dart";
import "package:strawberry/src/pages/queue.dart";
import "package:strawberry/src/pages/search_page.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:strawberry/src/platform/platform_thumbnail.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<void> _watcher;
  late final TabController tabController;

  late PlayerManager playerManager;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _watcher.cancel();
    tabController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    playerManager = PlayerManager.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: DarkTheme(
        child: BottomBar(
          realBrightness: theme.colorScheme.brightness,
          realSurfaceColor: theme.colorScheme.surface,
          bottomPadding: MediaQuery.viewPaddingOf(context).bottom,
        ),
      ),
      extendBody: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                floating: true,
                leading: const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.settings_outlined),
                ),
                clipBehavior: Clip.antiAlias,
                title: GestureDetector(
                  onTap: () {
                    SearchPage.go(context);
                  },
                  child: const AbsorbPointer(
                    child: Hero(
                      tag: "SearchAnchor",
                      child: SizedBox(
                        height: 40,
                        child: SearchBar(
                          elevation: WidgetStatePropertyAll(0),
                          leading: Icon(Icons.search_outlined),
                          hintText: "Search for tracks, albums...",
                        ),
                      ),
                    ),
                  ),
                ),
                forceElevated: innerBoxIsScrolled,
                actions: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () {
                          QueueModalPage.go(context);
                        },
                        icon: const Icon(Icons.list_alt_outlined),
                      );
                    },
                  ),
                ],
                shape: !innerBoxIsScrolled
                    ? null
                    : const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                bottom: TabBar(
                  dividerHeight: !innerBoxIsScrolled ? null : 0,
                  indicator: !innerBoxIsScrolled ? null : const BoxDecoration(),
                  indicatorSize: TabBarIndicatorSize.tab,
                  controller: tabController,
                  tabs: const [
                    Tab(
                      text: "Albums",
                      icon: Icon(Icons.album_outlined),
                    ),
                    Tab(
                      text: "Tracks",
                      icon: Icon(Icons.library_music_outlined),
                    ),
                    Tab(
                      text: "Artists",
                      icon: Icon(Icons.people_outline_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: tabController,
          children: const [
            DarkTheme(child: AlbumsTabBody()),
            TracksTabBody(),
            ArtistsTabBody(),
          ],
        ),
      ),
    );
  }
}

class BottomBar extends StatefulWidget {
  const BottomBar({
    super.key,
    required this.bottomPadding,
    required this.realSurfaceColor,
    required this.realBrightness,
  });

  final double bottomPadding;
  final Color realSurfaceColor;
  final Brightness realBrightness;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  final pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final queue = QueueList.of(context);

    final trackId = queue.currentTrackIdx();
    if (!pageController.hasClients && trackId != 0) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        pageController.jumpToPage(trackId);
      });
    } else if (pageController.hasClients && pageController.page != trackId) {
      pageController.animateToPage(
        trackId,
        duration: Durations.long4,
        curve: Easing.emphasizedDecelerate,
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = QueueList.of(context);

    final currentTrack = queue.currentTrack;

    const radius = Radius.circular(20);

    return AnnotatedRegion(
      value: currentTrack != null
          ? SystemUiOverlayStyle(
              systemNavigationBarColor: theme.colorScheme.surface.withValues(
                alpha: 0,
              ),
            )
          : SystemUiOverlayStyle(
              systemNavigationBarIconBrightness:
                  widget.realBrightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
              systemNavigationBarColor: widget.realSurfaceColor,
            ),
      child: AnimatedSlide(
        offset: Offset(0, currentTrack == null ? 1 : 0),
        duration: Durations.long3,
        curve: Easing.standard,
        child: currentTrack == null
            ? SizedBox(
                width: double.infinity,
                height: widget.bottomPadding,
              )
            : ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                ),
                child: SizedBox(
                  height: 68 + widget.bottomPadding,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 1.8,
                          sigmaY: 1.8,
                          tileMode: TileMode.clamp,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.48),
                                BlendMode.darken,
                              ),
                              // opacity: 0.8,
                              alignment: Alignment.topCenter,
                              image: PlatformThumbnailProvider.album(
                                currentTrack.albumId,
                                theme.brightness,
                              ),
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: TrackPlaybackProgress(
                          track: currentTrack,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      if (widget.bottomPadding != 0)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.5),
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.05),
                                  Colors.black.withValues(alpha: 0),
                                ],
                              ),
                            ),
                            child: SizedBox(
                              height: widget.bottomPadding + 8,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ) +
                            EdgeInsets.only(
                              bottom: widget.bottomPadding,
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (context) {
                                final isLooping =
                                    PlayerStateQuery.loopingOf(context);
                                final player = Player.of(context);

                                return IconButton(
                                  onPressed: () {
                                    player.flipIsLooping(context);
                                  },
                                  isSelected: isLooping,
                                  icon: const Icon(Icons.loop_outlined),
                                );
                              },
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(15),
                                ),
                                onTap: () {
                                  QueueModalPage.go(context);
                                },
                                child: IgnorePointer(
                                  child: PageView.builder(
                                    controller: pageController,
                                    // allowImplicitScrolling: ,
                                    // onPageChanged: (value) {
                                    //   // queue.setAt(value);
                                    // },
                                    itemCount: queue.length,
                                    itemBuilder: (context, index) {
                                      final track = queue[index];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              track.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              track.artist,
                                              maxLines: 1,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const PlayButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class DarkTheme extends StatelessWidget {
  const DarkTheme({
    // super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.colorScheme.primary,
          brightness: Brightness.dark,
        ),
      ),
      child: child,
    );
  }
}

class PlayButton extends StatefulWidget {
  const PlayButton({super.key});

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: Durations.long3,
      reverseDuration: Durations.long1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newIsPlaying = PlayerStateQuery.isPlayingOf(context);
    if (newIsPlaying != isPlaying) {
      isPlaying = newIsPlaying;

      if (isPlaying) {
        controller.animateTo(1, curve: Easing.emphasizedDecelerate);
      } else {
        controller.animateBack(0, curve: Easing.emphasizedAccelerate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final isPlaying = PlayerStateQuery.isPlayingOf(context);
        final player = Player.of(context);

        return IconButton.filledTonal(
          onPressed: () {
            player.flipIsPlaying(context);
          },
          style: const ButtonStyle(
            shape: WidgetStateOutlinedBorder.fromMap({
              WidgetState.selected: CircleBorder(),
              WidgetState.any: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            }),
          ),
          isSelected: isPlaying,
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: controller.view,
          ),
        );
      },
    );
  }
}

class ArtistsTabBody extends StatelessWidget {
  const ArtistsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final artists = ArtistsBucket.of(context);

    return CustomScrollView(
      key: const PageStorageKey("Artists"),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            context,
          ),
        ),
        SliverList.builder(
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];

            return ListTile(
              title: Text(artist.artist),
              subtitle: Text(
                "${artist.numberOfAlbums} albums · ${artist.numberOfTracks} tracks",
              ),
              onTap: () => ArtistAlbumsPage.go(context, artist.id),
            );
          },
        ),
        const _BottomBarPadding(),
      ],
    );
  }
}

class TracksTabBody extends StatelessWidget {
  const TracksTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final tracks = TracksBucket.of(context);

    return CustomScrollView(
      key: const PageStorageKey("Tracks"),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
            context,
          ),
        ),
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final queue = QueueList.of(context);

            final track = tracks[index];
            final isCurrent = queue.currentTrack?.id == track.id;

            return Column(
              children: [
                ListTile(
                  trailing: CircleAvatar(
                    foregroundImage: PlatformThumbnailProvider.album(
                      track.albumId,
                      Theme.of(context).brightness,
                    ),
                  ),
                  title: Text(track.name),
                  subtitle: Text("${track.artist} · ${track.album}"),
                  onTap: () {
                    QueueList.addOf(context, track);
                  },
                ),
                if (isCurrent)
                  TrackPlaybackProgress(track: track)
                else
                  const SizedBox(height: 2),
              ],
            );
          },
        ),
        const _BottomBarPadding(),
      ],
    );
  }
}

class AlbumsTabBody extends StatelessWidget {
  const AlbumsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final albums = AlbumsBucket.of(context);

    return Padding(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        key: const PageStorageKey("Albums"),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
              context,
            ),
            // sliver:,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              // padding: EdgeInsets.symmetric(
              //     vertical: 8, horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];

                return AlbumCard(album: album);
              },
            ),
          ),
          const _BottomBarPadding(),
        ],
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.pushRoute = false,
  });

  final Album album;

  final bool pushRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          onTap: () {
            AlbumTracksPage.go(context, album, pushRoute);
          },
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceBright.withValues(alpha: 0.5),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Center(
                  child: SizedBox.expand(
                    child: Hero(
                      tag: album.id,
                      child: Image(
                        frameBuilder: (
                          context,
                          child,
                          frame,
                          wasSynchronouslyLoaded,
                        ) {
                          if (wasSynchronouslyLoaded) {
                            return child;
                          }

                          return frame == null
                              ? const SizedBox.shrink()
                              : child.animate().fadeIn();
                        },
                        alignment: Alignment.topCenter,
                        fit: BoxFit.cover,
                        image: PlatformThumbnailProvider.album(
                          album.albumId,
                          theme.brightness,
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                        theme.colorScheme.surface.withValues(alpha: 0.6),
                        theme.colorScheme.surface.withValues(alpha: 0.4),
                        theme.colorScheme.surface.withValues(alpha: 0.2),
                        theme.colorScheme.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight * 0.5,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ) +
                          const EdgeInsets.only(bottom: 4),
                      child: Text(
                        album.album,
                        maxLines: 2,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ) +
                          const EdgeInsets.only(bottom: 8),
                      child: Text.rich(
                        TextSpan(
                          text: album.artist,
                          children: [
                            TextSpan(text: " · ${album.formatYears()}"),
                          ],
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomBarPadding extends StatelessWidget {
  const _BottomBarPadding({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
    );
  }
}
