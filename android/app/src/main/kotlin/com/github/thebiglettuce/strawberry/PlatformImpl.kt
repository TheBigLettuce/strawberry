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

package com.github.thebiglettuce.strawberry

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.media.session.MediaController
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaItem.RequestMetadata
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import com.github.thebiglettuce.strawberry.generated.DataLoader
import com.github.thebiglettuce.strawberry.generated.DataNotifications
import com.github.thebiglettuce.strawberry.generated.LoopingState
import com.github.thebiglettuce.strawberry.generated.MediaThumbnailType
import com.github.thebiglettuce.strawberry.generated.MediaThumbnails
import com.github.thebiglettuce.strawberry.generated.PlaybackController
import com.github.thebiglettuce.strawberry.generated.Queue
import com.github.thebiglettuce.strawberry.generated.RestoredData
import com.github.thebiglettuce.strawberry.generated.Track
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.nio.ByteBuffer

class MediaThumbnailsImpl(private val context: Context) : MediaThumbnails {
    override fun loadAndCache(
        id: Long,
        type: MediaThumbnailType,
        callback: (Result<String>) -> Unit,
    ) {
        val thumbnailer = (context.applicationContext as App).thumbnailer
        thumbnailer.getCachedThumbnail(CacheLocker.Id(id, type)) {
            callback(Result.success(it))
        }
    }
}

class DataLoaderImpl(
    private val loader: MediaLoader,
    private val data: DataNotifications,
    private val makeRestoredData: ((Result<RestoredData>) -> Unit) -> Unit,
) :
    DataLoader {
    override fun restore(callback: (Result<RestoredData>) -> Unit) {
        makeRestoredData(callback)
    }

    override fun startLoadingAlbums(callback: (Result<Unit>) -> Unit) {
        loader.loadAlbums {
            CoroutineScope(Dispatchers.Main).launch {
                data.insertAlbums(it, null) {}
            }.join()
        }
        callback(Result.success(Unit))
    }

    override fun startLoadingTracks(callback: (Result<Unit>) -> Unit) {
        loader.loadTracksAlbums(listOf()) {
            CoroutineScope(Dispatchers.Main).launch {
                data.insertTracks(it, null) {}
            }.join()
        }
        callback(Result.success(Unit))
    }

    override fun startLoadingArtists(callback: (Result<Unit>) -> Unit) {
        loader.loadArtists {
            CoroutineScope(Dispatchers.Main).launch {
                data.insertArtists(it, null) {}
            }.join()
        }
        callback(Result.success(Unit))
    }
}

class PlaybackControllerImpl(
    private val contentResolver: ContentResolver,
    private val queue: Queue,
    private val player: () -> Player?,
) :
    PlaybackController {
    override fun next(callback: (Result<Unit>) -> Unit) {
        player()?.seekToNext()
        callback(Result.success(Unit))
    }

    override fun prev(callback: (Result<Unit>) -> Unit) {
        player()?.seekToPrevious()
        callback(Result.success(Unit))
    }

    override fun seek(sec: Long, callback: (Result<Unit>) -> Unit) {
        player()?.seekTo(sec)
        callback(Result.success(Unit))
    }

    override fun play(callback: (Result<Unit>) -> Unit) {
        player()?.play()
        callback(Result.success(Unit))
    }

    override fun pause(callback: (Result<Unit>) -> Unit) {
        player()?.pause()
        callback(Result.success(Unit))
    }

    @OptIn(UnstableApi::class)
    override fun changeTrack(id: Long, callback: (Result<Unit>) -> Unit) {
        queue.byId(id) { result ->
            val track = result.getOrNull() ?: return@byId

            player()?.apply {
                val itemUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    track.id
                )

                setMediaItem(
                    trackToMediaItem(track, itemUri)
                )
                prepare()
                playWhenReady = true
            }
        }

        callback(Result.success(Unit))
    }

    override fun setIndex(index: Long, callback: (Result<Unit>) -> Unit) {
        player()?.apply {
            if (index != currentMediaItemIndex.toLong()) {
                seekTo(index.toInt(), 0)
                playWhenReady = true
            }
        }

        callback(Result.success(Unit))
    }

    override fun setTracks(tracks: List<Track>, callback: (Result<Unit>) -> Unit) {
        player()?.apply {
            clearMediaItems()
            addMediaItems(tracks.map {
                trackToMediaItem(
                    it, ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        it.id
                    )
                )
            })

            prepare()
            playWhenReady = true
        }

        callback(Result.success(Unit))
    }

    override fun swapIndexes(i1: Long, i2: Long, callback: (Result<Unit>) -> Unit) {
        player()?.moveMediaItem(i1.toInt(), i2.toInt())

        callback(Result.success(Unit))
    }

    override fun addTrack(id: Long, callback: (Result<Unit>) -> Unit) {
        queue.byId(id) { result ->
            val track = result.getOrNull() ?: return@byId

            player()?.apply {
                val itemUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    track.id
                )

                addMediaItem(
                    trackToMediaItem(track, itemUri)
                )
                prepare()
//                if (!isPlaying) {
//                    play()
//                }
            }
        }

        callback(Result.success(Unit))
    }

    override fun addTracks(tracks: List<Track>, callback: (Result<Unit>) -> Unit) {
        player()?.apply {
            addMediaItems(tracks.map {
                trackToMediaItem(
                    it, ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        it.id
                    )
                )
            })

            prepare()
        }

        callback(Result.success(Unit))
    }

    override fun removeTrack(index: Long, callback: (Result<Unit>) -> Unit) {
        player()?.removeMediaItem(index.toInt())

        callback(Result.success(Unit))
    }

    override fun clearStop(callback: (Result<Unit>) -> Unit) {
        player()?.apply {
            pause()
            stop()
            clearMediaItems()
        }

        callback(Result.success(Unit))
    }


    override fun setShuffle(shuffle: Boolean, callback: (Result<Unit>) -> Unit) {
        player()?.apply {
            this.shuffleModeEnabled = shuffle
        }

        callback(Result.success(Unit))
    }

    override fun setLooping(looping: LoopingState, callback: (Result<Unit>) -> Unit) {
        player()?.repeatMode = when (looping) {
            LoopingState.OFF -> Player.REPEAT_MODE_OFF
            LoopingState.ONE -> Player.REPEAT_MODE_ONE
            LoopingState.ALL -> Player.REPEAT_MODE_ALL
        }

        callback(Result.success(Unit))
    }
}

@OptIn(UnstableApi::class)
private fun trackToMediaItem(track: Track, itemUri: Uri): MediaItem = MediaItem.Builder()
    .setMediaMetadata(
        MediaMetadata.Builder()
            .setArtist(track.artist)
            .setTitle(track.name)
            .setTrackNumber(track.track.toInt())
            .setDurationMs(track.duration)
            .setAlbumTitle(track.album)
            .setAlbumArtist(track.albumArtist)
            .setDiscNumber(track.discNumber.toInt())
            .build()
    )
    .setUri(itemUri)
    .setRequestMetadata(
        RequestMetadata.Builder()
            .setExtras(Bundle().apply {
                putLong("id", track.id)
                putLong("albumId", track.albumId)
                putLong("dateModified", track.dateModified)
            })
            .build()
    )
    .build()
