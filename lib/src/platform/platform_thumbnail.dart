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

import "dart:io" as io;
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:strawberry/main.dart";
import "package:strawberry/src/platform/platform.dart";

final _thumbLoadingStatus = <int, Future<String>>{};

Future<String> _loadAlbumThumb(int id) {
  return MediaThumbnails().loadAndCache(id, MediaThumbnailType.album);
}

Future<String> _loadTrackThumb(int id) {
  return MediaThumbnails().loadAndCache(id, MediaThumbnailType.track);
}

class PlatformThumbnailProvider
    extends ImageProvider<PlatformThumbnailProvider> {
  const PlatformThumbnailProvider.album(this.id, this.brightness)
      : loadThumbnail = _loadAlbumThumb;
  // const PlatformThumbnailProvider.track(this.id)
  //     : loadThumbnail = _loadTrackThumb;

  final int id;

  final Brightness brightness;
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
      final image = switch (brightness) {
        Brightness.dark => placeholder_dark,
        Brightness.light => placeholder_light,
      };

      return decode(await ImmutableBuffer.fromUint8List(image));
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

    return other is PlatformThumbnailProvider &&
        other.id == id &&
        other.brightness == brightness;
  }

  @override
  int get hashCode => Object.hash(id, brightness);
}
