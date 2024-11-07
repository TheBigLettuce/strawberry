package com.github.thebiglettuce.strawberry

import android.content.ContentResolver
import android.content.Context
import android.os.Bundle
import android.provider.MediaStore
import okio.use

class MediaLoader {
    fun loadTracksAlbums(context: Context, albumIds: List<Int>) {
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
        )

        val values = Bundle().apply {
            putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection.toString())
            putStringArray(
                ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
                selectionArgs,
            )
            putString(
                ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                "COLLATE LOCALIZED ${MediaStore.Audio.Media.ALBUM} DESC"
            )
        }

        context.contentResolver.query(
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            values,
            null
        )?.use {

        }
    }

    fun loadArtists(context: Context) {
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
                "COLLATE LOCALIZED ${MediaStore.Audio.ArtistColumns.ARTIST} ASC"
            )
        }

        context.contentResolver.query(
            MediaStore.Audio.Artists.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            values,
            null
        )?.use {

        }
    }

    fun loadAlbums(context: Context) {
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
                "COLLATE LOCALIZED ${MediaStore.Audio.AudioColumns.YEAR} DESC"
            )
        }

        context.contentResolver.query(
            MediaStore.Audio.Albums.getContentUri(MediaStore.VOLUME_EXTERNAL),
            projection,
            values,
            null
        )?.use {

        }
    }
}