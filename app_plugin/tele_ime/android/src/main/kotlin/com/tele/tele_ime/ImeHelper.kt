package com.tele.tele_ime

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager

/**
 * Helper class for IME status and settings operations.
 *
 * Provides utilities to:
 * - Check if a specific IME is enabled
 * - Check if a specific IME is the current/active IME
 * - Open system IME settings
 * - Get list of enabled IMEs
 */
class ImeHelper(private val context: Context) {

    companion object {
        private const val TAG = "ImeHelper"
    }

    private val inputMethodManager: InputMethodManager =
        context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

    /**
     * Get the IME ID for this app's input method service.
     * The ID format is: packageName/fullyQualifiedServiceClassName
     */
    fun getImeId(serviceClass: Class<*>): String {
        val componentName = ComponentName(context.packageName, serviceClass.name)
        return componentName.flattenToString()
    }

    /**
     * Check if a specific IME is enabled in system settings.
     */
    fun isImeEnabled(serviceClass: Class<*>): Boolean {
        val imeId = getImeId(serviceClass)
        return isImeEnabledById(imeId)
    }

    /**
     * Check if an IME is enabled by its ID.
     */
    fun isImeEnabledById(imeId: String): Boolean {
        val enabledImes = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_INPUT_METHODS
        ) ?: return false

        return enabledImes.split(":").any { it.contains(imeId) || imeId.contains(it) }
    }

    /**
     * Check if a specific IME is the current active IME.
     */
    fun isImeActive(serviceClass: Class<*>): Boolean {
        val imeId = getImeId(serviceClass)
        return isImeActiveById(imeId)
    }

    /**
     * Check if an IME is active by its ID.
     */
    fun isImeActiveById(imeId: String): Boolean {
        val currentIme = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD
        ) ?: return false

        return currentIme == imeId || currentIme.contains(imeId) || imeId.contains(currentIme)
    }

    /**
     * Open the system IME settings screen.
     */
    fun openImeSettings() {
        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    /**
     * Open the IME picker dialog.
     */
    fun showImePicker() {
        inputMethodManager.showInputMethodPicker()
    }

    /**
     * Get list of all enabled input methods.
     */
    fun getEnabledImes(): List<String> {
        val enabledImes = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_INPUT_METHODS
        ) ?: return emptyList()

        return enabledImes.split(":").filter { it.isNotBlank() }
    }

    /**
     * Get the current default input method.
     */
    fun getCurrentIme(): String? {
        return Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD
        )
    }

    /**
     * Get information about all installed input methods.
     */
    fun getInstalledImes(): List<ImeInfo> {
        return inputMethodManager.inputMethodList.map { ime ->
            ImeInfo(
                id = ime.id,
                packageName = ime.packageName,
                serviceName = ime.serviceName,
                label = ime.loadLabel(context.packageManager).toString()
            )
        }
    }

    /**
     * Data class containing input method information.
     */
    data class ImeInfo(
        val id: String,
        val packageName: String,
        val serviceName: String,
        val label: String
    ) {
        fun toMap(): Map<String, String> = mapOf(
            "id" to id,
            "packageName" to packageName,
            "serviceName" to serviceName,
            "label" to label
        )
    }
}
