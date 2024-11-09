import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:meta/meta.dart";
import "package:strawberry/src/platform/generated/platform_api.g.dart"
    as platform;

export "package:strawberry/src/platform/generated/platform_api.g.dart"
    show Album, Artist, DataNotifications, PlaybackEvents, Queue, Track;

abstract interface class StorageDriver {
  factory StorageDriver.memoryOnly() => _StorageDriver();

  StorageBucket<platform.Album> get albums;
  StorageBucket<platform.Artist> get artists;
  StorageBucket<platform.Track> get tracks;
}

abstract interface class StorageBucket<T> extends Iterable<T> {
  T operator [](int i);

  void put(List<T> elements);

  void setGeneration(String generation);

  void clear();

  Stream<int> get events;
}

abstract interface class BucketSearch<T> {
  T findById(int id);
}

class _StorageBucket<T> extends StorageBucket<T> {
  _StorageBucket();

  final _events = StreamController<int>.broadcast();
  String _generation = "";
  final List<T> storage = [];

  @override
  T operator [](int i) => storage[i];

  @override
  int get length => storage.length;

  @override
  Stream<int> get events => _events.stream;

  @override
  Iterator<T> get iterator => storage.iterator;

  @override
  void put(List<T> elements) {
    storage.addAll(elements);
    _events.add(storage.length);

    print(elements);
  }

  @override
  void setGeneration(String generation) {
    _generation = generation;
  }

  @override
  void clear() {
    storage.clear();
    _events.add(0);
  }
}

class _StorageDriver implements StorageDriver {
  _StorageDriver();

  @override
  StorageBucket<platform.Album> albums = _StorageBucket();

  @override
  StorageBucket<platform.Artist> artists = _StorageBucket();

  @override
  StorageBucket<platform.Track> tracks = _StorageBucket();
}

abstract interface class Player {
  platform.PlaybackController get controller;

  QueueList get queue;

  Stream<PlaybackEvent> get playbackEvents;
}

abstract interface class QueueList extends Iterable<platform.Track>
    implements platform.Queue {
  platform.Track? get currentTrack;
  platform.Track? get nextTrack;

  platform.Track operator [](int id);

  void operator []=(int id, platform.Track track);

  void clearAndPlay(platform.Track track);
  void add(platform.Track track);
  void shiftPositions(platform.Track from, platform.Track to);

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

  final int duration;
}

class Playing implements PlaybackEvent {
  const Playing(this.playing);

  final bool playing;
}

class TrackChange implements PlaybackEvent {
  const TrackChange(this.track);

  final platform.Track? track;
}

class DataNotificationsImpl implements platform.DataNotifications {
  DataNotificationsImpl({
    required this.storage,
  });

  final StorageDriver storage;
  final loader = platform.DataLoader();

  @override
  void insertAlbums(List<platform.Album> albums, String? generation) {
    storage.albums.put(albums);
    if (generation != null) {
      storage.albums.setGeneration(generation);
    }
  }

  @override
  void insertArtists(List<platform.Artist> artists, String? generation) {
    storage.artists.put(artists);
    if (generation != null) {
      storage.artists.setGeneration(generation);
    }
  }

  @override
  void insertTracks(List<platform.Track> tracks, String? generation) {
    storage.tracks.put(tracks);
    if (generation != null) {
      storage.tracks.setGeneration(generation);
    }
  }

  @override
  void notifyAlbums() {
    storage.albums.clear();
    loader.startLoadingAlbums();
  }

  @override
  void notifyArtists() {
    storage.artists.clear();
    loader.startLoadingArtists();
  }

  @override
  void notifyTracks() {
    storage.tracks.clear();
    loader.startLoadingTracks();
  }
}

class _QueueList extends QueueList {
  _QueueList(this.player);

  final Player player;

  final _stream = StreamController<int>.broadcast();
  final order = <platform.Track>[];

  @override
  platform.Track operator [](int id) => order.firstWhere((e) => e.id == id);

  @override
  void operator []=(int id, platform.Track track) {
    add(track);
  }

  @override
  Iterator<platform.Track> get iterator => order.iterator;

  @override
  Stream<int> get events => _stream.stream;

  @override
  platform.Track? currentTrack;

  @override
  platform.Track? get nextTrack {
    if (order.isEmpty || order.length == 1 || currentTrack == null) {
      return null;
    }

    final idx = order.indexWhere((e) => e.id == currentTrack!.id);
    if (idx == -1) {
      debugPrintThrottled("current track hasn't been found in queue");
      return null;
    }

    return order[idx];
  }

  @override
  void add(platform.Track track) {
    order.add(track);
    _stream.add(order.length);
  }

  @override
  void clearAndPlay(platform.Track track) {
    order.clear();
    order.add(track);
    _stream.add(order.length);
    player.controller.changeTrack(track.id);
  }

  @override
  void shiftPositions(platform.Track from, platform.Track to) {
    final idx1 = order.indexWhere((e) => e.id == from.id);
    final idx2 = order.indexWhere((e) => e.id == to.id);

    if (idx1 == -1 || idx2 == -1) {
      return;
    }

    final e1 = order[idx1];
    final e2 = order[idx2];
    order[idx1] = e2;
    order[idx2] = e1;
    _stream.add(order.length);
  }
}

class PlaybackEventsImpl implements platform.PlaybackEvents, Player {
  PlaybackEventsImpl() {
    queue = _QueueList(this);
  }

  @override
  late final _QueueList queue;

  final _events = StreamController<PlaybackEvent>.broadcast();

  @override
  platform.PlaybackController controller = platform.PlaybackController();

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
  void addSeek(int duration) {
    _events.add(Seek(duration));
  }

  @override
  void addTrackChange(platform.Track? track) {
    _events.add(TrackChange(track));
    queue.currentTrack = track;
    queue._stream.add(queue.order.length);
  }
}
