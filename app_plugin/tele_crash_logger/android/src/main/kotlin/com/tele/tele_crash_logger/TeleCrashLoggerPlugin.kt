package com.tele.tele_crash_logger

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** TeleCrashLoggerPlugin */
class TeleCrashLoggerPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tele_crash_logger")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "logCrash" -> {
                val errorType = call.argument<String>("errorType") ?: "Unknown"
                val message = call.argument<String>("message") ?: "Unknown error"
                val stackTrace = call.argument<String>("stackTrace") ?: ""
                val displayState = call.argument<Map<String, Any?>>("displayState")
                val engineState = call.argument<String>("engineState") ?: "running"
                val showNotification = call.argument<Boolean>("showNotification") ?: true

                val crashId = CrashLogger.logCrash(
                    context = context,
                    errorType = errorType,
                    message = message,
                    stackTrace = stackTrace,
                    displayState = displayState,
                    engineState = engineState,
                    showNotification = showNotification
                )
                result.success(crashId)
            }
            "getCrashLogs" -> {
                val logs = CrashLogger.getCrashLogs(context)
                val logsList = logs.map { jsonObject ->
                    mapOf(
                        "id" to jsonObject.optString("id"),
                        "timestamp" to jsonObject.optString("timestamp"),
                        "errorType" to jsonObject.optString("errorType"),
                        "message" to jsonObject.optString("message"),
                        "stackTrace" to jsonObject.optString("stackTrace"),
                        "engineState" to jsonObject.optString("engineState")
                    )
                }
                result.success(logsList)
            }
            "getCrashLogDetail" -> {
                val id = call.argument<String>("id")
                if (id == null) {
                    result.error("INVALID_ARGUMENT", "id is required", null)
                    return
                }
                val log = CrashLogger.getCrashLogDetail(context, id)
                if (log != null) {
                    result.success(mapOf(
                        "id" to log.optString("id"),
                        "timestamp" to log.optString("timestamp"),
                        "errorType" to log.optString("errorType"),
                        "message" to log.optString("message"),
                        "stackTrace" to log.optString("stackTrace"),
                        "engineState" to log.optString("engineState")
                    ))
                } else {
                    result.success(null)
                }
            }
            "clearCrashLogs" -> {
                val success = CrashLogger.clearCrashLogs(context)
                result.success(success)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
