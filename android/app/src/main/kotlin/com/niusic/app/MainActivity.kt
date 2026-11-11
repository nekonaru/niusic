package com.niusic.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

/**
 * Handles the widget update channel. The Flutter side calls `update` to push
 * SharedPreferences and request the widget views to rebind.
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "niusic/widget"
    private val permissionChannel = "niusic/permission"

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
    }
}
