package com.niusic.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.KeyEvent
import android.widget.RemoteViews

/** Home screen widget. Shows the current track and sends media buttons to the audio service. */
class NiusicWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val title = prefs.getString("flutter.widget_title", null) ?: "Niusic"
        val artist = prefs.getString("flutter.widget_artist", null) ?: "Tap to open"
        val playing = prefs.getString("flutter.widget_playing", "false") == "true"

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_niusic)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_artist, artist)
            views.setImageViewResource(
                R.id.widget_button_play,
                if (playing) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            )

            // Open the app when the user taps the header area.
            val open = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            views.setOnClickPendingIntent(
                R.id.widget_title,
                activityPendingIntent(context, 1, open)
            )
            views.setOnClickPendingIntent(
                R.id.widget_album,
                activityPendingIntent(context, 2, open)
            )

            views.setOnClickPendingIntent(
                R.id.widget_button_prev,
                mediaButtonPendingIntent(context, 3, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
            )
            views.setOnClickPendingIntent(
                R.id.widget_button_play,
                mediaButtonPendingIntent(context, 4, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
            )
            views.setOnClickPendingIntent(
                R.id.widget_button_next,
                mediaButtonPendingIntent(context, 5, KeyEvent.KEYCODE_MEDIA_NEXT)
            )

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun mediaButtonPendingIntent(
        context: Context,
        requestCode: Int,
        keyCode: Int
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setPackage(context.packageName)
            setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        return broadcastPendingIntent(context, requestCode, intent)
    }

    private fun activityPendingIntent(context: Context, requestCode: Int, intent: Intent): PendingIntent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            @Suppress("DEPRECATION")
            PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        }
    }

    private fun broadcastPendingIntent(
        context: Context,
        requestCode: Int,
        intent: Intent
    ): PendingIntent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            @Suppress("DEPRECATION")
            PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        }
    }
}
