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
import android.database.ContentObserver
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.provider.MediaStore
import androidx.annotation.OptIn
import androidx.core.database.getStringOrNull
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.github.thebiglettuce.strawberry.generated.DataNotifications
import com.github.thebiglettuce.strawberry.generated.Track
import io.flutter.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.use

class MediaService : MediaSessionService() {
    private var mediaSession: MediaSession? = null
    private val mux = Mutex()
    private val coScope = CoroutineScope(Dispatchers.IO)

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo,
    ): MediaSession? = mediaSession

    private val mediaStoreUpdates by lazy {
        object : ContentObserver(Handler(mainLooper)) {
            override fun onChange(selfChange: Boolean) {
                this.onChange(selfChange, null)
            }

            override fun onChange(
                selfChange: Boolean, uris: Collection<Uri>,
                flags: Int,
            ) {
                mediaSession?.apply {
                    val itemCount = player.mediaItemCount
                    if (itemCount == 0) {
                        return@apply
                    }

                    val list = mutableListOf<Long>()
                    for (e in 0..<player.mediaItemCount) {
                        list.add(player.getMediaItemAt(e).requestMetadata.extras!!.getLong("id"))
                    }

                    coScope.launch {
                        if (mux.tryLock()) {
                            val tracks = loadTracks(list)

                            CoroutineScope(Dispatchers.Main).launch {
                                for (e in list.withIndex().reversed()) {
                                    if (!tracks.contains(e.value)) {
                                        player.removeMediaItem(e.index)
                                    }
                                }
                            }.join()

                            mux.unlock()
                        }
                    }

                }
            }
        }
    }

    private fun loadTracks(list: List<Long>): Map<Long, Unit> {
        val selection = StringBuilder("${MediaStore.Audio.Media._ID} = ?")
        for (e in 1..<list.size) {
            selection.append(" OR ${MediaStore.Audio.Media._ID} = ?")
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
        )

        val values = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection.toString())
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                list.map { it.toString() }.toTypedArray(),
            )
        }

        val retList = mutableMapOf<Long, Unit>()

        contentResolver.query(
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            values,
            null
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return@use
            }

            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)

            do {
                retList[cursor.getLong(idCol)] = Unit
            } while (
                cursor.moveToNext()
            )
        }

        return retList
    }

    @OptIn(UnstableApi::class)
    override fun onCreate() {
        super.onCreate()

        val player = ExoPlayer.Builder(this)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build(), true
            )
            .setHandleAudioBecomingNoisy(true)
            .build()
        mediaSession = MediaSession.Builder(this, player).build()
//        mediaSession?.apply {
//            setMediaNotificationProvider(
//                DefaultMediaNotificationProvider.Builder(this@MediaService). .build()
//            )
//        }

        contentResolver.registerContentObserver(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            true,
            mediaStoreUpdates
        )
    }

    override fun onDestroy() {
        coScope.cancel()
        contentResolver.unregisterContentObserver(mediaStoreUpdates)

        mediaSession?.run {
            player.release()
            release()
            mediaSession = null
        }

        super.onDestroy()
    }
}