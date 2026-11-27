package com.niusic.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

/** Second home screen widget. Shows the first four playlists. */
class NiusicPlaylistsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val names = (1..4).map { index ->
            prefs.getString("flutter.widget_playlist_$index", null) ?: "Niusic"
        }
        val ids = listOf(
            R.id.widget_playlist_1,
            R.id.widget_playlist_2,
            R.id.widget_playlist_3,
            R.id.widget_playlist_4
        )
        val open = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_playlists)
            for (i in ids.indices) {
                views.setTextViewText(ids[i], names[i])
                views.setOnClickPendingIntent(
                    ids[i],
                    pendingIntent(context, i + 11, open)
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun pendingIntent(context: Context, requestCode: Int, intent: Intent): PendingIntent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        }
    }
}
