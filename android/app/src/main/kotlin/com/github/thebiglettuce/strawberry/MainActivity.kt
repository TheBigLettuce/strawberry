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
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.github.thebiglettuce.strawberry.generated.DataLoader
import com.github.thebiglettuce.strawberry.generated.DataNotifications
import com.github.thebiglettuce.strawberry.generated.PlaybackController
import com.github.thebiglettuce.strawberry.generated.PlaybackEvents
import com.github.thebiglettuce.strawberry.generated.Queue
import com.github.thebiglettuce.strawberry.generated.Track
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterActivity() {
    private var player: Player? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null

    private val loader = MediaLoader(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.attributes.layoutInDisplayCutoutMode =
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        super.onCreate(savedInstanceState)

        PlaybackController.setUp(
            flutterEngine!!.dartExecutor.binaryMessenger,
            PlaybackControllerImpl(Queue(flutterEngine!!.dartExecutor.binaryMessenger)) {
                player
            })

        DataLoader.setUp(
            flutterEngine!!.dartExecutor.binaryMessenger,
            DataLoaderImpl(loader, DataNotifications(flutterEngine!!.dartExecutor.binaryMessenger))
        )
    }

    override fun onDestroy() {
        PlaybackController.setUp(flutterEngine!!.dartExecutor.binaryMessenger, null)
        DataLoader.setUp(flutterEngine!!.dartExecutor.binaryMessenger, null);

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
                    playWhenReady = true
                }
                player?.addListener(PlayerEventsListener(PlaybackEvents(flutterEngine!!.dartExecutor.binaryMessenger)))
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

        super.onStop()
    }
}

class PlayerEventsListener(private val events: PlaybackEvents) : Player.Listener {
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

    @OptIn(UnstableApi::class)
    override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        super.onMediaItemTransition(mediaItem, reason)
        events.addTrackChange(
            if (mediaItem == null) null else Track(
                track = mediaItem.mediaMetadata.trackNumber?.toLong() ?: 0L,
                discNumber = mediaItem.mediaMetadata.discNumber?.toLong() ?: 0L,
                duration = mediaItem.mediaMetadata.durationMs ?: 0L,
                artist = mediaItem.mediaMetadata.artist?.toString() ?: "",
                album = mediaItem.mediaMetadata.albumTitle?.toString() ?: "",
                albumArtist = mediaItem.mediaMetadata.albumArtist?.toString() ?: "",
                name = mediaItem.mediaMetadata.displayTitle?.toString() ?: "",
                id = mediaItem.requestMetadata.extras!!.getLong("id"),
                albumId = mediaItem.requestMetadata.extras!!.getLong("albumId"),
                dateModified = mediaItem.requestMetadata.extras!!.getLong("dateModified"),
            )
        ) {}

        Log.i("PlayerEvents.mediaTransition", mediaItem?.mediaMetadata?.displayTitle.toString())
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        super.onIsPlayingChanged(isPlaying)
        events.addPlaying(isPlaying) {}

        Log.i("PlayerEvents.playingChanged", isPlaying.toString())
    }

    override fun onRepeatModeChanged(repeatMode: Int) {
        super.onRepeatModeChanged(repeatMode)
        if (repeatMode == Player.REPEAT_MODE_ALL) {
            events.addLooping(true) {}
        } else if (repeatMode == Player.REPEAT_MODE_OFF) {
            events.addLooping(false) {}
        }

        Log.i("PlayerEvents.repeatMode", (repeatMode == Player.REPEAT_MODE_ALL).toString())
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