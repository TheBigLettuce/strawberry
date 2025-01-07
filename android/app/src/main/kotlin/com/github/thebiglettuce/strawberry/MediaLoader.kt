package com.github.thebiglettuce.strawberry

import android.content.ContentResolver
import android.content.Context
import android.os.Bundle
import android.provider.MediaStore
import androidx.core.database.getStringOrNull
import com.github.thebiglettuce.strawberry.generated.Album
import com.github.thebiglettuce.strawberry.generated.Artist
import com.github.thebiglettuce.strawberry.generated.Track
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import okio.use

class MediaLoader(private val context: Context) {
    private val coScope: CoroutineScope = CoroutineScope(Dispatchers.IO)

    fun loadTracksAlbums(albumIds: List<Int>, callback: suspend (List<Track>) -> Unit) {
        coScope.launch {
            val selection =
                if (albumIds.isEmpty()) StringBuilder() else StringBuilder("${MediaStore.Audio.Media.ALBUM_ID} = ?")
            if (albumIds.size > 1) {
                for (e in albumIds.subList(1, albumIds.size)) {
                    selection.append(" OR ${MediaStore.Audio.Media.ALBUM_ID} = ?")
                }
            }
            val selectionArgs = arrayOfNulls<String>(albumIds.size)
            albumIds.forEachIndexed { index, s -> selectionArgs[index] = s.toString() }

            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.ALBUM_ID,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.ALBUM_ARTIST,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.DATE_MODIFIED,
                MediaStore.Audio.Media.TRACK,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.DISC_NUMBER,
                MediaStore.Audio.Media.TITLE,
            )

            val values = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection.toString())
                putStringArray(
                    ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                    selectionArgs,
                )
                putString(
                    ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                    "${MediaStore.Audio.Media.ALBUM} DESC"
                )
            }

            context.contentResolver.query(
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
                projection,
                values,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use
                }

                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
                val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val albumArtistCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ARTIST)
                val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val dateModifiedCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
                val trackCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
                val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val discNumberCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISC_NUMBER)
                val displayNameCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)

                val list = mutableListOf<Track>()

                do {
                    if (list.count() > 100) {
                        callback(list.toList())
                        list.clear()
                    }

                    list.add(
                        Track(
                            id = cursor.getLong(idCol),
                            albumId = cursor.getLong(albumIdCol),
                            album = cursor.getString(albumCol),
                            albumArtist = cursor.getStringOrNull(albumArtistCol) ?: "",
                            artist = cursor.getString(artistCol),
                            dateModified = cursor.getLong(dateModifiedCol),
                            track = cursor.getLong(trackCol),
                            duration = cursor.getLong(durationCol),
                            discNumber = cursor.getLong(discNumberCol),
                            name = cursor.getString(displayNameCol)
                        )
                    )
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    callback(list)
                }
            }

            callback(listOf())
        }
    }

    fun loadArtists(callback: suspend (List<Artist>) -> Unit) {
        coScope.launch {
            val selection = ""
            val selectionArgs = arrayOf<String>()

            val projection = arrayOf(
                MediaStore.Audio.Artists._ID,
                MediaStore.Audio.Artists.ARTIST,
                MediaStore.Audio.Artists.NUMBER_OF_ALBUMS,
                MediaStore.Audio.Artists.NUMBER_OF_TRACKS,
            )

            val values = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                putStringArray(
                    ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                    selectionArgs,
                )
                putString(
                    ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                    "${MediaStore.Audio.Artists.ARTIST} ASC"
                )
            }

            context.contentResolver.query(
                MediaStore.Audio.Artists.getContentUri(MediaStore.VOLUME_EXTERNAL),
                projection,
                values,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use
                }

                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists._ID)
                val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.ARTIST)
                val numberOfAlbumsCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_ALBUMS)
                val numberOfTracksCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Artists.NUMBER_OF_TRACKS)

                val list = mutableListOf<Artist>()

                do {
                    if (list.count() > 100) {
                        callback(list.toList())
                        list.clear()
                    }

                    list.add(
                        Artist(
                            id = cursor.getLong(idCol),
                            artist = cursor.getString(artistCol),
                            numberOfAlbums = cursor.getLong(numberOfAlbumsCol),
                            numberOfTracks = cursor.getLong(numberOfTracksCol)
                        )
                    )
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    callback(list)
                }
            }

            callback(listOf())
        }
    }

    fun loadAlbums(callback: suspend (List<Album>) -> Unit) {
        coScope.launch {
            val selection = ""
            val selectionArgs = arrayOf<String>()

            val projection = arrayOf(
                MediaStore.Audio.Albums._ID,
                MediaStore.Audio.Albums.ALBUM,
                MediaStore.Audio.Albums.ALBUM_ID,
                MediaStore.Audio.Albums.ARTIST,
                MediaStore.Audio.Albums.ARTIST_ID,
                MediaStore.Audio.Albums.FIRST_YEAR,
                MediaStore.Audio.Albums.LAST_YEAR,
                MediaStore.Audio.Albums.NUMBER_OF_SONGS,
            )

            val values = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                putStringArray(
                    ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                    selectionArgs,
                )
                putString(
                    ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                    "${MediaStore.Audio.Albums.ALBUM} ASC"
                )
            }

            context.contentResolver.query(
                MediaStore.Audio.Albums.getContentUri(MediaStore.VOLUME_EXTERNAL),
                projection,
                values,
                null
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    return@use
                }

                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums._ID)
                val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM_ID)
                val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM)
                val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ARTIST)
                val artistIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ARTIST_ID)
                val firstYearCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.FIRST_YEAR)
                val lastYearCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.LAST_YEAR)
                val numberOfSongCol =
                    cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.NUMBER_OF_SONGS)

                val list = mutableListOf<Album>()

                do {
                    if (list.count() > 100) {
                        callback(list.toList())
                        list.clear()
                    }

                    list.add(
                        Album(
                            id = cursor.getLong(idCol),
                            artist = cursor.getString(artistCol),
                            album = cursor.getString(albumCol),
                            albumId = cursor.getLong(albumIdCol),
                            artistId = cursor.getLong(artistIdCol),
                            firstYear = cursor.getLong(firstYearCol),
                            secondYear = cursor.getLong(lastYearCol),
                            numberOfSongs = cursor.getLong(numberOfSongCol)
                        )
                    )
                } while (
                    cursor.moveToNext()
                )

                if (list.isNotEmpty()) {
                    callback(list)
                }
            }

            callback(listOf())
        }
    }

    fun dispose() {
        if (coScope.isActive) {
            coScope.cancel()
        }
    }
}