package com.github.thebiglettuce.strawberry

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.webkit.MimeTypeMap
import androidx.core.graphics.scale
import androidx.documentfile.provider.DocumentFile
import com.github.thebiglettuce.strawberry.generated.MediaThumbnailType
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import okio.FileSystem
import okio.buffer
import okio.sink
import okio.use
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.Queue
import java.util.SortedSet
import kotlin.io.path.Path
import kotlin.io.path.deleteIfExists
import kotlin.io.path.extension

data class ThumbOp(
    val thumb: Long,
    val type: MediaThumbnailType,
    val callback: ((String) -> Unit),
)

class Thumbnailer(private val context: Context) {
    private val thumbnailsChannel = Channel<ThumbOp>(capacity = CAP)

    private val scope = CoroutineScope(Dispatchers.IO)

    private val locker = CacheLocker(context)

    private var initDone = false

    fun initMover() {
        if (initDone) {
            return
        }

        locker.init()

        scope.launch {
            val inProgress = mutableListOf<Job>()

            for (op in thumbnailsChannel) {
                try {
                    if (inProgress.count() == CAP) {
                        inProgress.first().join()
                        inProgress.removeAt(0)
                    }

                    inProgress.add(launch {
                        var res: String
                        try {
                            val uri = ContentUris.withAppendedId(
                                when (op.type) {
                                    MediaThumbnailType.ALBUM -> MediaStore.Audio.Albums.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL
                                    )

                                    MediaThumbnailType.TRACK -> MediaStore.Audio.Media.getContentUri(
                                        MediaStore.VOLUME_EXTERNAL
                                    )
                                },
                                op.thumb
                            )

                            res = getThumb(CacheLocker.Id(op.thumb, op.type), uri)
                        } catch (e: Exception) {
                            res = ""
                            Log.e("thumbnail coro", e.toString())
                        }

                        op.callback.invoke(res)
                    })
                } catch (e: java.lang.Exception) {
                    Log.e("thumbnails", e.toString())
                }
            }

            for (job in inProgress) {
                job.cancelAndJoin()
            }
            inProgress.clear()
        }

        initDone = true
    }

    fun dispose() {
        thumbnailsChannel.close()
        scope.cancel()
//        uiScope.cancel()
    }

    fun add(thumb: ThumbOp) {
        scope.launch {
            thumbnailsChannel.send(thumb)
        }
    }

//    fun deleteCachedThumbs(thumbs: List<CacheLocker>) {
//        scope.launch {
//            locker.removeAll(thumbs)
//        }
//    }

    fun clearCachedThumbs() {
        scope.launch { locker.clear() }
    }

    fun getCachedThumbnail(
        thumb: CacheLocker.Id,
        callback: (String) -> Unit,
    ) {
        scope.launch {
            val cachedFile = locker.get(thumb)
            if (cachedFile != null) {
                CoroutineScope(Dispatchers.Main).launch {
                    callback(cachedFile)
                }
            } else {
                thumbnailsChannel.send(ThumbOp(thumb.id, thumb.type) { path ->
                    CoroutineScope(Dispatchers.Main).launch {
                        callback(path)
                    }
                })
            }
        }
    }

    fun thumbCacheSize(res: MethodChannel.Result) {
        scope.launch {
            res.success(locker.count())
        }
    }

    private suspend fun getThumb(
        id: CacheLocker.Id,
        uri: Uri,
    ): String {
        if (locker.exist(id)) {
            return ""
        }

        val thumb = context.contentResolver.loadThumbnail(
            uri,
            Size(320, 320),
            null
        )

        val stream = ByteArrayOutputStream()

        thumb.compress(
            Bitmap.CompressFormat.WEBP_LOSSY,
            80,
            stream
        )

        val path = locker.put(stream, id)

        stream.reset()
        thumb.recycle()

        return path ?: ""
    }

    companion object {
        private const val CAP: Int = 4
    }
}

class CacheLocker(private val context: Context) {
    private val mux = Mutex()

    private val aliveFiles = ArrayDeque<String>(200)

    fun init() {
        CoroutineScope(Dispatchers.IO).launch {
            mux.lock()

            try {
                val dir = directoryFile()
                if (dir.exists() && dir.isDirectory) {
                    (dir).walk().forEach { file ->
                        aliveFiles.addLast(file.path)
                    }
                }
            } catch (e: Exception) {
                Log.e("CacheLocker", "init has failed", e)
            }

            mux.unlock()
        }
    }

    suspend fun put(image: ByteArrayOutputStream, id: Id): String? {
        mux.lock()

        var ret: String? = null

        val dir = directoryFile()
        val file = dir.resolve(id.toString())
        try {
            if (!file.exists()) {
                file.writeBytes(image.toByteArray())
                if (aliveFiles.size >= 200) {
                    var c = aliveFiles.size - 199
                    while (c != 0) {
                        val f = aliveFiles.first()
                        Log.i("CacheLocker", "removed ${f}")

                        File(f).delete()
                        c -= 1
                    }
                }
                aliveFiles.addLast(file.path)
            }
            ret = file.absolutePath
        } catch (e: Exception) {
            Log.e("CacheLocker.put", e.toString())
        }

        mux.unlock()

        return ret
    }

//    suspend fun removeAll(ids: List<Id>) {
//        mux.lock()
//
//        try {
//            val dir = directoryFile()
//
//            for (id in ids) {
//                dir.resolve(id.toString()).delete()
//            }
//        } catch (e: Exception) {
//            Log.e("CacheLocker.remove", e.toString())
//        }
//
//        mux.unlock()
//    }

    fun exist(id: Id): Boolean {
        return directoryFile().resolve(id.toString()).exists()
    }

    fun get(id: Id): String? {
        val file = directoryFile().resolve(id.toString())
        if (file.exists()) {
            return file.path
        }

        return null
    }

    suspend fun clear() {
        mux.lock()

        aliveFiles.clear()
        directoryFile().deleteRecursively()

        mux.unlock()
    }

    private fun directoryFile(): File {
        val dir = context.filesDir.resolve(DIRECTORY)
        dir.mkdir()

        return dir
    }

    fun count(): Long {
        val dir = directoryFile()

        if (!dir.exists() || !dir.isDirectory) {
            return 0
        }

        return (dir).walk().sumOf { file ->
            return@sumOf file.length()
        }
    }

    data class Id(val id: Long, val type: MediaThumbnailType) {
        override fun toString(): String {
            return "${type.name}_${id}"
        }
    }

    companion object {
        private const val DIRECTORY = "thumbnailsCache"
        private const val MAX_FILES = 200
    }
}