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
import "package:strawberry/l10n/generated/app_localizations.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:strawberry/src/platform/platform_thumbnail.dart";

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
    // final p = ;

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

  final (Album, List<Track>) data;
  final EdgeInsets padding;

  @override
  State<_AlbumAndTracks> createState() => __AlbumAndTracksState();
}

class __AlbumAndTracksState extends State<_AlbumAndTracks> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final album = widget.data.$1;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(6)),
                          child: SizedBox.square(
                            dimension: 48,
                            child: Image(
                              image: PlatformThumbnailProvider.album(
                                album.albumId,
                                theme.brightness,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                album.album,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    album.artist,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                  Text(
                                    album.formatYears(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.items(album.numberOfSongs),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              QueueList.clearAndPlayOf(context, widget.data.$2);
                            },
                            child: Text(
                              l10n.playAll,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Padding(padding: EdgeInsets.only(right: 16)),
                          GestureDetector(
                            onTap: () {
                              QueueList.addAllOf(context, widget.data.$2);
                            },
                            child: Text(
                              l10n.addAll,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l10n.minutes(
                          Duration(
                            milliseconds: widget.data.$2
                                .fold(0, (i, e) => i + e.duration),
                          ).inMinutes,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  final (Album, List<Track>)? data;

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
              : data!.$2
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
