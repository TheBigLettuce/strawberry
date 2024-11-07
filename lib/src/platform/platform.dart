import "dart:async";

import "package:meta/meta.dart";
import "package:strawberry/src/platform/generated/platform_api.g.dart"
    as platform;

export "package:strawberry/src/platform/generated/platform_api.g.dart"
    show Album, Artist, PlaybackEvents, Queue, Track;

abstract interface class StorageDriver {}

abstract interface class Player {
  QueueList get queue;
  Stream<PlaybackEvent> get playbackEvents;
}

abstract interface class QueueList extends Iterable<platform.Track>
    implements platform.Queue {
  platform.Track? get currentTrack;
  platform.Track? get nextTrack;

  platform.Track operator [](int id);

  void operator []=(int id, platform.Track track);

  Stream<int> get events;

  @override
  platform.Track? current() => currentTrack;

  @override
  platform.Track? nextFromCurrent() => nextTrack;

  @override
  platform.Track? byId(int id) => this[id];
}

abstract interface class PlayerController {}

@immutable
sealed class PlaybackEvent {
  const PlaybackEvent();
}

class Looping implements PlaybackEvent {
  const Looping(this.looping);

  final bool looping;
}

class Seek implements PlaybackEvent {
  const Seek(this.duration);

  final double duration;
}

class Playing implements PlaybackEvent {
  const Playing(this.playing);

  final bool playing;
}

class TrackChange implements PlaybackEvent {
  const TrackChange(this.trackId);

  final int trackId;
}

class DataNotificationsImpl implements platform.DataNotifications {
  DataNotificationsImpl({
    required this.storage,
  });

  final StorageDriver storage;

  @override
  void insertAlbums(List<platform.Album> albums, String? generation) {
    // TODO: implement insertAlbums
  }

  @override
  void insertArtists(List<platform.Artist> artists, String? generation) {
    // TODO: implement insertArtists
  }

  @override
  void insertTracks(List<platform.Track> tracks, String? generation) {
    // TODO: implement insertTracks
  }

  @override
  void notifyAlbums() {
    // TODO: implement notifyAlbums
  }

  @override
  void notifyArtists() {
    // TODO: implement notifyArtists
  }

  @override
  void notifyTracks() {
    // TODO: implement notifyTracks
  }
}

class _QueueList extends QueueList {
  _QueueList();

  final _map = <int, platform.Track>{};
  final _stream = StreamController<int>.broadcast();

  @override
  platform.Track operator [](int id) => _map[id]!;

  @override
  void operator []=(int id, platform.Track track) {
    _map[id] = track;
    _stream.add(_map.length);
  }

  @override
  Iterator<platform.Track> get iterator => _map.values.iterator;

  @override
  Stream<int> get events => _stream.stream;

  @override
  platform.Track? currentTrack;

  @override
  platform.Track? nextTrack;
}

class PlaybackEventsImpl implements platform.PlaybackEvents, Player {
  PlaybackEventsImpl();

  @override
  QueueList queue = _QueueList();

  final _events = StreamController<PlaybackEvent>.broadcast();

  @override
  Stream<PlaybackEvent> get playbackEvents => _events.stream;

  @override
  void addLooping(bool looping) {
    _events.add(Looping(looping));
  }

  @override
  void addPlaying(bool playing) {
    _events.add(Playing(playing));
  }

  @override
  void addSeek(double duration) {
    _events.add(Seek(duration));
  }

  @override
  void addTrackChange(int id) {
    _events.add(TrackChange(id));
  }
}
