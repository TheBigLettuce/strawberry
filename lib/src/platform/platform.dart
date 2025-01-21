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

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:strawberry/src/platform/generated/platform_api.g.dart"
    as platform;

export "package:strawberry/src/platform/generated/platform_api.g.dart"
    show
        Album,
        Artist,
        DataNotifications,
        LoopingState,
        MediaThumbnailType,
        MediaThumbnails,
        PlaybackEvents,
        Queue,
        Track;

extension FormatYearsAlbumExt on platform.Album {
  String formatYears() {
    if (firstYear == 0 && secondYear == 0) {
      return "";
    }

    if (firstYear == secondYear) {
      return "$firstYear";
    }

    return "$firstYear—$album";
  }
}

final platform.PlaybackController _controller = platform.PlaybackController();

StateManager createStateManager() {
  final stateManager = StateManager._memoryOnly();

  platform.PlaybackEvents.setUp(stateManager.playerManager.playbackEvents);
  platform.Queue.setUp(stateManager.playerManager.player.queue);
  platform.DataNotifications.setUp(stateManager.playerManager.data);

  return stateManager;
}

abstract interface class StateManager {
  factory StateManager._memoryOnly() => _StateManager();

  StorageDriver get storage;
  RequestsHandler get requests;

  PlayerManager get playerManager;

  Widget inject(Widget child);

  void restore(platform.RestoredData data);

  static StateManager of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<StateManagerNotifier>();

    return widget!.stateManager;
  }

  void dispose();
}

abstract interface class PlayerManager {
  Player get player;

  platform.PlaybackEvents get playbackEvents;
  platform.DataNotifications get data;

  Widget inject(Widget child);

  static PlayerManager of(BuildContext context) =>
      StateManager.of(context).playerManager;

  void dispose();
}

class _PlayerManager implements PlayerManager {
  _PlayerManager(this.stateManager)
      : data = DataNotificationsImpl(storage: stateManager.storage);

  final StateManager stateManager;

  @override
  final PlaybackEventsImpl player = PlaybackEventsImpl();

  @override
  platform.PlaybackEvents get playbackEvents => player;

  @override
  final platform.DataNotifications data;

  @override
  Widget inject(Widget child) {
    return player.inject(child);
  }

  @override
  void dispose() {
    stateManager.dispose();
    player.dispose();
  }
}

class _StateManager implements StateManager {
  _StateManager();

  @override
  RequestsHandler get requests => throw UnimplementedError();

  @override
  final StorageDriver storage = _StorageDriver();

  @override
  late final PlayerManager playerManager = _PlayerManager(this);

  @override
  void restore(platform.RestoredData data) {
    playerManager.player.restore(data);
  }

  @override
  Widget inject(Widget child) {
    return StateManagerNotifier(
      stateManager: this,
      child: storage.inject(
        playerManager.inject(child),
      ),
    );
  }

  @override
  void dispose() {
    storage.dispose();
    playerManager.dispose();
    requests.dispose();

    platform.PlaybackEvents.setUp(null);
    platform.Queue.setUp(null);
    platform.DataNotifications.setUp(null);
  }
}

class StateManagerNotifier extends InheritedWidget {
  const StateManagerNotifier({
    super.key,
    required this.stateManager,
    required super.child,
  });

  final StateManager stateManager;

  @override
  bool updateShouldNotify(StateManagerNotifier oldWidget) {
    return stateManager != oldWidget.stateManager;
  }
}

class QueueListNotifier extends InheritedWidget {
  const QueueListNotifier({
    super.key,
    required this.queueList,
    required this.count,
    required this.currentTrack,
    required super.child,
  });

  final QueueList queueList;
  final platform.Track? currentTrack;
  final int count;

  @override
  bool updateShouldNotify(QueueListNotifier oldWidget) {
    return count != oldWidget.count ||
        queueList != oldWidget.queueList ||
        currentTrack != oldWidget.currentTrack;
  }
}

class PlaybackStateNotifier extends InheritedWidget {
  const PlaybackStateNotifier({
    super.key,
    required this.playbackEvent,
    required super.child,
  });

  final PlaybackEvent playbackEvent;

  @override
  bool updateShouldNotify(PlaybackStateNotifier oldWidget) {
    return playbackEvent != oldWidget.playbackEvent;
  }
}

