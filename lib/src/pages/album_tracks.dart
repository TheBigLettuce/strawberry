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
import "package:strawberry/exts.dart";
import "package:strawberry/l10n/generated/app_localizations.dart";
import "package:strawberry/src/pages/queue.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:strawberry/src/platform/platform_thumbnail.dart";

class AlbumTracksPage extends StatefulWidget {
  const AlbumTracksPage({
    super.key,
  });

  static void go(BuildContext context, Album album, [bool push = false]) {
    final result = TracksBucket.queryAlbumOf(
      context,
      album,
    );

    if (push) {
      context.pushNamed("AlbumTracks", extra: result);
    } else {
      context.goNamed("AlbumTracks", extra: result);
    }
  }

  @override
  State<AlbumTracksPage> createState() => _AlbumTracksPageState();
}

class _AlbumTracksPageState extends State<AlbumTracksPage> {
  @override
  Widget build(BuildContext context) {
    final tracks = LiveTracksBucket.of(context);
    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return AlbumInfoBody(
      album: tracks.associatedAlbum!,
      tracks: tracks,
      showImage: false,
      child: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];

          return TrackTile(track: track);
        },
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.reverseIcon = false,
    this.maxLines = 2,
    this.overrideColor,
  });

  final Color? overrideColor;
  final bool reverseIcon;
  final int maxLines;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queue = QueueList.of(context);
    final inQueue = queue.containsTrack(track);

    final avatar = CircleAvatar(
      backgroundImage: PlatformThumbnailProvider.album(
        track.albumId,
        theme.brightness,
      ),
      child: queue.isCurrent(track.id) ? const IsPlayingIndicator() : null,
    );

    final addRemoveButton = AnimatedCrossFade(
      firstChild: IconButton(
        key: const ValueKey(true),
        onPressed: () {
          queue.removeTrack(track);
        },
        icon: const Icon(Icons.remove),
      ),
      secondChild: IconButton(
        key: const ValueKey(false),
        onPressed: () {
          queue.add(track);
        },
        icon: const Icon(Icons.add),
      ),
      crossFadeState:
          inQueue ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: Durations.medium3,
      reverseDuration: Durations.medium1,
    );

    return Column(
      children: [
        ListTile(
          tileColor: overrideColor,
          trailing: reverseIcon ? avatar : addRemoveButton,
          onTap: () {
            final isCurrent = queue.isCurrent(track.id);

            if (queue.hasCurrentTrack && isCurrent) {
              Player.of(context).flipIsPlaying(context);
            } else if (queue.isNotEmpty && inQueue) {
              final idx = queue.trackIdIndex(track.id);
              if (idx != -1) {
                queue.setAt(idx);
              }
            } else {
              queue.clearAndPlay([track]);
            }
          },
          leading: reverseIcon ? addRemoveButton : avatar,
          title: Text(
            track.name,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "${track.track} · ${track.duration.durationMilisFormatted}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: overrideColor),
          child: queue.isCurrent(track.id)
              ? TrackPlaybackProgress(track: track)
              : const SizedBox(height: 2, width: double.infinity),
        ),
      ],
    );
  }
}

class IsPlayingIndicator extends StatelessWidget {
  const IsPlayingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = PlayerStateQuery.isPlayingOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface.valueAlpha(0.75),
      ),
      child: Center(
        child: AnimatedCrossFade(
          firstChild: const Icon(
            Icons.play_circle_outline_rounded,
            key: ValueKey(true),
          ),
          secondChild: const Icon(
            Icons.pause_circle_outline_rounded,
            key: ValueKey(false),
          ),
          crossFadeState:
              isPlaying ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: Durations.medium1,
        ),
      ),
    );
  }
}

class AlbumInfoBody extends StatelessWidget {
  const AlbumInfoBody({
    super.key,
    required this.tracks,
    required this.album,
    this.showImage = true,
    this.child,
  });

  final Album album;
  final Iterable<Track> tracks;

  final bool showImage;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showImage)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Image(
                        frameBuilder:
                            PlatformThumbnailProvider.defaultFrameBuilder,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            album.artist,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.valueAlpha(0.9),
                            ),
                          ),
                          Text(
                            album.yearsFormatted,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.valueAlpha(0.8),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.items(album.numberOfSongs),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.valueAlpha(0.8),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      QueueList.clearAndPlayOf(
                        context,
                        tracks,
                      );
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
                      QueueList.addAllOf(context, tracks);
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
                l10n.minutes(tracks.countDurationMinutes()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.valueAlpha(0.8),
                ),
              ),
            ],
          ),
        ),
        if (child != null) Expanded(child: child!),
      ],
    );
  }
}
