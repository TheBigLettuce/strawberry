package com.github.thebiglettuce.strawberry

import android.content.ComponentName
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.enableEdgeToEdge
import androidx.core.view.WindowCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterActivity() {
    private var player: Player? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)

        window.attributes.layoutInDisplayCutoutMode =
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        super.onStart()

        val sessionToken = SessionToken(this, ComponentName(this, MediaService::class.java))
        controllerFuture = MediaController.Builder(this, sessionToken).buildAsync()
        controllerFuture?.addListener(
            {
                player = controllerFuture?.get();
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