abstract interface class RequestsHandler {
  void dispose();
}

class NetworkRequest {
  NetworkRequest();
}

abstract interface class StorageDriver {
  AlbumsBucket get albums;
  ArtistsBucket get artists;
  TracksBucket get tracks;

  Widget inject(Widget child);

  void dispose();
}

abstract interface class LiveBucketData<T> extends Iterable<T> {
  T operator [](int i);

  Widget inject(Widget child);

  void dispose();
}

abstract class _StorageBucketLiveData<T> extends LiveBucketData<T> {
  _StorageBucketLiveData(_StorageBucket<T> upstreamBucket) {
    _countEvents = upstreamBucket._events.stream.listen((e) {
      data.clear();
      loadFilteredValues(upstreamBucket.storage);
      _events.add(data.length);
    });

    loadFilteredValues(upstreamBucket.storage);
  }

  late final StreamSubscription<int> _countEvents;
  final _events = StreamController<int>.broadcast();

  final data = <T>[];

  @override
  T operator [](int i) => data[i];

  @override
  int get length => data.length;

  void loadFilteredValues(List<T> upstream);

  @override
  Widget inject(Widget child);

  @override
  Iterator<T> get iterator => data.iterator;

  @override
  void dispose() {
    _events.close();
    _countEvents.cancel();
  }
}

sealed class AlbumsBucket extends StorageBucket<platform.Album> {
  LiveAlbumsBucket query(String albumName);
  LiveAlbumsBucket queryArtistId(int artistId);

  static AlbumsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AlbumBucketNotifier>();

    return widget!.bucket;
  }

  static LiveAlbumsBucket queryArtistIdOf(BuildContext context, int artistId) {
    final widget = context.getInheritedWidgetOfExactType<AlbumBucketNotifier>();

    return widget!.bucket.queryArtistId(artistId);
  }
}

sealed class ArtistsBucket extends StorageBucket<platform.Artist> {
  LiveArtistsBucket query(String artistName);

  static ArtistsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ArtistBucketNotifier>();

    return widget!.bucket;
  }
}

sealed class LiveArtistsBucket extends LiveBucketData<platform.Artist> {
  static LiveArtistsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<LiveArtistsBucketNotifier>();

    return widget!.bucketData;
  }
}

class LiveArtistsBucketNotifier extends InheritedWidget {
  const LiveArtistsBucketNotifier({
    super.key,
    required this.count,
    required this.bucketData,
    required super.child,
  });

  final LiveArtistsBucket bucketData;
  final int count;

  @override
  bool updateShouldNotify(LiveArtistsBucketNotifier oldWidget) {
    return bucketData != oldWidget.bucketData || count != oldWidget.count;
  }
}

sealed class LiveTracksBucket extends LiveBucketData<platform.Track> {
  platform.Album? get associatedAlbum;

  static LiveTracksBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<LiveTracksBucketNotifier>();

    return widget!.bucketData;
  }
}

sealed class CombinedLiveTracksBucket {
  List<(platform.Album, List<platform.Track>)> get sortedTracks;

  Widget inject(Widget child);

  static CombinedLiveTracksBucket of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<CombinedLiveTracksBucketNotifier>();

    return widget!.bucketData;
  }

  void dispose();
}

class LiveTracksBucketNotifier extends InheritedWidget {
  const LiveTracksBucketNotifier({
    super.key,
    required this.count,
    required this.bucketData,
    required super.child,
  });

  final LiveTracksBucket bucketData;
  final int count;

  @override
  bool updateShouldNotify(LiveTracksBucketNotifier oldWidget) {
    return bucketData != oldWidget.bucketData || count != oldWidget.count;
  }
}

sealed class LiveAlbumsBucket extends LiveBucketData<platform.Album> {
  static LiveAlbumsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<LiveAlbumsBucketNotifier>();

    return widget!.bucketData;
  }
}

class LiveAlbumsBucketNotifier extends InheritedWidget {
  const LiveAlbumsBucketNotifier({
    super.key,
    required this.count,
    required this.bucketData,
    required super.child,
  });

  final LiveAlbumsBucket bucketData;
  final int count;

  @override
  bool updateShouldNotify(LiveAlbumsBucketNotifier oldWidget) {
    return bucketData != oldWidget.bucketData || count != oldWidget.count;
  }
}

