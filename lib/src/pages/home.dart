import "dart:async";

import "package:flutter/material.dart";
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

    tabController = TabController(length: 4, vsync: this);
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) {
                final isPlaying = PlayerStateQuery.isPlayingOf(context);
                final player = Player.of(context);

                return IconButton.filledTonal(
                  onPressed: () {
                    player.flipIsPlaying(context);
                  },
                  isSelected: isPlaying,
                  icon: Icon(Icons.play_arrow),
                );
              },
            ),
            Builder(
              builder: (context) {
                final isLooping = PlayerStateQuery.loopingOf(context);
                final player = Player.of(context);

                return IconButton.filledTonal(
                  onPressed: () {
                    player.flipIsLooping(context);
                  },
                  isSelected: isLooping,
                  icon: Icon(Icons.loop_outlined),
                );
              },
            ),
            // IconButton(onPressed: () {}, icon: Icon(Icons.)),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          tabs: [
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
            Tab(
              text: "Queue",
              icon: Icon(Icons.list_alt_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          Builder(
            builder: (context) {
              final albums = AlbumsBucket.of(context);

              return ListView.builder(
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];

                  return ListTile(
                    trailing: CircleAvatar(
                      foregroundImage:
                          PlatformThumbnailProvider.album(album.albumId),
                    ),
                    title: Text(album.album),
                    subtitle: Text(album.numberOfSongs.toString()),
                    // onTap: () {
                    // QueueList.clearAndPlayOf(context, track);
                    // },
                  );
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final tracks = TracksBucket.of(context);

              return ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];

                  return ListTile(
                    trailing: CircleAvatar(
                      foregroundImage:
                          PlatformThumbnailProvider.album(track.albumId),
                    ),
                    title: Text(track.name),
                    subtitle: Text(track.artist),
                    onTap: () {
                      QueueList.clearAndPlayOf(context, track);
                    },
                  );
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final artists = ArtistsBucket.of(context);

              return ListView.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];

                  return ListTile(
                    // trailing: CircleAvatar(
                    //   foregroundImage:
                    //       PlatformThumbnailProvider.album(track.albumId),
                    // ),
                    title: Text(artist.artist),
                    subtitle: Text(artist.numberOfAlbums.toString()),
                    // onTap: () {
                    // QueueList.clearAndPlayOf(context, track);
                    // },
                  );
                },
              );
            },
          ),
          Builder(
            builder: (context) {
              final queue = QueueList.of(context);

              return ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final track = queue[index];
                  final current = queue.current();

                  return ListTile(
                    leading: current != null && current.id == track.id
                        ? Builder(
                            builder: (context) {
                              final progress =
                                  PlayerStateQuery.progressOf(context)
                                      .inMilliseconds;

                              return CircularProgressIndicator(
                                year2023: false,
                                constraints: BoxConstraints.tightFor(
                                  width: 20,
                                  height: 20,
                                ),
                                value: progress <= 0 || track.duration <= 0
                                    ? 0
                                    : progress / track.duration,
                              );
                            },
                          )
                        : null,
                    trailing: CircleAvatar(
                      foregroundImage:
                          PlatformThumbnailProvider.album(track.albumId),
                    ),
                    title: Text(track.name),
                    subtitle: Text(track.album),
                    onTap: () {
                      Player.of(context).flipIsPlaying(context);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
