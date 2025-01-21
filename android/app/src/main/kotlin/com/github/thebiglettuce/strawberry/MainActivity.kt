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

import android.content.ComponentName
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.activity.enableEdgeToEdge
import androidx.annotation.OptIn
import androidx.core.view.WindowCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Metadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.github.thebiglettuce.strawberry.generated.AllEvents
import com.github.thebiglettuce.strawberry.generated.DataLoader
import com.github.thebiglettuce.strawberry.generated.DataNotifications
import com.github.thebiglettuce.strawberry.generated.LoopingState
import com.github.thebiglettuce.strawberry.generated.MediaThumbnails
import com.github.thebiglettuce.strawberry.generated.PlaybackController
import com.github.thebiglettuce.strawberry.generated.PlaybackEvents
import com.github.thebiglettuce.strawberry.generated.Queue
import com.github.thebiglettuce.strawberry.generated.RestoredData
import com.github.thebiglettuce.strawberry.generated.Track
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.channels.produce
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

class MainActivity : FlutterActivity() {
    private var player: Player? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var positionUpdater: ReceiveChannel<Long>? = null

    private val loader = MediaLoader(this)

    @OptIn(UnstableApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.attributes.layoutInDisplayCutoutMode =
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        super.onCreate(savedInstanceState)

        PlaybackController.setUp(
            flutterEngine!!.dartExecutor.binaryMessenger,
            PlaybackControllerImpl(
                context.contentResolver,
                Queue(flutterEngine!!.dartExecutor.binaryMessenger)
            ) {
                player
            })

        MediaThumbnails.setUp(
            flutterEngine!!.dartExecutor.binaryMessenger,
            MediaThumbnailsImpl(this)
        )

        DataLoader.setUp(
            flutterEngine!!.dartExecutor.binaryMessenger,
            DataLoaderImpl(
                loader,
                DataNotifications(flutterEngine!!.dartExecutor.binaryMessenger)
            ) {
                controllerFuture?.addListener(
                    {
                        it(
                            Result.success(
                                RestoredData(
                                    looping = player?.repeatMode.run {
                                        return@run when (this) {
                                            Player.REPEAT_MODE_OFF -> LoopingState.OFF
                                            Player.REPEAT_MODE_ONE -> LoopingState.ONE
                                            Player.REPEAT_MODE_ALL -> LoopingState.ALL
                                            else -> LoopingState.OFF
                                        }
                                    },
                                    isPlaying = player?.isPlaying ?: false,
                                    currentTrack = player?.currentMediaItem?.run {
                                        return@run trackFromMediaItem(this)
                                    },
                                    progress = player?.currentPosition ?: 0L,
                                    queue = player?.run {
                                        val ret = mutableListOf<Track>()
                                        var count = mediaItemCount
                                        var pos = 0
                                        if (count == 0) {
                                            return@run ret
                                        }
                                        while (count > 0) {
                                            ret.add(trackFromMediaItem(getMediaItemAt(pos)))
                                            pos += 1
                                            count -= 1
                                        }

                                        return@run ret
                                    } ?: listOf(),
                                    isShuffling = player?.shuffleModeEnabled ?: false
                                ),
                            ))
                    },
                    MoreExecutors.directExecutor(),
                )
            }
        )
    }

    override fun onDestroy() {
        PlaybackController.setUp(flutterEngine!!.dartExecutor.binaryMessenger, null)
        DataLoader.setUp(flutterEngine!!.dartExecutor.binaryMessenger, null)
        MediaThumbnails.setUp(flutterEngine!!.dartExecutor.binaryMessenger, null)

        suspendPositionUpdates()

        super.onDestroy()

        loader.dispose()
    }

    override fun onStart() {
        super.onStart()

        val sessionToken = SessionToken(this, ComponentName(this, MediaService::class.java))
        controllerFuture = MediaController.Builder(this, sessionToken).buildAsync()
        controllerFuture?.addListener(
            {
                player = controllerFuture?.get()?.apply {
//                    playWhenReady = true

                    val queue = Queue(flutterEngine!!.dartExecutor.binaryMessenger)
                    val events = PlaybackEvents(flutterEngine!!.dartExecutor.binaryMessenger)

                    val mediaItem = currentMediaItem

                    events.addState(
                        AllEvents(
                            isPlaying = isPlaying,
                            progress = currentPosition,
                            looping = playerRepeatToLooping(repeatMode),
                            shuffle = shuffleModeEnabled,
                        )
                    ) {}

                    queue.ensureCurrentTrack(
                        if (mediaItem == null) null else trackFromMediaItem(
                            mediaItem
                        )
                    ) {}

                    if (mediaItemCount == 0) {
                        queue.ensureQueueClear { }
                    }

                    if (isPlaying) {
                        watchPositionUpdates(events)
                    }
                }
                player?.addListener(
                    PlayerEventsListener(
                        PlaybackEvents(flutterEngine!!.dartExecutor.binaryMessenger),
                        ::watchPositionUpdates,
                        ::suspendPositionUpdates,
                    )
                )
            },
            MoreExecutors.directExecutor(),
        )
    }

