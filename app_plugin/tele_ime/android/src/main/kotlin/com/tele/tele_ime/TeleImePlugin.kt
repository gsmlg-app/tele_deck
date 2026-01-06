package com.tele.tele_ime

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter plugin for IME status and settings operations.
 *
 * Provides:
 * - Check if IME is enabled/active
 * - Open IME settings
 * - Show IME picker
 * - List installed/enabled IMEs
 *
 * Note: This plugin provides utilities for IME management.
 * The actual IME service is implemented by extending [BaseImeService]
 * in the app's native code.
 */
class TeleImePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var imeHelper: ImeHelper? = null

    // Store the IME service class name for status checks
    var imeServiceClassName: String? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tele_ime/settings")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isImeEnabled" -> {
                val imeId = call.argument<String>("imeId") ?: getDefaultImeId()
                if (imeId == null) {
                    result.error("INVALID_ARGUMENT", "imeId is required", null)
                    return
                }
                val helper = getOrCreateHelper()
                result.success(helper.isImeEnabledById(imeId))
            }
            "isImeActive" -> {
                val imeId = call.argument<String>("imeId") ?: getDefaultImeId()
                if (imeId == null) {
                    result.error("INVALID_ARGUMENT", "imeId is required", null)
                    return
                }
                val helper = getOrCreateHelper()
                result.success(helper.isImeActiveById(imeId))
            }
            "openImeSettings" -> {
                val helper = getOrCreateHelper()
                helper.openImeSettings()
                result.success(null)
            }
            "showImePicker" -> {
                val helper = getOrCreateHelper()
                helper.showImePicker()
                result.success(null)
            }
            "getEnabledImes" -> {
                val helper = getOrCreateHelper()
                result.success(helper.getEnabledImes())
            }
            "getCurrentIme" -> {
                val helper = getOrCreateHelper()
                result.success(helper.getCurrentIme())
            }
            "getInstalledImes" -> {
                val helper = getOrCreateHelper()
                val imes = helper.getInstalledImes().map { it.toMap() }
                result.success(imes)
            }
            "setImeServiceClass" -> {
                imeServiceClassName = call.argument<String>("className")
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        imeHelper = null
    }

    private fun getOrCreateHelper(): ImeHelper {
        if (imeHelper == null) {
            imeHelper = ImeHelper(context)
        }
        return imeHelper!!
    }

    private fun getDefaultImeId(): String? {
        // If a service class was set, use that
        imeServiceClassName?.let { className ->
            return "${context.packageName}/$className"
        }
        return null
    }
}
