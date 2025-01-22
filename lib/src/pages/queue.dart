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
import "package:flutter_animate/flutter_animate.dart";
import "package:go_router/go_router.dart";
import "package:strawberry/l10n/generated/app_localizations.dart";
import "package:strawberry/src/pages/album_tracks.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:strawberry/src/platform/platform_thumbnail.dart";

class QueueModalPage extends StatefulWidget {
  const QueueModalPage({
    super.key,
  });

  static void go(BuildContext context, [int seekTo = 0]) {
    context.goNamed("QueueModal");
  }

  @override
  State<QueueModalPage> createState() => _QueueModalPageState();
}

class _QueueModalPageState extends State<QueueModalPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final queue = QueueList.of(context);

    if (queue.isEmpty) {
      return Center(
        child: Text(
          l10n.empty,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ).animate().fadeIn();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Builder(
                builder: (context) {
                  final shuffle = PlayerStateQuery.isShuffleOf(context);

                  return IconButton(
                    onPressed: () {
                      Player.of(context).flipIsShuffling(context);
                    },
                    isSelected: shuffle,
                    icon: const Icon(Icons.shuffle),
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  queue.clearStop();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.items(queue.length),
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                l10n.minutes(
                  Duration(
                    milliseconds: queue.fold(0, (i, e) => i + e.duration),
                  ).inMinutes,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            // header: queue.currentTrack == null
            //     ? null
            //     : Padding(
            //         padding: EdgeInsets.only(bottom: 40),
            //         child: QueueTrackTile(
            //           track: queue.currentTrack!,
            //           isCurrent: true,
            //           index: -1,
            //         ),
            //       ),
            onReorder: (oldIndex, newIndex) {
              if (newIndex >= queue.length) {
                queue.shiftIndex(oldIndex, queue.length - 1);
              } else {
                queue.shiftIndex(oldIndex, newIndex);
              }
            },
            itemCount: queue.length,
            itemBuilder: (context, index) {
              final track = queue[index];
              final current = queue.current();

              return Dismissible(
                direction: DismissDirection.endToStart,
                // dismissThresholds: const {DismissDirection.endToStart: 0.5},
                key: ValueKey((track.id, index)),
                onDismissed: (direction) {
                  QueueList.removeAtOf(context, index);
                },
                child: QueueTrackTile(
                  track: track,
                  isCurrent: current != null && current.id == track.id,
                  index: index,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
        ),
      ],
    );
  }
}

class QueueTrackTile extends StatelessWidget {
  const QueueTrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
  });

  final bool isCurrent;
  final int index;

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: PlatformThumbnailProvider.album(
              track.albumId,
              Theme.of(context).brightness,
            ),
            child: isCurrent ? const IsPlayingIndicator() : null,
          ),
          title: Text(track.name),
          subtitle: Text(track.album),
          onTap: () {
            if (index < 0) {
              Player.of(context).flipIsPlaying(context);
            } else {
              Player.of(context).changeOrPlay(context, track, index);
            }
          },
        ),
        if (isCurrent)
          TrackPlaybackProgress(track: track)
        else
          const SizedBox(height: 2),
      ],
    );
  }
}

class TrackPlaybackProgress extends StatelessWidget {
  const TrackPlaybackProgress({
    super.key,
    required this.track,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height = 2,
  });

  final Track track;
  final EdgeInsets padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = PlayerStateQuery.progressOf(context).inMilliseconds;

    return Padding(
      padding: padding,
      child: LinearProgressIndicator(
        trackGap: 0,
        minHeight: height,
        year2023: false,
        value: progress <= 0 || track.duration <= 0
            ? 0
            : progress / track.duration,
      ),
    );
  }
}
