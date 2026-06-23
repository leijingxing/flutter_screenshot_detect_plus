
package com.ss.detect

import android.app.Activity
import android.content.ContentResolver
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

class FlutterScreenshotDetectPlugin: FlutterPlugin, EventChannel.StreamHandler, ActivityAware {
    private var contentResolver: ContentResolver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var screenshotObserver: ContentObserver? = null
    private lateinit var channel: EventChannel
    private var activity: Activity? = null
    private var screenCaptureCallback: Activity.ScreenCaptureCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        contentResolver = binding.applicationContext.contentResolver
        channel = EventChannel(binding.binaryMessenger, "com.ss.detect/events")
        channel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setStreamHandler(null)
        stopListening()
        contentResolver = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (eventSink != null) {
            registerScreenCaptureCallback()
        }
    }

    override fun onDetachedFromActivity() {
        unregisterScreenCaptureCallback()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (eventSink != null) {
            registerScreenCaptureCallback()
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregisterScreenCaptureCallback()
        activity = null
    }

    private fun registerScreenCaptureCallback() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val currentActivity = activity ?: return
            if (eventSink == null) return
            if (screenCaptureCallback == null) {
                val callback = Activity.ScreenCaptureCallback {
                    eventSink?.success(mapOf(
                        "method" to "screen_capture_callback",
                        "timestamp" to currentTimestampMicros()
                    ))
                }
                screenCaptureCallback = callback
                currentActivity.registerScreenCaptureCallback(
                    currentActivity.mainExecutor,
                    callback
                )
            }
        }
    }

    private fun unregisterScreenCaptureCallback() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val currentActivity = activity
            val callback = screenCaptureCallback
            if (currentActivity != null && callback != null) {
                currentActivity.unregisterScreenCaptureCallback(callback)
            }
            screenCaptureCallback = null
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        stopListening()
        eventSink = events

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerScreenCaptureCallback()
            return
        }

        registerContentObserver()
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    private fun registerContentObserver() {
        val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                if (uri == null) return
                // 延迟 500ms 查询，避免系统数据库尚未写入完成导致文件名/路径为空。
                mainHandler.postDelayed({
                    if (eventSink != null && isScreenshotPath(uri)) {
                        eventSink?.success(mapOf(
                            "method" to "content_observer",
                            "timestamp" to currentTimestampMicros(),
                            "path" to uri.toString()
                        ))
                    }
                }, 500)
            }
        }
        screenshotObserver = observer

        contentResolver?.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            observer
        )
    }

    private fun stopListening() {
        mainHandler.removeCallbacksAndMessages(null)
        screenshotObserver?.let {
            contentResolver?.unregisterContentObserver(it)
        }
        unregisterScreenCaptureCallback()
        eventSink = null
        screenshotObserver = null
    }

    private fun isScreenshotPath(uri: Uri): Boolean {
        val lastSegment = uri.lastPathSegment
        val isImageFileChange = uri.toString().contains("external/images/media") &&
            lastSegment != null &&
            lastSegment.toLongOrNull() != null
        if (!isImageFileChange) {
            return false
        }

        val resolver = contentResolver ?: return false
        val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(MediaStore.Images.Media.DISPLAY_NAME, MediaStore.Images.Media.RELATIVE_PATH)
        } else {
            arrayOf(MediaStore.Images.Media.DISPLAY_NAME, MediaStore.Images.Media.DATA)
        }

        return runCatching {
            resolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    false
                } else {
                    val name = cursor.getStringOrEmpty(MediaStore.Images.Media.DISPLAY_NAME)
                    val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        MediaStore.Images.Media.RELATIVE_PATH
                    } else {
                        MediaStore.Images.Media.DATA
                    }
                    val path = cursor.getStringOrEmpty(pathColumn)
                    isScreenshotText(name) || isScreenshotText(path)
                }
            } ?: false
        }.getOrDefault(false)
    }

    private fun Cursor.getStringOrEmpty(columnName: String): String {
        val index = getColumnIndex(columnName)
        if (index < 0 || isNull(index)) {
            return ""
        }
        return getString(index) ?: ""
    }

    private fun isScreenshotText(value: String): Boolean {
        val normalized = value.lowercase()
        return screenshotKeywords.any { normalized.contains(it) }
    }

    private fun currentTimestampMicros(): Long {
        return System.currentTimeMillis() * 1000
    }

    companion object {
        private val screenshotKeywords = listOf(
            "screenshot",
            "screen_shot",
            "screen-shot",
            "screenshots",
            "screen capture",
            "screencapture",
            "截屏",
            "截图",
            "屏幕截图"
        )
    }
}
