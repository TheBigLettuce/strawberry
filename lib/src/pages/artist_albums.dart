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
import "package:go_router/go_router.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/platform/platform.dart";

class ArtistAlbumsPage extends StatefulWidget {
  const ArtistAlbumsPage({
    super.key,
  });

  static void go(BuildContext context, int artistId, [bool push = false]) {
    final albums = AlbumsBucket.queryArtistIdOf(context, artistId);
    final result = TracksBucket.queryAlbumsOf(context, albums.toList());
    albums.dispose();

    if (push) {
      context.pushNamed("ArtistAlbums", extra: result);
    } else {
      context.goNamed("ArtistAlbums", extra: result);
    }
  }

  @override
  State<ArtistAlbumsPage> createState() => _ArtistAlbumsPageState();
}

class _ArtistAlbumsPageState extends State<ArtistAlbumsPage> {
  @override
  Widget build(BuildContext context) {
    final albums = CombinedLiveTracksBucket.of(context);

    return CustomScrollView(
      slivers: [
        ...albums.sortedTracks.indexed.map(
          (e) => _AlbumAndTracks(
            data: e.$2,
            padding: e.$1 == albums.sortedTracks.length - 1
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 8),
          ),
        ),
        SliverPadding(
          padding: MediaQuery.viewPaddingOf(context),
        ),
      ],
    );
  }
}

class _AlbumAndTracks extends StatefulWidget {
  const _AlbumAndTracks({
    // super.key,
    required this.data,
    required this.padding,
  });

  final AlbumTracksRecord data;
  final EdgeInsets padding;

  @override
  State<_AlbumAndTracks> createState() => __AlbumAndTracksState();
}

class __AlbumAndTracksState extends State<_AlbumAndTracks> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.data.album;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: AlbumInfoBody(
              album: album,
              tracks: widget.data.tracks,
            ),
          ),
        ),
        AlbumTracks(data: expanded ? widget.data : null),
        SliverPadding(padding: widget.padding),
      ],
    );
  }
}

class AlbumTracks extends StatelessWidget {
  const AlbumTracks({
    super.key,
    required this.data,
  });

  final AlbumTracksRecord? data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: AnimatedSize(
        alignment: Alignment.topCenter,
        curve: Easing.emphasizedDecelerate,
        duration: Durations.medium4,
        reverseDuration: Durations.medium1,
        child: Column(
          children: data == null
              ? []
              : data!.tracks
                  .map(
                    (e) => TrackTile(
                      track: e,
                      overrideColor: theme.colorScheme.surfaceContainerLowest,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
