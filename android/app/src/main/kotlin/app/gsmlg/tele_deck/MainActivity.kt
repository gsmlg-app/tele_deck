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
    }

    private var settingsChannel: MethodChannel? = null

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
    }

    override fun onDestroy() {
        settingsChannel = null
        super.onDestroy()
    }
}
