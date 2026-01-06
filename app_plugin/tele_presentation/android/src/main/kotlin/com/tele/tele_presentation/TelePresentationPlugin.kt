package com.tele.tele_presentation

import android.content.Context
import android.view.Display
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel

/**
 * Flutter plugin for secondary display detection and management.
 *
 * Provides:
 * - Display detection (secondary/presentation displays)
 * - Display change events via EventChannel
 * - Display information queries
 *
 * Note: This plugin provides the infrastructure for secondary display detection.
 * The actual presentation rendering is done by subclasses of [FlutterPresentation]
 * in the app's native code, since presentations need custom MethodChannel setup.
 */
class TelePresentationPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var displayHelper: DisplayHelper? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "tele_presentation")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "tele_presentation/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "hasSecondaryDisplay" -> {
                val helper = getOrCreateDisplayHelper()
                result.success(helper.hasSecondaryDisplay())
            }
            "getSecondaryDisplay" -> {
                val helper = getOrCreateDisplayHelper()
                val display = helper.getSecondaryDisplay()
                if (display != null) {
                    result.success(displayToMap(display))
                } else {
                    result.success(null)
                }
            }
            "getAllDisplays" -> {
                val helper = getOrCreateDisplayHelper()
                val displays = helper.getAllDisplays().map { displayToMap(it) }
                result.success(displays)
            }
            "getPresentationDisplays" -> {
                val helper = getOrCreateDisplayHelper()
                val displays = helper.getPresentationDisplays().map { displayToMap(it) }
                result.success(displays)
            }
            "getDisplayInfo" -> {
                val displayId = call.argument<Int>("displayId")
                if (displayId == null) {
                    result.error("INVALID_ARGUMENT", "displayId is required", null)
                    return
                }
                val helper = getOrCreateDisplayHelper()
                val info = helper.getDisplayInfo(displayId)
                result.success(info?.toMap())
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val helper = getOrCreateDisplayHelper()

        helper.registerDisplayListener(object : DisplayHelper.DisplayListener {
            override fun onDisplayAdded(display: Display) {
                eventSink?.success(mapOf(
                    "event" to "displayAdded",
                    "display" to displayToMap(display)
                ))
            }

            override fun onDisplayRemoved(displayId: Int) {
                eventSink?.success(mapOf(
                    "event" to "displayRemoved",
                    "displayId" to displayId
                ))
            }

            override fun onDisplayChanged(display: Display) {
                eventSink?.success(mapOf(
                    "event" to "displayChanged",
                    "display" to displayToMap(display)
                ))
            }
        })
    }

    override fun onCancel(arguments: Any?) {
        displayHelper?.unregisterDisplayListener()
        eventSink = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        displayHelper?.unregisterDisplayListener()
        displayHelper = null
    }

    private fun getOrCreateDisplayHelper(): DisplayHelper {
        if (displayHelper == null) {
            displayHelper = DisplayHelper(context)
        }
        return displayHelper!!
    }

    private fun displayToMap(display: Display): Map<String, Any> {
        return mapOf(
            "displayId" to display.displayId,
            "name" to display.name,
            "width" to display.width,
            "height" to display.height,
            "rotation" to display.rotation,
            "isValid" to display.isValid
        )
    }
}
