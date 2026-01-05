package app.gsmlg.tele_deck

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver that handles the keyboard toggle action.
 *
 * This receiver responds to the following actions:
 * - app.gsmlg.tele_deck.TOGGLE_KEYBOARD - Toggle keyboard visibility
 * - app.gsmlg.tele_deck.SHOW_KEYBOARD - Show keyboard
 * - app.gsmlg.tele_deck.HIDE_KEYBOARD - Hide keyboard
 *
 * Ayaneo Pocket DS (or other devices) can bind a physical button to send these broadcasts:
 * adb shell am broadcast -a app.gsmlg.tele_deck.TOGGLE_KEYBOARD
 */
class ToggleKeyboardReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "ToggleKeyboardReceiver"
        const val ACTION_TOGGLE_KEYBOARD = "app.gsmlg.tele_deck.TOGGLE_KEYBOARD"
        const val ACTION_SHOW_KEYBOARD = "app.gsmlg.tele_deck.SHOW_KEYBOARD"
        const val ACTION_HIDE_KEYBOARD = "app.gsmlg.tele_deck.HIDE_KEYBOARD"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received action: ${intent.action}")

        // Get the IME service instance
        val imeService = TeleDeckIMEService.instance

        if (imeService == null) {
            Log.w(TAG, "TeleDeckIMEService is not running")
            return
        }

        when (intent.action) {
            ACTION_TOGGLE_KEYBOARD -> {
                Log.d(TAG, "Toggling keyboard")
                imeService.toggleKeyboard()
            }
            ACTION_SHOW_KEYBOARD -> {
                Log.d(TAG, "Showing keyboard")
                imeService.showKeyboard()
            }
            ACTION_HIDE_KEYBOARD -> {
                Log.d(TAG, "Hiding keyboard")
                imeService.hideKeyboard()
            }
        }
    }
}
