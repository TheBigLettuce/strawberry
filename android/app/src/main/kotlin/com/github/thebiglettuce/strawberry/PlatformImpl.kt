package com.github.thebiglettuce.strawberry

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
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
import com.github.thebiglettuce.strawberry.generated.MediaThumbnailType
import com.github.thebiglettuce.strawberry.generated.MediaThumbnails
import com.github.thebiglettuce.strawberry.generated.PlaybackController
import com.github.thebiglettuce.strawberry.generated.Queue
import com.github.thebiglettuce.strawberry.generated.RestoredData
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
    private val makeRestoredData: () -> RestoredData,
) :
    DataLoader {
    override fun restore(): RestoredData {
        return makeRestoredData()
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
                    MediaItem.Builder()
                        .setUri(itemUri)
                        .setRequestMetadata(
                            RequestMetadata.Builder()
                                .setExtras(Bundle().apply {
                                    putLong("id", track.id)
                                    putLong("albumId", track.albumId)
                                    putLong("dateModified", track.dateModified)
                                    putLong("duration", track.duration)
                                    putString("name", track.name)
                                })
                                .build()
                        )
                        .build()
                )
                prepare()
            }
        }

        callback(Result.success(Unit))
    }

    override fun setLooping(looping: Boolean, callback: (Result<Unit>) -> Unit) {
        if (looping) {
            player()?.repeatMode = Player.REPEAT_MODE_ALL
        } else {
            player()?.repeatMode = Player.REPEAT_MODE_OFF
        }

        callback(Result.success(Unit))
    }
}
