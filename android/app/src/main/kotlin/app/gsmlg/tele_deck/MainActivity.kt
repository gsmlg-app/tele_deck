package app.gsmlg.tele_deck

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity - Settings and Onboarding Screen for TeleDeck IME
 *
 * This activity serves as the launcher activity and provides:
 * - IME setup/onboarding flow
 * - Settings access
 * - Status information about the IME
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.gsmlg.tele_deck/settings"
        private const val IME_CHANNEL = "tele_deck/ime"
        private const val CRASH_LOG_CHANNEL = "app.gsmlg.tele_deck/crash_logs"
    }

    private var settingsChannel: MethodChannel? = null
    private var imeChannel: MethodChannel? = null
    private var crashLogChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for settings-related operations
        settingsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        settingsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isIMEEnabled" -> {
                    result.success(isIMEEnabled())
                }
                "isIMESelected" -> {
                    result.success(isIMESelected())
                }
                "openIMESettings" -> {
                    openIMESettings()
                    result.success(true)
                }
                "openIMEPicker" -> {
                    openIMEPicker()
                    result.success(true)
                }
                "getIMEStatus" -> {
                    result.success(mapOf(
                        "enabled" to isIMEEnabled(),
                        "selected" to isIMESelected()
                    ))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup IME MethodChannel for launcher-side IME operations
        imeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IME_CHANNEL)
        imeChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isImeEnabled" -> {
                    result.success(isIMEEnabled())
                }
                "isImeActive" -> {
                    result.success(isIMESelected())
                }
                "openImeSettings" -> {
                    openIMESettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup crash log MethodChannel
        crashLogChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CRASH_LOG_CHANNEL)
        crashLogChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getCrashLogs" -> {
                    val logs = CrashLogger.getCrashLogs(this)
                    val logsAsString = logs.map { it.toString() }
                    result.success(logsAsString)
                }
                "getCrashLogDetail" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        val log = CrashLogger.getCrashLogDetail(this, id)
                        result.success(log?.toString())
                    } else {
                        result.error("INVALID_ARGUMENT", "id is required", null)
                    }
                }
                "clearCrashLogs" -> {
                    val success = CrashLogger.clearCrashLogs(this)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Check if TeleDeck IME is enabled in system settings
     * Uses InputMethodManager which works on all Android versions
     */
    private fun isIMEEnabled(): Boolean {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        val enabledIMEs = imm.enabledInputMethodList

        val myPackageName = packageName
        return enabledIMEs.any { it.packageName == myPackageName }
    }

    /**
     * Check if TeleDeck IME is currently selected as the default keyboard
     * Uses InputMethodManager which works on all Android versions
     */
    private fun isIMESelected(): Boolean {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager

        // Get the current input method ID from the system
        // This approach works across all Android versions
        try {
            val currentIMEId = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.DEFAULT_INPUT_METHOD
            ) ?: return false

            val myPackageName = packageName
            return currentIMEId.startsWith("$myPackageName/")
        } catch (e: SecurityException) {
            // Fallback: check if our IME is in the enabled list
            // We can't determine if it's the default, so return false
            return false
        }
    }

    /**
     * Open system settings to enable/disable input methods
     */
    private fun openIMESettings() {
        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    /**
     * Open the input method picker dialog
     */
    private fun openIMEPicker() {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        imm.showInputMethodPicker()
    }

    override fun onResume() {
        super.onResume()
        // Notify Flutter of current IME status when activity resumes
        try {
            settingsChannel?.invokeMethod("onIMEStatusChanged", mapOf(
                "enabled" to isIMEEnabled(),
                "selected" to isIMESelected()
            ))
        } catch (e: Exception) {
            // Ignore errors during status check
        }

        // Handle VIEW_CRASH_LOGS intent deep link
        handleCrashLogIntent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleCrashLogIntent()
    }

    private fun handleCrashLogIntent() {
        if (intent?.action == "app.gsmlg.tele_deck.VIEW_CRASH_LOGS") {
            // Notify Flutter to show crash logs
            settingsChannel?.invokeMethod("viewCrashLogs", null)
            // Clear the intent to prevent re-triggering
            intent = Intent()
        }
    }

    override fun onDestroy() {
        settingsChannel = null
        imeChannel = null
        crashLogChannel = null
        super.onDestroy()
    }
}
