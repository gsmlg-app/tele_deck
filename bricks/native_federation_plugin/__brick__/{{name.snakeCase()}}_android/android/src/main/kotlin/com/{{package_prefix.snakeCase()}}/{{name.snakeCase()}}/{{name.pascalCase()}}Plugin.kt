package com.{{package_prefix.snakeCase()}}.{{name.snakeCase()}}

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Date

/** {{name.pascalCase()}}Plugin */
class {{name.pascalCase()}}Plugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var cachedData: Map<String, Any>? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "{{package_prefix.snakeCase()}}_{{name.snakeCase()}}")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getData" -> {
                try {
                    val data = getData()
                    result.success(data)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get data: ${e.message}", null)
                }
            }
            "refresh" -> {
                try {
                    cachedData = null
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to refresh: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getData(): Map<String, Any> {
        if (cachedData != null) {
            return cachedData!!
        }

        val data = mutableMapOf<String, Any>(
            "platform" to "android",
            "timestamp" to Date().toInstant().toString(),
            "additionalData" to mapOf(
                "manufacturer" to Build.MANUFACTURER,
                "model" to Build.MODEL,
                "brand" to Build.BRAND,
                "device" to Build.DEVICE,
                "sdkInt" to Build.VERSION.SDK_INT,
                "release" to Build.VERSION.RELEASE
            )
        )

        cachedData = data
        return data
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
