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
        MediaThumbnailType,
        MediaThumbnails,
        PlaybackEvents,
        Queue,
        Track;

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
    required super.child,
  });

  final QueueList queueList;
  final int count;

  @override
  bool updateShouldNotify(QueueListNotifier oldWidget) {
    return count != oldWidget.count || queueList != oldWidget.queueList;
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

sealed class AlbumsBucket extends StorageBucket<platform.Album> {
  static AlbumsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AlbumBucketNotifier>();

    return widget!.bucket;
  }
}

sealed class ArtistsBucket extends StorageBucket<platform.Artist> {
  static ArtistsBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ArtistBucketNotifier>();

    return widget!.bucket;
  }
}

sealed class TracksBucket extends StorageBucket<platform.Track> {
  static TracksBucket of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<TrackBucketNotifier>();

    return widget!.bucket;
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
  String _generation = "";
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

  @override
  void destroy() {
    storage.clear();
    _events.close();
  }
}

class _AlbumBucket extends _StorageBucket<platform.Album>
    implements AlbumsBucket {
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
      controller.pause();
    } else {
      controller.play();
    }
  }

  void flipIsLooping(BuildContext context) {
    final isLooping = PlayerStateQuery.loopingOf(context);
    controller.setLooping(!isLooping);
  }
}

abstract interface class Player {
  platform.PlaybackController get controller;

  QueueList get queue;

  void restore(platform.RestoredData data);

  Widget inject(Widget child);

  static Player of(BuildContext context) => PlayerManager.of(context).player;

  void dispose();
}

class PlayerStateQuery extends InheritedModel<_PlayerStateQueryAspect> {
  const PlayerStateQuery({
    required this.looping,
    required this.progress,
    required this.isPlaying,
    required super.child,
  });

  final bool looping;
  final Duration progress;
  final bool isPlaying;

  static Duration progressOf(BuildContext context) {
    final widget = InheritedModel.inheritFrom<PlayerStateQuery>(
      context,
      aspect: _PlayerStateQueryAspect.progress,
    );

    return widget!.progress;
  }

  static bool loopingOf(BuildContext context) {
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

  @override
  bool updateShouldNotify(PlayerStateQuery oldWidget) {
    return looping != oldWidget.looping ||
        progress != oldWidget.progress ||
        isPlaying != oldWidget.isPlaying;
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
            dependencies.contains(_PlayerStateQueryAspect.playback));
  }
}

enum _PlayerStateQueryAspect {
  playback,
  progress,
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
  bool isLooping = false;
  Duration progress = Duration.zero;

  @override
  void initState() {
    super.initState();

    if (widget.restoredData != null) {
      isPlaying = widget.restoredData!.isPlaying;
      isLooping = widget.restoredData!.isLooping;
      progress = Duration(milliseconds: widget.restoredData!.progress);
    }

    events = widget.stream.listen((e) {
      switch (e) {
        case Looping():
          isLooping = e.looping;
        case Seek():
          progress = Duration(milliseconds: e.duration);
        case Playing():
          isPlaying = e.playing;
        case TrackChange():
          return;
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
      looping: isLooping,
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

  void clearAndPlay(platform.Track track);
  void add(platform.Track track);
  void shiftPositions(platform.Track from, platform.Track to);

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

  static void clearAndPlayOf(BuildContext context, platform.Track track) =>
      _getOf(context).clearAndPlay(track);

  @override
  platform.Track? current() => currentTrack;

  @override
  platform.Track? nextFromCurrent() => nextTrack;

  @override
  platform.Track? byId(int id) => firstWhere((e) => e.id == id);
}

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
  Widget inject(Widget child) {
    return StreamBuilder(
      stream: _stream.stream,
      builder: (context, snapshot) => QueueListNotifier(
        queueList: this,
        count: order.length,
        child: child,
      ),
    );
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
  platform.PlaybackController controller = platform.PlaybackController();

  @override
  void restore(platform.RestoredData data) {
    restoredData = data;
    queue.order.clear();
    queue.order.addAll(data.queue);
    queue.currentTrack = data.currentTrack;
  }

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
