import "dart:io" as io;
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:strawberry/src/platform/platform.dart";
import "package:transparent_image/transparent_image.dart";

final _thumbLoadingStatus = <int, Future<String>>{};

Future<String> _loadAlbumThumb(int id) {
  return MediaThumbnails().loadAndCache(id, MediaThumbnailType.album);
}

Future<String> _loadTrackThumb(int id) {
  return MediaThumbnails().loadAndCache(id, MediaThumbnailType.track);
}

class PlatformThumbnailProvider
    extends ImageProvider<PlatformThumbnailProvider> {
  const PlatformThumbnailProvider.album(this.id)
      : loadThumbnail = _loadAlbumThumb;
  // const PlatformThumbnailProvider.track(this.id)
  //     : loadThumbnail = _loadTrackThumb;

  final int id;

  final Future<String> Function(int id) loadThumbnail;

  @override
  Future<PlatformThumbnailProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    PlatformThumbnailProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
    );
  }

  Future<Codec> _loadAsync(
    PlatformThumbnailProvider key,
    ImageDecoderCallback decode,
  ) async {
    Future<io.File?> setFile() async {
      final future = _thumbLoadingStatus[id];
      if (future != null) {
        final path = await future;

        if (path.isEmpty) {
          return null;
        }

        return io.File(path);
      }

      _thumbLoadingStatus[id] = _loadAlbumThumb(id).whenComplete(() {
        _thumbLoadingStatus.remove(id);
      });
      final path = await _thumbLoadingStatus[id]!;
      if (path.isEmpty) {
        return null;
      }

      return io.File(path);
    }

    final file = await setFile();
    if (file == null) {
      return decode(await ImmutableBuffer.fromUint8List(kTransparentImage));
    }

    // copied from Flutter source of FileImage

    final int lengthInBytes = await file.length();
    if (lengthInBytes == 0) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError("$file is empty and cannot be loaded as an image.");
    }
    return (file.runtimeType == io.File)
        ? decode(await ImmutableBuffer.fromFilePath(file.path))
        : decode(await ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is PlatformThumbnailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