    override fun onStop() {
        controllerFuture?.let {
            MediaController.releaseFuture(it)
            controllerFuture = null
        }
        player?.let {
            it.release()
            player = null
        }
        suspendPositionUpdates()

        super.onStop()
    }


    @kotlin.OptIn(ExperimentalCoroutinesApi::class)
    fun watchPositionUpdates(events: PlaybackEvents) {
        positionUpdater?.cancel()
        positionUpdater = CoroutineScope(Dispatchers.IO).produce {
            while (true) {
                CoroutineScope(Dispatchers.Main).launch {
                    events.addSeek(player?.currentPosition ?: 0) {

                    }
                }
                delay(1.seconds)
            }
        }
    }

    private fun suspendPositionUpdates() {
        positionUpdater?.cancel()
        positionUpdater = null
    }
}

class PlayerEventsListener(
    private val events: PlaybackEvents,
    private val watchPositionUpdates: (events: PlaybackEvents) -> Unit,
    private val suspendPositionUpdates: () -> Unit,
) : Player.Listener {
    override fun onEvents(player: Player, events: Player.Events) {
        super.onEvents(player, events)
        if (events.contains(Player.EVENT_CUES)) {
            Log.i("PlayerEvents.events", "cues")
        }

        if (events.contains(Player.EVENT_METADATA)) {
            Log.i("PlayerEvents.events", "metadata")
        }

        if (events.contains(Player.EVENT_TRACKS_CHANGED)) {
            Log.i("PlayerEvents.events", "tracks_changed")
        }

        if (events.contains(Player.EVENT_IS_LOADING_CHANGED)) {
            Log.i("PlayerEvents.events", "loading_changed")
        }

        if (events.contains(Player.EVENT_AUDIO_SESSION_ID)) {
            Log.i("PlayerEvents.events", "audio_session_id")
        }

        if (events.contains(Player.EVENT_MEDIA_METADATA_CHANGED)) {
            Log.i("PlayerEvents.events", "media_metadata_changed")
        }

//        if (events.contains(Player.EVENT_)) {
//            Log.i("PlayerEvents.events")
//        }
    }

    override fun onPlayerError(error: PlaybackException) {
        super.onPlayerError(error)
        Log.e("PlayerEvents.error", error.message.toString(), error)
    }

    override fun onPlayerErrorChanged(error: PlaybackException?) {
        super.onPlayerErrorChanged(error)
        Log.e("PlayerEvents.errorChanged", error?.message.toString(), error)
    }

    override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
        super.onShuffleModeEnabledChanged(shuffleModeEnabled)

        events.addShuffle(shuffleModeEnabled) {}
    }

    @OptIn(UnstableApi::class)
    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        super.onMediaItemTransition(mediaItem, reason)
        events.addTrackChange(
            if (mediaItem == null) null else trackFromMediaItem(mediaItem)
        ) {}

        Log.i("PlayerEvents.mediaTransition", mediaItem?.mediaMetadata?.displayTitle.toString())
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        super.onIsPlayingChanged(isPlaying)
        events.addPlaying(isPlaying) {}

        if (isPlaying) {
            watchPositionUpdates(events)
        } else {
            suspendPositionUpdates()
        }

        Log.i("PlayerEvents.playingChanged", isPlaying.toString())
    }

    override fun onRepeatModeChanged(repeatMode: Int) {
        super.onRepeatModeChanged(repeatMode)
        events.addLooping(playerRepeatToLooping(repeatMode)) {}

        Log.i("PlayerEvents.repeatMode", Player.REPEAT_MODE_ALL.toString())
    }

    override fun onPositionDiscontinuity(
        oldPosition: Player.PositionInfo,
        newPosition: Player.PositionInfo,
        reason: Int,
    ) {
        super.onPositionDiscontinuity(oldPosition, newPosition, reason)
        events.addSeek(newPosition.positionMs) {}

        Log.i("PlayerEvents.positionDiscontinuity", newPosition.positionMs.toString())
    }
}

private fun playerRepeatToLooping(repeatMode: Int): LoopingState = when (repeatMode) {
    Player.REPEAT_MODE_OFF -> LoopingState.OFF
    Player.REPEAT_MODE_ONE -> LoopingState.ONE
    Player.REPEAT_MODE_ALL -> LoopingState.ALL
    else -> LoopingState.OFF
}

@OptIn(UnstableApi::class)
fun trackFromMediaItem(mediaItem: MediaItem): Track = Track(
    track = mediaItem.mediaMetadata.trackNumber?.toLong() ?: 0L,
    discNumber = mediaItem.mediaMetadata.discNumber?.toLong() ?: 0L,
    artist = mediaItem.mediaMetadata.artist?.toString() ?: "",
    album = mediaItem.mediaMetadata.albumTitle?.toString() ?: "",
    albumArtist = mediaItem.mediaMetadata.albumArtist?.toString() ?: "",
    name = mediaItem.mediaMetadata.title?.toString() ?: "",
    duration = mediaItem.mediaMetadata.durationMs ?: 0L,
    id = mediaItem.requestMetadata.extras!!.getLong("id"),
    albumId = mediaItem.requestMetadata.extras!!.getLong("albumId"),
    dateModified = mediaItem.requestMetadata.extras!!.getLong("dateModified"),
)
