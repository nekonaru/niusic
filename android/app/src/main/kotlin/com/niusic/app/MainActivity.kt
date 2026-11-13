package com.niusic.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * Handles the widget update channel, the notification permission channel, and
 * the device music scanner. The scanner queries MediaStore for on-device
 * audio files and emits an event whenever the audio MediaStore changes so a
 * running app can pick up new files in real time.
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "niusic/widget"
    private val permissionChannel = "niusic/permission"
    private val scannerChannel = "niusic/scanner"
    private val scannerEventsChannel = "niusic/scanner_events"

    private var audioObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        val ids = manager.getAppWidgetIds(
                            ComponentName(this, NiusicWidgetProvider::class.java)
                        )
                        val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                            component = ComponentName(this@MainActivity, NiusicWidgetProvider::class.java)
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                        }
                        sendBroadcast(intent)
                        result.success(ids.size)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "areNotificationsGranted" -> {
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                                PackageManager.PERMISSION_GRANTED
                        )
                    }
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            requestPermissions(
                                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                                1001
                            )
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, scannerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "areScanGranted" -> result.success(areScanGranted())
                    "requestScanPermission" -> {
                        if (areScanGranted()) {
                            result.success(true)
                        } else {
                            requestPermissions(arrayOf(audioPermission()), 1002)
                            result.success(false)
                        }
                    }
                    "scanLibrary" -> {
                        try {
                            result.success(scanLibrary())
                        } catch (e: Exception) {
                            result.error("scan_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, scannerEventsChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    if (audioObserver != null) {
                        return
                    }
                    audioObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                        override fun onChange(selfChange: Boolean) {
                            events.success("changed")
                        }

                        override fun onChange(selfChange: Boolean, uri: Uri?) {
                            events.success("changed")
                        }
                    }
                    contentResolver.registerContentObserver(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        true,
                        audioObserver!!
                    )
                }

                override fun onCancel(arguments: Any?) {
                    audioObserver?.let { contentResolver.unregisterContentObserver(it) }
                    audioObserver = null
                }
            })
    }

    private fun audioPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            android.Manifest.permission.READ_MEDIA_AUDIO
        } else {
            android.Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun areScanGranted(): Boolean {
        return checkSelfPermission(audioPermission()) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Queries every on-device audio file that the MediaStore marks as music.
     * Returns maps with path, title, artist, display name and duration in
     * milliseconds. Runs on the calling thread; callers should keep the result
     * set small enough to avoid blocking the UI.
     */
    private fun scanLibrary(): List<Map<String, Any?>> {
        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.DURATION
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        val out = ArrayList<Map<String, Any?>>()
        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )?.use { cursor ->
            val pathCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            while (cursor.moveToNext()) {
                val path = cursor.getString(pathCol) ?: continue
                // Skip empty paths; some cloud-only entries have no local file.
                if (path.isBlank()) {
                    continue
                }
                val title = cursor.getString(titleCol)?.trim().orEmpty()
                val artist = cursor.getString(artistCol)?.trim().orEmpty()
                out.add(
                    mapOf(
                        "path" to path,
                        "name" to (cursor.getString(nameCol)?.trim() ?: ""),
                        "title" to title,
                        "artist" to artist,
                        "duration" to cursor.getLong(durationCol)
                    )
                )
            }
        }
        return out
    }
}