class CombinedLiveTracksBucketNotifier extends InheritedWidget {
  const CombinedLiveTracksBucketNotifier({
    super.key,
    required this.count,
    required this.bucketData,
    required super.child,
  });

  final CombinedLiveTracksBucket bucketData;
  final int count;

  @override
  bool updateShouldNotify(CombinedLiveTracksBucketNotifier oldWidget) {
    return bucketData != oldWidget.bucketData || count != oldWidget.count;
  }
}

sealed class TracksBucket extends StorageBucket<platform.Track> {
  LiveTracksBucket query(String trackName);
  LiveTracksBucket queryAlbum(platform.Album album);
  CombinedLiveTracksBucket queryAlbums(List<platform.Album> albums);

  static TracksBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TrackBucketNotifier>();

    return widget!.bucket;
  }

  static LiveTracksBucket queryAlbumOf(
    BuildContext context,
    platform.Album album,
  ) {
    final widget = context.getInheritedWidgetOfExactType<TrackBucketNotifier>();

    return widget!.bucket.queryAlbum(album);
  }

  static CombinedLiveTracksBucket queryAlbumsOf(
    BuildContext context,
    List<platform.Album> albums,
  ) {
    final widget = context.getInheritedWidgetOfExactType<TrackBucketNotifier>();

    return widget!.bucket.queryAlbums(albums);
  }
}

class TrackBucketNotifier extends InheritedWidget {
  const TrackBucketNotifier({
    super.key,
    required this.bucket,
    required this.count,
    required super.child,
  });

  final TracksBucket bucket;
  final int count;

  @override
  bool updateShouldNotify(TrackBucketNotifier oldWidget) {
    return bucket != oldWidget.bucket || count != oldWidget.count;
  }
}

class ArtistBucketNotifier extends InheritedWidget {
  const ArtistBucketNotifier({
    super.key,
    required this.bucket,
    required this.count,
    required super.child,
  });

  final ArtistsBucket bucket;
  final int count;

  @override
  bool updateShouldNotify(ArtistBucketNotifier oldWidget) {
    return bucket != oldWidget.bucket || count != oldWidget.count;
  }
}

class AlbumBucketNotifier extends InheritedWidget {
  const AlbumBucketNotifier({
    super.key,
    required this.bucket,
    required this.count,
    required super.child,
  });

  final AlbumsBucket bucket;
  final int count;

  @override
  bool updateShouldNotify(AlbumBucketNotifier oldWidget) {
    return bucket != oldWidget.bucket || count != oldWidget.count;
  }
}

abstract interface class StorageBucket<T> extends Iterable<T> {
  T operator [](int i);

  void put(List<T> elements);

  void setGeneration(String generation);

  void clear();
  void destroy();

  Widget inject(Widget child);
}

abstract interface class BucketSearch<T> {
  T findById(int id);
}

abstract class _StorageBucket<T> extends StorageBucket<T> {
  _StorageBucket();

  final _events = StreamController<int>.broadcast();
  // String _generation = "";
  final List<T> storage = [];

  @override
  T operator [](int i) => storage[i];

  @override
  int get length => storage.length;

  @override
  Iterator<T> get iterator => storage.iterator;

  @override
  void put(List<T> elements) {
    storage.addAll(elements);
    _events.add(storage.length);
  }

  @override
  void setGeneration(String generation) {
    // _generation = generation;
  }

  @override
  void clear() {
    storage.clear();
    _events.add(0);
  }

  @override
  void destroy() {
    storage.clear();
    _events.close();
  }
}

class _CombinedLiveTracksBucket extends CombinedLiveTracksBucket {
  _CombinedLiveTracksBucket(
    _StorageBucket<platform.Track> upstreamBucket,
    List<platform.Album> albums,
  ) {
    _countEvents = upstreamBucket._events.stream.listen((e) {
      filterTracks(upstreamBucket.storage, albums);
    });

    filterTracks(upstreamBucket.storage, albums);
  }

  late final StreamSubscription<int> _countEvents;
  final _events = StreamController<int>.broadcast();

