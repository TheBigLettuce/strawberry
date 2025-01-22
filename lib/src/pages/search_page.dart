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

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:strawberry/l10n/generated/app_localizations.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/pages/artist_albums.dart";
import "package:strawberry/src/pages/home.dart";
import "package:strawberry/src/platform/platform.dart";

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
  });

  static void go(BuildContext context) {
    context.goNamed("Search");
  }

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final focusNode = FocusNode();
  late final StreamController<String> filteringStream =
      StreamController.broadcast();

  @override
  void dispose() {
    focusNode.dispose();
    filteringStream.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.zero,
        automaticallyImplyLeading: false,
        title: Hero(
          tag: "SearchAnchor",
          child: SizedBox(
            height: 40,
            child: SearchBar(
              focusNode: focusNode,
              onChanged: filteringStream.add,
              onSubmitted: filteringStream.add,
              onTapOutside: (event) => focusNode.unfocus(),
              elevation: const WidgetStatePropertyAll(0),
              leading: IconButton(
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back),
              ),
              hintText: l10n.searchHint,
            ),
          ),
        ),
      ),
      body: _SearchPageBody(filteringStream: filteringStream),
    );
  }
}

class _SearchPageBody extends StatefulWidget {
  const _SearchPageBody({
    // super.key,
    required this.filteringStream,
  });

  final StreamController<String> filteringStream;

  @override
  State<_SearchPageBody> createState() => __SearchPageBodyState();
}

class __SearchPageBodyState extends State<_SearchPageBody> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _ArtistsBody(
          filteringEvents: widget.filteringStream.stream,
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
        _AlbumsBody(
          filteringEvents: widget.filteringStream.stream,
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
        _TracksBody(
          filteringEvents: widget.filteringStream.stream,
        ),
        Builder(
          builder: (context) => SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlbumsBody extends StatefulWidget {
  const _AlbumsBody({
    // super.key,
    required this.filteringEvents,
  });

  final Stream<String> filteringEvents;

  @override
  State<_AlbumsBody> createState() => __AlbumsBodyState();
}

class __AlbumsBodyState extends State<_AlbumsBody> {
  late final StreamSubscription<String> events;
  LiveAlbumsBucket? resultBucket;

  String filteringEvents = "";

  late AlbumsBucket bucket;

  @override
  void initState() {
    super.initState();

    events = widget.filteringEvents.listen((str) {
      setState(() {
        if (str.isEmpty) {
          filteringEvents = "";
          resultBucket?.dispose();
          resultBucket = null;

          return;
        } else if (str == filteringEvents) {
          return;
        }

        resultBucket?.dispose();
        resultBucket = bucket.query(str);
        filteringEvents = str;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bucket = AlbumsBucket.of(context);
  }

  @override
  void dispose() {
    events.cancel();
    resultBucket?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (resultBucket == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return resultBucket!.inject(
      const AlbumsContent(),
    );
  }
}

class AlbumsContent extends StatelessWidget {
  const AlbumsContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final albumsBucket = LiveAlbumsBucket.of(context);

    return SliverToBoxAdapter(
      child: DarkTheme(
        child: AnimatedSize(
          alignment: Alignment.topCenter,
          curve: Easing.standard,
          duration: Durations.medium3,
          reverseDuration: Durations.medium1,
          child: albumsBucket.isEmpty
              ? const SizedBox.shrink()
              : SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    itemCount: albumsBucket.length,
                    itemBuilder: (context, index) {
                      final album = albumsBucket[index];

                      return AlbumCard(
                        album: album,
                        pushRoute: true,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _TracksBody extends StatefulWidget {
  const _TracksBody({
    // super.key,
    required this.filteringEvents,
  });

  final Stream<String> filteringEvents;

  @override
  State<_TracksBody> createState() => __TracksBodyState();
}

class __TracksBodyState extends State<_TracksBody> {
  late final StreamSubscription<String> events;
  LiveTracksBucket? resultBucket;

  String filteringEvents = "";

  late TracksBucket bucket;

  @override
  void initState() {
    super.initState();

    events = widget.filteringEvents.listen((str) {
      setState(() {
        if (str.isEmpty) {
          filteringEvents = "";
          resultBucket?.dispose();
          resultBucket = null;

          return;
        } else if (str == filteringEvents) {
          return;
        }

        resultBucket?.dispose();
        resultBucket = bucket.query(str);
        filteringEvents = str;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bucket = TracksBucket.of(context);
  }

  @override
  void dispose() {
    events.cancel();
    resultBucket?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (resultBucket == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return resultBucket!.inject(
      const TracksContent(),
    );
  }
}

class TracksContent extends StatelessWidget {
  const TracksContent({super.key});

  @override
  Widget build(BuildContext context) {
    final tracksBucket = LiveTracksBucket.of(context);

    return SliverList.builder(
      itemCount: tracksBucket.length,
      itemBuilder: (context, index) {
        final track = tracksBucket[index];

        return TrackTile(track: track);
      },
    );
  }
}

class _ArtistsBody extends StatefulWidget {
  const _ArtistsBody({
    super.key,
    required this.filteringEvents,
  });

  final Stream<String> filteringEvents;

  @override
  State<_ArtistsBody> createState() => __ArtistsBodyState();
}

class __ArtistsBodyState extends State<_ArtistsBody> {
  late final StreamSubscription<String> events;
  LiveArtistsBucket? resultBucket;

  String filteringEvents = "";

  late ArtistsBucket bucket;

  @override
  void initState() {
    super.initState();

    events = widget.filteringEvents.listen((str) {
      setState(() {
        if (str.isEmpty) {
          filteringEvents = "";
          resultBucket?.dispose();
          resultBucket = null;

          return;
        } else if (str == filteringEvents) {
          return;
        }

        resultBucket?.dispose();
        resultBucket = bucket.query(str);
        filteringEvents = str;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    bucket = ArtistsBucket.of(context);
  }

  @override
  void dispose() {
    events.cancel();
    resultBucket?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (resultBucket == null) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return resultBucket!.inject(
      const ArtistsContent(),
    );
  }
}

class ArtistsContent extends StatelessWidget {
  const ArtistsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final artistsBucket = LiveArtistsBucket.of(context);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: artistsBucket.length,
          itemBuilder: (context, index) {
            final artist = artistsBucket[index];

            return Padding(
              padding: EdgeInsets.only(
                right: index == artistsBucket.length - 1 ? 0 : 8,
              ),
              child: SizedBox(
                width: 180,
                child: ArtistSearchTile(artist: artist),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArtistSearchTile extends StatelessWidget {
  const ArtistSearchTile({
    super.key,
    required this.artist,
  });

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      tileColor: theme.colorScheme.surfaceContainerHigh,
      // leading: ArtistCircle(artist: artist),
      title: Text(
        artist.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // subtitle: Text(
      //   "${l10n.albums(artist.numberOfAlbums)} · ${l10n.tracks(artist.numberOfTracks)}",
      // ),
      onTap: () => ArtistAlbumsPage.go(context, artist.id, true),
    );
  }
}
