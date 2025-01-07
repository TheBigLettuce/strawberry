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
  void seek(int sec);

  @async
  void play();
  @async
  void pause();

  @async
  void changeTrack(int id);

  @async
  void setLooping(bool looping);
}

@HostApi()
abstract interface class DataLoader {
  RestoredData restore();

  @async
  void startLoadingAlbums();
  @async
  void startLoadingTracks();
  @async
  void startLoadingArtists();
}

class RestoredData {
  const RestoredData({
    required this.isLooping,
    required this.isPlaying,
    required this.progress,
    required this.currentTrack,
    required this.queue,
  });

  final bool isLooping;
  final bool isPlaying;
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
  Track? byId(int id);

  Track? current();
  Track? nextFromCurrent();
}

@FlutterApi()
abstract interface class DataNotifications {
  void notifyAlbums();
  void notifyTracks();
  void notifyArtists();

  void insertAlbums(List<Album> albums, String? generation);
  void insertTracks(List<Track> tracks, String? generation);
  void insertArtists(List<Artist> artists, String? generation);
}

@FlutterApi()
abstract interface class PlaybackEvents {
  void addPlaying(bool playing);
  void addSeek(int duration);
  void addLooping(bool looping);
  void addTrackChange(Track? track);
}
