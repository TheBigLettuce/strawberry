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

import "package:pigeon/pigeon.dart";

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/platform/generated/platform_api.g.dart",
    dartTestOut: "test/platform_api.g.dart",
    kotlinOut:
        "android/app/src/main/kotlin/com/github/thebiglettuce/strawberry/generated/Generated.kt",
    kotlinOptions: KotlinOptions(
      package: "com.github.thebiglettuce.strawberry.generated",
    ),
    copyrightHeader: "pigeons/copyright.txt",
  ),
)
class Artist {
  const Artist({
    required this.id,
    required this.numberOfAlbums,
    required this.numberOfTracks,
    required this.artist,
  });

  final int id;
  final int numberOfAlbums;
  final int numberOfTracks;

  final String artist;
}

class Track {
  const Track({
    required this.id,
    required this.albumId,
    required this.dateModified,
    required this.track,
    required this.discNumber,
    required this.duration,
    required this.artist,
    required this.album,
    required this.albumArtist,
    required this.name,
  });

  final int id;
  final int albumId;

  final int dateModified;
  final int track;
  final int discNumber;
  final int duration;

  final String artist;
  final String album;
  final String albumArtist;
  final String name;
}

class Album {
  const Album({
    required this.id,
    required this.albumId,
    required this.artistId,
    required this.firstYear,
    required this.secondYear,
    required this.numberOfSongs,
    required this.album,
    required this.artist,
  });

  final int id;
  final int albumId;
  final int artistId;

  final int firstYear;
  final int secondYear;

  final int numberOfSongs;

  final String album;
  final String artist;
}

@HostApi()
abstract interface class PlaybackController {
  @async
  void next();

  @async
  void prev();

  @async
  void seek(int sec);

  @async
  void play();
  @async
  void pause();

  @async
  void changeTrack(int id);

  @async
  void setIndex(int index);

  @async
  void setTracks(List<Track> tracks);

  @async
  void swapIndexes(int i1, int i2);

  @async
  void addTrack(int id);

  @async
  void addTracks(List<Track> tracks);

  @async
  void removeTrack(int index);

  @async
  void removeIdxs(List<int> indexes);

  @async
  void clearStop();

  @async
  void setLooping(LoopingState looping);

  @async
  void setShuffle(bool shuffle);
}

@HostApi()
abstract interface class DataLoader {
  @async
  RestoredData restore();

  @async
  void startLoadingAlbums();
  @async
  void startLoadingTracks();
  @async
  void startLoadingArtists();

  void unlockAlbums();
  void unlockTracks();
  void unlockArtists();
}

class RestoredData {
  const RestoredData({
    required this.looping,
    required this.isPlaying,
    required this.isShuffling,
    required this.progress,
    required this.currentTrack,
    required this.queue,
  });

  final LoopingState looping;
  final bool isPlaying;
  final bool isShuffling;
  final int progress;
  final Track? currentTrack;
  final List<Track> queue;
}

@HostApi()
abstract interface class MediaThumbnails {
  @async
  String loadAndCache(int id, MediaThumbnailType type);
}

enum MediaThumbnailType {
  album,
  track;
}

@FlutterApi()
abstract interface class Queue {
  void ensureQueueClear();
  void ensureCurrentTrack(Track? track);

  Track? byId(int id);

  Track? current();
  Track? nextFromCurrent();
}

class QueueData {
  const QueueData({
    required this.queue,
    required this.currentTrack,
  });

  final Track? currentTrack;
  final List<Track> queue;
}

@FlutterApi()
abstract interface class DataNotifications {
  void notifyAlbums();
  void notifyTracks();
  void notifyArtists();

  void insertAlbums(List<Album> albums);
  void insertTracks(List<Track> tracks);
  void insertArtists(List<Artist> artists);
}

@FlutterApi()
abstract interface class PlaybackEvents {
  void addPlaying(bool playing);
  void addSeek(int duration);
  void addLooping(LoopingState looping);
  void addTrackChange(Track? track);
  void addShuffle(bool shuffle);

  void addState(AllEvents events);
}

class AllEvents {
  const AllEvents({
    required this.isPlaying,
    required this.progress,
    required this.looping,
    required this.shuffle,
  });

  final bool isPlaying;
  final int progress;
  final LoopingState looping;
  final bool shuffle;
}

enum LoopingState {
  off,
  one,
  all;
}