  @override
  final List<(platform.Album, List<platform.Track>)> sortedTracks = [];

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => CombinedLiveTracksBucketNotifier(
        count: sortedTracks.length,
        bucketData: this,
        child: child,
      ),
    );
  }

  void filterTracks(
    List<platform.Track> bucketStorage,
    List<platform.Album> albums,
  ) {
    final ret = <int, (platform.Album, List<platform.Track>)>{};

    for (final e in bucketStorage) {
      for (final album in albums) {
        if (album.albumId == e.albumId) {
          final l = ret[album.albumId] ?? (album, []);
          l.$2.add(e);

          ret[album.albumId] = l;
        }
      }
    }

    sortedTracks.clear();
    for (final e in albums) {
      final a = ret[e.albumId];
      if (a == null) {
        continue;
      }
      sortedTracks.add(a);
    }
    _events.add(sortedTracks.length);

    return;
  }

  @override
  void dispose() {
    _events.close();
    _countEvents.cancel();
  }
}

class _LiveArtistsBucket extends _StorageBucketLiveData<platform.Artist>
    implements LiveArtistsBucket {
  _LiveArtistsBucket(super.upstreamBucket, this.artistName);

  final String artistName;

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => LiveArtistsBucketNotifier(
        count: data.length,
        bucketData: this,
        child: child,
      ),
    );
  }

  @override
  void loadFilteredValues(List<platform.Artist> upstream) {
    for (final e in upstream) {
      if (e.artist.toLowerCase().startsWith(artistName)) {
        data.add(e);
      }
    }
  }
}

class _LiveTracksBucket extends _StorageBucketLiveData<platform.Track>
    implements LiveTracksBucket {
  _LiveTracksBucket(
    super.upstreamBucket,
    this.filterFn,
    this.associatedAlbum,
  );

  @override
  final platform.Album? associatedAlbum;

  final void Function(List<platform.Track> data, List<platform.Track> upstream)
      filterFn;

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => LiveTracksBucketNotifier(
        count: data.length,
        bucketData: this,
        child: child,
      ),
    );
  }

  @override
  void loadFilteredValues(List<platform.Track> upstream) {
    filterFn(data, upstream);
  }
}

class _LiveAlbumBucket extends _StorageBucketLiveData<platform.Album>
    implements LiveAlbumsBucket {
  _LiveAlbumBucket(super.upstreamBucket, this.filterFn);

  final void Function(List<platform.Album> data, List<platform.Album> upstream)
      filterFn;

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => LiveAlbumsBucketNotifier(
        count: data.length,
        bucketData: this,
        child: child,
      ),
    );
  }

  @override
  void loadFilteredValues(List<platform.Album> upstream) {
    filterFn(data, upstream);
  }

  @override
  String toString() => data.toString();
}

class _AlbumBucket extends _StorageBucket<platform.Album>
    implements AlbumsBucket {
  @override
  LiveAlbumsBucket query(String albumName) {
    final albumNameLowerCase = albumName.toLowerCase();

    return _LiveAlbumBucket(
      this,
      (data, upstream) {
        for (final e in upstream) {
          if (e.album.toLowerCase().startsWith(albumNameLowerCase)) {
            data.add(e);
          }
        }
      },
    );
  }

  @override
  LiveAlbumsBucket queryArtistId(int artistId) => _LiveAlbumBucket(
        this,
        (data, upstream) {
          for (final e in upstream) {
            if (e.artistId == artistId) {
              data.add(e);
            }
          }
        },
      );

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => AlbumBucketNotifier(
        bucket: this,
        count: length,
        child: child,
      ),
    );
  }
}

class _ArtistsBucket extends _StorageBucket<platform.Artist>
    implements ArtistsBucket {
  @override
  LiveArtistsBucket query(String artistName) =>
      _LiveArtistsBucket(this, artistName.toLowerCase());

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => ArtistBucketNotifier(
        bucket: this,
        count: length,
        child: child,
      ),
    );
  }
}

class _TracksBucket extends _StorageBucket<platform.Track>
    implements TracksBucket {
  @override
  LiveTracksBucket query(String trackName) {
    final trackNameLower = trackName.toLowerCase();

    return _LiveTracksBucket(
      this,
      (data, upstream) {
        for (final e in upstream) {
          if (e.name.toLowerCase().startsWith(trackNameLower)) {
            data.add(e);
          }
        }
      },
      null,
    );
  }

  @override
  LiveTracksBucket queryAlbum(platform.Album album) => _LiveTracksBucket(
        this,
        (data, upstream) {
          for (final e in upstream) {
            if (e.albumId == album.albumId) {
              data.add(e);
            }
          }
        },
        album,
      );

  @override
  CombinedLiveTracksBucket queryAlbums(List<platform.Album> albums) =>
      _CombinedLiveTracksBucket(
        this,
        albums,
      );

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _events.stream,
      builder: (context, snapshot) => TrackBucketNotifier(
        bucket: this,
        count: length,
        child: child,
      ),
    );
  }
}

