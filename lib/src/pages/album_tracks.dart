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
    final theme = Theme.of(context);
    final tracks = LiveTracksBucket.of(context);
    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16) +
              const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            tracks.associatedAlbum?.album ?? tracks.first.album,
            style: theme.textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16) +
              const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tracks.associatedAlbum?.artist ?? tracks.first.albumArtist,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
              if (tracks.associatedAlbum != null)
                Text(
                  tracks.associatedAlbum!.formatYears(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                "${tracks.length} items",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      QueueList.clearAndPlayOf(context, tracks.toList());
                    },
                    child: Text(
                      "Play all",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(right: 16)),
                  GestureDetector(
                    onTap: () {
                      QueueList.addAllOf(context, tracks.toList());
                    },
                    child: Text(
                      "Add all",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "${Duration(milliseconds: tracks.fold(0, (i, e) => i + e.duration)).inMinutes} minutes",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];

              return TrackTile(
                track: track,
              );
            },
          ),
        ),
      ],
    );
  }
}

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.overrideColor,
  });

  final Color? overrideColor;
  final Track track;

  String formatDuration(int duration) {
    var microseconds = Duration(milliseconds: duration).inMicroseconds;

    final minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    final seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final queue = QueueList.of(context);
    final inQueue = queue.containsTrack(track);
    final isCurrent = queue.currentTrack?.id == track.id;

    return Column(
      children: [
        ListTile(
          tileColor: overrideColor,
          trailing: AnimatedCrossFade(
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
          ),
          onTap: () {
            if (queue.currentTrack != null &&
                queue.currentTrack!.id == track.id) {
              Player.of(context).flipIsPlaying(context);
            } else {
              queue.clearAndPlay([track]);
            }
          },
          leading: CircleAvatar(
            foregroundImage: PlatformThumbnailProvider.album(
              track.albumId,
              Theme.of(context).brightness,
            ),
          ),
          title: Text(track.name),
          subtitle: Text(
            "${track.track} · ${formatDuration(track.duration)}",
          ),
        ),
        if (isCurrent)
          TrackPlaybackProgress(track: track)
        else
          const SizedBox(height: 2),
      ],
    );
  }
}