class _StorageDriver implements StorageDriver {
  _StorageDriver();

  @override
  AlbumsBucket albums = _AlbumBucket();

  @override
  ArtistsBucket artists = _ArtistsBucket();

  @override
  TracksBucket tracks = _TracksBucket();

  @override
  Widget inject(Widget child) {
    return albums.inject(
      artists.inject(
        tracks.inject(child),
      ),
    );
  }

  @override
  void dispose() {
    albums.destroy();
    artists.destroy();
    tracks.destroy();
  }
}

extension PlayerStatePlaybackExt on Player {
  void flipIsPlaying(BuildContext context) {
    final isPlaying = PlayerStateQuery.isPlayingOf(context);
    if (isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void flipIsShuffling(BuildContext context) {
    final isShuffling = PlayerStateQuery.isShuffleOf(context);
    _controller.setShuffle(!isShuffling);
  }

  void flipIsLooping(BuildContext context) {
    final isLooping = PlayerStateQuery.loopingOf(context);
    _controller.setLooping(
      switch (isLooping) {
        platform.LoopingState.off => platform.LoopingState.one,
        platform.LoopingState.one => platform.LoopingState.all,
        platform.LoopingState.all => platform.LoopingState.off,
      },
    );
  }

  void changeOrPlay(BuildContext context, platform.Track track, int idx) {
    if (track.id != queue.currentTrack?.id) {
      queue.setAt(idx);
    } else {
      flipIsPlaying(context);
    }
  }
}

abstract interface class Player {
  void toNext();
  void toPrevious();

  QueueList get queue;

  void restore(platform.RestoredData data);

  Widget inject(Widget child);

  static Player of(BuildContext context) => PlayerManager.of(context).player;

  void dispose();
}

class PlayerStateQuery extends InheritedModel<_PlayerStateQueryAspect> {
  const PlayerStateQuery({
    required this.isShuffling,
    required this.looping,
    required this.progress,
    required this.isPlaying,
    required super.child,
  });

  final platform.LoopingState looping;
  final Duration progress;
  final bool isPlaying;
  final bool isShuffling;

  static Duration progressOf(BuildContext context) {
    final widget = InheritedModel.inheritFrom<PlayerStateQuery>(
      context,
      aspect: _PlayerStateQueryAspect.progress,
    );

    return widget!.progress;
  }

  static platform.LoopingState loopingOf(BuildContext context) {
    final widget = InheritedModel.inheritFrom<PlayerStateQuery>(
      context,
      aspect: _PlayerStateQueryAspect.looping,
    );

    return widget!.looping;
  }

  static bool isPlayingOf(BuildContext context) {
    final widget = InheritedModel.inheritFrom<PlayerStateQuery>(
      context,
      aspect: _PlayerStateQueryAspect.playback,
    );

    return widget!.isPlaying;
  }

  static bool isShuffleOf(BuildContext context) {
    final widget = InheritedModel.inheritFrom<PlayerStateQuery>(
      context,
      aspect: _PlayerStateQueryAspect.shuffle,
    );

    return widget!.isShuffling;
  }

  @override
  bool updateShouldNotify(PlayerStateQuery oldWidget) {
    return looping != oldWidget.looping ||
        progress != oldWidget.progress ||
        isPlaying != oldWidget.isPlaying ||
        isShuffling != oldWidget.isShuffling;
  }

  @override
  bool updateShouldNotifyDependent(
    PlayerStateQuery oldWidget,
    Set<_PlayerStateQueryAspect> dependencies,
  ) {
    return (looping != oldWidget.looping &&
            dependencies.contains(_PlayerStateQueryAspect.looping)) ||
        (progress != oldWidget.progress &&
            dependencies.contains(_PlayerStateQueryAspect.progress)) ||
        (isPlaying != oldWidget.isPlaying &&
            dependencies.contains(_PlayerStateQueryAspect.playback)) ||
        (isShuffling != oldWidget.isShuffling &&
            dependencies.contains(_PlayerStateQueryAspect.shuffle));
  }
}

enum _PlayerStateQueryAspect {
  playback,
  progress,
  shuffle,
  looping;
}

class _PlayerStateHolder extends StatefulWidget {
  const _PlayerStateHolder({
    // super.key,
    required this.stream,
    required this.restoredData,
    required this.child,
  });

  final platform.RestoredData? restoredData;
  final Stream<PlaybackEvent> stream;
  final Widget child;

  @override
  State<_PlayerStateHolder> createState() => __PlayerStateHolderState();
}

class __PlayerStateHolderState extends State<_PlayerStateHolder> {
  late final StreamSubscription<PlaybackEvent> events;

  bool isPlaying = false;
  platform.LoopingState looping = platform.LoopingState.off;
  Duration progress = Duration.zero;
  bool shuffleEnabled = false;

  @override
  void initState() {
    super.initState();

    if (widget.restoredData != null) {
      isPlaying = widget.restoredData!.isPlaying;
      looping = widget.restoredData!.looping;
      progress = Duration(milliseconds: widget.restoredData!.progress);
    }

    events = widget.stream.listen((e) {
      switch (e) {
        case Looping():
          looping = e.looping;
        case Seek():
          progress = Duration(milliseconds: e.duration);
        case Playing():
          isPlaying = e.playing;
        case Shuffle():
          shuffleEnabled = e.shuffle;
        case TrackChange():
          return;
        case EnsureData():
          isPlaying = e.data.isPlaying;
          shuffleEnabled = e.data.shuffle;
          progress = Duration(milliseconds: e.data.progress);
          looping = e.data.looping;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerStateQuery(
      isPlaying: isPlaying,
      progress: progress,
      isShuffling: shuffleEnabled,
      looping: looping,
      child: widget.child,
    );
  }
}

abstract interface class QueueList extends Iterable<platform.Track>
    implements platform.Queue {
  platform.Track? get currentTrack;
  platform.Track? get nextTrack;

  platform.Track operator [](int id);
  void operator []=(int id, platform.Track track);

  int currentTrackIdx();

  void clearAndPlay(List<platform.Track> tracks);
  void clearStop();
  void add(platform.Track track);
  void addAll(List<platform.Track> tracks);
  void removeAt(int idx);
  void setAt(int idx);
  void removeTrack(platform.Track track);
  void shiftTracks(platform.Track from, platform.Track to);
  void shiftIndex(int i1, int i2);

  bool containsTrack(platform.Track track);

  Widget inject(Widget child);

  static QueueList of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<QueueListNotifier>();

    return widget!.queueList;
  }

  static QueueList _getOf(BuildContext context) {
    final widget = context.getInheritedWidgetOfExactType<QueueListNotifier>();

    return widget!.queueList;
  }

  static void clearAndPlayOf(
    BuildContext context,
    List<platform.Track> tracks,
  ) =>
      _getOf(context).clearAndPlay(tracks);

  static void addOf(BuildContext context, platform.Track track) =>
      _getOf(context).add(track);

  static void addAllOf(BuildContext context, List<platform.Track> tracks) =>
      _getOf(context).addAll(tracks);

  static void removeAtOf(BuildContext context, int idx) =>
      _getOf(context).removeAt(idx);

  static void clearStopOf(BuildContext context) => _getOf(context).clearStop();

  @override
  platform.Track? current() => currentTrack;

  @override
  platform.Track? nextFromCurrent() => nextTrack;

  @override
  platform.Track? byId(int id) => firstWhere((e) => e.id == id);

  @override
  void ensureQueueClear() => clearStop();
}

@immutable
sealed class PlaybackEvent {
  const PlaybackEvent();
}

class Looping implements PlaybackEvent {
  const Looping(this.looping);

  final platform.LoopingState looping;
}

class Shuffle implements PlaybackEvent {
  const Shuffle(this.shuffle);

  final bool shuffle;
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

class EnsureData implements PlaybackEvent {
  const EnsureData(this.data);

  final platform.AllEvents data;
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
  final _map = <int, void>{};

  @override
  platform.Track operator [](int idx) => order[idx];

  @override
  void operator []=(int id, platform.Track track) {
    add(track);
  }

  @override
  Iterator<platform.Track> get iterator => order.iterator;

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
  int currentTrackIdx() {
    if (currentTrack == null) {
      return 0;
    }

    return order.indexWhere((e) => e.id == currentTrack!.id);
  }

  @override
  void ensureCurrentTrack(platform.Track? track) {
    if (track?.id != currentTrack?.id) {
      currentTrack = track;
      _stream.add(order.length);
    }
  }

  @override
  bool containsTrack(platform.Track track) => _map.containsKey(track.id);

  @override
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _stream.stream,
      builder: (context, snapshot) => QueueListNotifier(
        queueList: this,
        count: order.length,
        currentTrack: currentTrack,
        child: child,
      ),
    );
  }

  @override
  void add(platform.Track track) {
    if (order.isEmpty) {
      clearAndPlay([track]);
    }

    if (_map.containsKey(track.id)) {
      return;
    }

    order.add(track);
    _stream.add(order.length);
    _controller.addTrack(track.id);
    _map[track.id] = null;
  }

  @override
  void addAll(List<platform.Track> tracks, [bool set = false]) {
    final actualTracks = <platform.Track>[];

    for (final e in tracks) {
      if (_map.containsKey(e.id)) {
        continue;
      }

      _map[e.id] = null;
      order.add(e);
      actualTracks.add(e);
    }

    _stream.add(order.length);
    if (set) {
      _controller.setTracks(actualTracks);
    } else {
      _controller.addTracks(actualTracks);
    }
  }

  @override
  void clearAndPlay(List<platform.Track> tracks) {
    _map.clear();
    order.clear();

    addAll(tracks, true);
  }

  @override
  void clearStop() {
    _map.clear();
    order.clear();

    _stream.add(order.length);
    _controller.clearStop();
    currentTrack = null;
  }

  @override
  void removeAt(int idx) {
    _controller.removeTrack(idx);
    final e = order.removeAt(idx);
    _map.remove(e.id);
    _stream.add(order.length);

    if (order.isEmpty) {
      currentTrack = null;
    }
  }

  @override
  void removeTrack(platform.Track track) {
    final idx = order.indexWhere((e) => e.id == track.id);
    if (idx == -1) {
      return;
    }

    removeAt(idx);
  }

  @override
  void setAt(int idx) {
    _controller.setIndex(idx);
    _stream.add(order.length);
  }

  @override
  void shiftTracks(platform.Track from, platform.Track to) {
    final idx1 = order.indexWhere((e) => e.id == from.id);
    final idx2 = order.indexWhere((e) => e.id == to.id);

    if (idx1 == -1 || idx2 == -1) {
      return;
    }

    shiftIndex(idx1, idx2);
  }

  @override
  void shiftIndex(int i1, int i2) {
    final e1 = order.removeAt(i1);
    order.insert(i2, e1);
    _stream.add(order.length);

    _controller.swapIndexes(i1, i2);
  }

  void dispose() {
    order.clear();
    _stream.close();
  }
}

class PlaybackEventsImpl implements platform.PlaybackEvents, Player {
  PlaybackEventsImpl() {
    queue = _QueueList(this);
  }

  platform.RestoredData? restoredData;

  @override
  late final _QueueList queue;

  final _events = StreamController<PlaybackEvent>.broadcast();

  @override
  void toNext() {
    _controller.next();
  }

  @override
  void toPrevious() {
    _controller.prev();
  }

  @override
  void restore(platform.RestoredData data) {
    restoredData = data;
    queue.order.clear();
    queue.order.addAll(data.queue);
    queue.currentTrack = data.currentTrack;
  }

  @override
  void addLooping(platform.LoopingState looping) {
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
  void addShuffle(bool shuffle) {
    _events.add(Shuffle(shuffle));
  }

  @override
  void addTrackChange(platform.Track? track) {
    _events.add(TrackChange(track));
    queue.currentTrack = track;
    queue._stream.add(queue.order.length);
  }

  @override
  void addState(platform.AllEvents events) {
    _events.add(EnsureData(events));
  }

  @override
  Widget inject(Widget child) {
    return _PlayerStateHolder(
      restoredData: restoredData,
      stream: _events.stream,
      child: queue.inject(child),
    );
  }

  @override
  void dispose() {
    _events.close();
    queue.dispose();
  }
}
